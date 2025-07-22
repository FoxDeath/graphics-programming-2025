vec3 TransformToLocalPoint(vec3 p, vec3 position)
{
	return p - position;
}

mat2 Rotate (float angle) 
{
    float s = sin (angle);
    float c = cos (angle);

    return mat2 (c, -s, s, c);
}

vec3 TriplexMul(vec3 n1, vec3 n2, float r1, float theta1, float phi1) 
{
    float r2 = length(n2);
    float theta2 = atan(n2.y, n2.x);
    float phi2 = asin(n2.z / r2);

    float r = r1 * r2;
    float theta = theta1 + theta2;
    float phi = phi1 + phi2;

    return vec3(r * cos(theta) * cos(phi), r * sin(theta) * cos(phi), r * sin(phi));
}

vec3 TriplexPow(vec3 z, float phase, float power)
{
    float r = length(z);
    float theta = atan(z.y, z.x);
    float phi = acos(z.z / r);
    r = r * r * r * r;
    theta *= power;
    phi = phi * power + phase;
    return vec3(r * sin(phi) * cos(theta), r * sin(phi) * sin(theta), r * cos(phi));
}

float SphereFold(vec4 z, float minR, float maxR, float bloatFactor) 
{ 
    float r2 = dot(z.xyz, z.xyz);
    return max(maxR / max(minR, r2), bloatFactor); 
}

vec4 BoxFold(vec4 z, vec3 r)
{ 
    z.xyz = clamp(z.xyz, -r, r) * 2.0 - z.xyz;
    return z; 
}

float DeBox(vec4 p, vec3 s)
{ 
    vec3 a = abs(p.xyz) - s;
    return (min(max(max(a.x, a.y), a.z), 0.0) + length(max(a, 0.0))) / p.w; 
}


float MandelbulbSDF(vec3 pos, int iterations, float power) 
{
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    int Iterations = iterations;
    float Power = power;

    for (int i = 0; i < Iterations; i++) 
    {
        r = length(z);
        if (r > 2.0) break;

        // Convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        dr = pow(r, Power - 1.0) * Power * dr + 1.0;

        // Scale and rotate the point
        float zr = pow(r, Power);
        theta *= Power;
        phi *= Power;

        // Convert back to cartesian coordinates
        z = zr * vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z += pos;
    }
    return 0.5 * log(r) * r / dr;
}

float MandelboxSDF(vec3 pos, int iterations, float power) 
{
	vec4 p = vec4(pos, 1.0) * 5.0;
    vec4 o = p;
    float scale = 2.0;

	for (int i = 0; i < iterations; i++) 
    {
		p = BoxFold(p, vec3(1.0));
		p *= SphereFold(p, 0.0, 1.0, 1.0) * power;
		p += o;
	}

	return DeBox(p, vec3(10));
}


float LambdakleinSDF(vec3 p, int iterations, float power) 
{
    vec3 z = p;
    vec3 c = vec3(1.035, -0.317, 0.013);
    float r1 = length(c);
    float theta1 = atan(c.y, c.x);
    float phi1 = asin(c.z / r1);
    float r = length(z);
    float dz = 1.0;
    float powercache1 = (power - 1.0) * 0.5;

    for (int i = 0; i < int(iterations); i++) 
    {
        dz = power * pow(r, powercache1) * dz + 2.0;
        
        if (z.z > z.x) z.zx = z.xz;
        if (z.z > z.y) z.zy = z.yz;
        if (z.x > z.y) z.xy = z.yx;
        z.xy = z.yx; // Put negative sign before z.yx to make a more coral like variation

        z = TriplexMul(c, z - TriplexPow(z, 1.815142, power), r1, theta1, phi1);
        z = 2.0 * clamp(z, vec3(0.0), vec3(0.5)) - z;
        
        r = length(z);
		
        if (r > 2.0) break;
    }

    return 0.5 * log(r) * sqrt(r) / dz;
}