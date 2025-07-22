// Forward declare distance function
float GetDistance(vec3 p);

uniform float AOStrength = 1.0;
uniform int AOSteps = 5;
uniform float AOStepSize = 0.1;

float AmbientOcclusion(vec3 p, vec3 normal)
{
    float ao = 0.0;
    float weight = 1.0;
    int aoSteps = AOSteps;
    float aoStepSize = AOStepSize;

    for(int i = 1; i <= aoSteps; i++) 
    {
        float dist = aoStepSize * float(i);
        float d = GetDistance(p + normal * dist); // 'map' is your distance function (Mandelbulb SDF)
        ao += (dist - d) * weight;
        weight *= 0.5; // progressively reduce influence
    }

    ao = 1.0 - clamp(ao, 0.0, 1.0);
    return pow(ao, AOStrength);
}
