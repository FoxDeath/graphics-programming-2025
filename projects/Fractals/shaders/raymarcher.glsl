struct RayMarchOutput
{
	float dist;
    float ao;
	vec4 color;
};

void InitRayMarchOutput(out RayMarchOutput ro)
{
	ro.dist = 0.0;
	ro.color = vec4(0.0, 0.0, 0.0, 1.0);
}

// Forward declare distance function
float GetDistance(vec3 p);

// Forward declare config function
void GetRayMarcherConfig(out int steps, out float time, out float maxDistance, out float surfaceDistance);

float AmbientOcclusion(vec3 p, vec3 normal) {
    float ao = 0.0;
    float weight = 1.0;
    const int aoSteps = 5;
    const float aoStepSize = 0.1;

    for(int i = 1; i <= aoSteps; i++) {
        float dist = aoStepSize * float(i);
        float d = GetDistance(p + normal * dist); // 'map' is your distance function (Mandelbulb SDF)
        ao += (dist - d) * weight;
        weight *= 0.5; // progressively reduce influence
    }

    ao = 1.0 - clamp(ao, 0.0, 1.0);
    return ao;
}

vec3 EstimateNormal(vec3 p) {
    float h = 0.001;
    vec2 k = vec2(1, -1);
    return normalize(
        k.xyy * GetDistance(p + k.xyy*h) + 
        k.yyx * GetDistance(p + k.yyx*h) + 
        k.yxy * GetDistance(p + k.yxy*h) + 
        k.xxx * GetDistance(p + k.xxx*h)
    );
}

// Marches the ray in the scene. ro is ray origin, rd is ray direction, and o is the output structure
void RayMarchering (vec3 ro, vec3 rd, inout RayMarchOutput o) {
    float steps = 0.0;
    float totalDistance = 0.0;
    float minDistToScene = 100.0;
    vec3 minDistToScenePos = ro;
    float minDistToOrigin = 100.0;
    vec3 minDistToOriginPos = ro;
    vec4 col = vec4 (0.0, 0.0, 0.0, 1.0);
    vec3 curPos = ro;
    bool hit = false;

    int maxSteps;
    float time, maxDistance, surfaceDistance;
    GetRayMarcherConfig(maxSteps, time, maxDistance, surfaceDistance);

    for (steps = 0.0; steps < float (maxSteps); steps++) {
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
        if (distance < surfaceDistance) {
            hit = true;
            break; // If the ray marched more than the max steps or the max distance, breake out
        }
        else if (distance > maxDistance) {
            break;
        }
    }

    float iterations = float (steps) + log (log (maxDistance)) / log (2.0) - log (log (dot (curPos, curPos))) / log (2.0);

    if (hit) {
    col.rgb = vec3 (0.8 + (length (curPos) / 0.5), 1.0, 0.8);
    col.rgb = HSVToRGB(col.rgb);

    }
    else {
    col.rgb = vec3 (0.8 + (length (minDistToScenePos) / 0.5), 1.0, 0.8);
    col.rgb = HSVToRGB(col.rgb);
    col.rgb *= 1.0 / (minDistToScene * minDistToScene);
    col.rgb /= Map(sin (time * 3.0), -1.0, 1.0, 3000.0, 50000.0);
    }

    vec3 normal = EstimateNormal(curPos);
	float ao = pow(AmbientOcclusion(curPos, normal), o.ao * 5.0);
    col.rgb *= ao;

    o.dist = totalDistance;
    o.color = col;
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
