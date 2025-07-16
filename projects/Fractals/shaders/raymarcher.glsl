
// Forward declare distance function
float GetDistance(vec3 p);

// Forward declare config function
void GetRayMarcherConfig(out uint maxSteps, out float maxDistance, out float surfaceDistance);

vec3 hsv2rgb (vec3 c) {
  vec4 K = vec4 (1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs (fract (c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix (K.xxx, clamp (p - K.xxx, 0.0, 1.0), c.y);
}

float map (float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

// Marches the ray in the scene
vec4 RayMarcherColour (vec3 ro, vec3 rd, float time) {
  float steps = 0.0;
  float totalDistance = 0.0;
  float minDistToScene = 100.0;
  vec3 minDistToScenePos = ro;
  float minDistToOrigin = 100.0;
  vec3 minDistToOriginPos = ro;
  vec4 col = vec4 (0.0, 0.0, 0.0, 1.0);
  vec3 curPos = ro;
  bool hit = false;
  float PI = 3.141592653589793238;

  for (steps = 0.0; steps < float (250); steps++) {
    vec3 p = ro + totalDistance * rd; // Current position of the ray
    float distance = GetDistance (p); // Distance from the current position to the scene
    curPos = ro + rd * totalDistance;
    if (minDistToScene > distance) {
      minDistToScene = distance;
      minDistToScenePos = curPos;
    }
    if (minDistToOrigin > length (curPos)) {
      minDistToOrigin = length (curPos);
      minDistToOriginPos = curPos;
    }
    totalDistance += distance; // Increases the total distance armched
    if (distance < 0.0001) {
      hit = true;
      break; // If the ray marched more than the max steps or the max distance, breake out
    }
    else if (distance > 200.0) {
      break;
    }
  }

  float iterations = float (steps) + log (log (200.0)) / log (2.0) - log (log (dot (curPos, curPos))) / log (2.0);

  if (hit) {
    col.rgb = vec3 (0.8 + (length (curPos) / 0.5), 1.0, 0.8);
    col.rgb = hsv2rgb (col.rgb);
  }
  else {
    col.rgb = vec3 (0.8 + (length (minDistToScenePos) / 0.5), 1.0, 0.8);
    col.rgb = hsv2rgb (col.rgb);
    col.rgb *= 1.0 / (minDistToScene * minDistToScene);
    col.rgb /= map (sin (time * 3.0), -1.0, 1.0, 3000.0, 50000.0);
  }

  col.rgb /= steps * 0.08; // Ambeint occlusion
  col.rgb /= pow (distance (ro, minDistToScenePos), 2.0);
  col.rgb *= 3.0;

  return col;
}


// Ray marching algorithm
float RayMarch(vec3 origin, vec3 dir)
{
    float distance = 0.0f;

    // Get configuration specific to this shader pass
    uint maxSteps;
    float maxDistance, surfaceDistance;
    GetRayMarcherConfig(maxSteps, maxDistance, surfaceDistance);

    // Iterate until maxSteps is reached or we find a point
    for(uint i = 0u; i < maxSteps; ++i)
    {
        // Get distance to the current point
        vec3 p = origin + dir * distance;
        float d = GetDistance(p);
        distance += d;

        // If distance is too big, discard the fragment
        if (distance > maxDistance)
            discard;

        // If this step increment was very small, we found a hit
        if (d < surfaceDistance)
            break;
    }

    return distance;
}

uniform int RaymarchHack;
// Calculate numerical normals using the tetrahedron technique with specific differential
// Implementation here because GetDistance needs to be defined
vec3 CalculateNormal(vec3 p, float h)
{
    vec3 normal = vec3(0.0f);

    #define ZERO (min(RaymarchHack, 0)) // hack to prevent inlining
    for(int i = ZERO; i < 4; i++)
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        normal += e * GetDistance(p + e * h);
    }

    return normalize(normal);
}

vec3 CalculateNormal(vec3 p)
{
    return CalculateNormal(p, 0.0001f);
}
