uniform vec3 BaseColor = vec3(0.2, 1.0, 0.3);
uniform vec3 SecondaryColor = vec3(0.0, 0.4, 0.8);
uniform int Steps = 100;

struct RayMarchOutput
{
	float dist;
	vec4 color;
};

void InitRayMarchOutput(out RayMarchOutput ro)
{
	ro.dist = 0.0;
	ro.color = vec4(0.0, 0.0, 0.0, 1.0);
}

// Forward declare distance function
float GetDistance(vec3 p);

float GetTime();

// Forward declare config function
void GetRayMarcherConfig(out float maxDistance, out float surfaceDistance);

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

    float maxDistance, surfaceDistance;
    GetRayMarcherConfig(maxDistance, surfaceDistance);

    for (steps = 0.0; steps < float (Steps); steps++) 
    {
        vec3 p = ro + totalDistance * rd; // Current position of the ray
        float distance = GetDistance (p); // Distance from the current position to the scene
        curPos = ro + rd * totalDistance;
        if (minDistToScene > distance) 
        {
            minDistToScene = distance;
            minDistToScenePos = curPos;
        }
        if (minDistToOrigin > length (curPos)) 
        {
            minDistToOrigin = length (curPos);
            minDistToOriginPos = curPos;
        }
        totalDistance += distance; // Increases the total distance armched
        if (distance < surfaceDistance) 
        {
            hit = true;
            break; // If the ray marched more than the max steps or the max distance, breake out
        }
        else if (distance > maxDistance) 
        {
            break;
        }
    }

    float iterations = float (steps) + log (log (maxDistance)) / log (2.0) - log (log (dot (curPos, curPos))) / log (2.0);

    if (hit) 
    {
        col.rgb = mix(BaseColor, SecondaryColor, length (curPos) / 1.5);

        vec3 normal = CalculateNormal(curPos);
        float ao = pow(AmbientOcclusion(curPos, normal), AOStrength * 5.0);

        vec3 light1 = Light(curPos, rd, ro, Light1Position, Light1Color, normal);
        vec3 light2 = Light(curPos, rd, ro, Light2Position, Light2Color, normal);

        col.rgb *= ao * (light1 + light2);
    }

    o.dist = totalDistance;
    o.color = col;
}
