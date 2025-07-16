float sdMandelbulb(vec3 p, float power) {
    vec3 z = p;
    float dr = 1.0;
    float r = 0.0;
    const int ITERATIONS = 100;
    const float BAILOUT = 2.0;

    for (int i = 0; i < ITERATIONS; ++i) {
        r = length(z);
        if (r > BAILOUT) break;

        // convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        // scale and rotate the point
        float zr = pow(r, power);
        theta *= power;
        phi *= power;

        // compute new position
        z = zr * vec3(
            sin(theta) * cos(phi),
            sin(phi) * sin(theta),
            cos(theta)
        );
        z += p;

        // update derivative of radius
        dr = zr * power * dr + 1.0;
    }

    // distance estimator
    return 0.5 * log(r) * r / dr;
}

// Wrapper to match raymarcher expectations
float map(vec3 p) {
    // 'Power' uniform set from ImGui
    return sdMandelbulb(p, Power);
}