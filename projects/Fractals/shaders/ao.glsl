// Forward declare distance function
float GetDistance(vec3 p);

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
