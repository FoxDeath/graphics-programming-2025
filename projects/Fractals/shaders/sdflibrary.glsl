
// Transformations ---

// Transform point relative to a specific position
vec3 TransformToLocalPoint(vec3 p, vec3 position)
{
	return p - position;
}

// Transform point relative to a transform matrix
vec3 TransformToLocalPoint(vec3 p, mat4 m)
{
	return (inverse(m) * vec4(p, 1)).xyz;
}

// Transform vector relative to a transform matrix
vec3 TransformToLocalVector(vec3 v, mat4 m)
{
	return (inverse(m) * vec4(v, 0)).xyz;
}

// SDFs ---

// Signed distance field of a plane
float PlaneSDF(vec3 p, vec3 normal, float offset)
{
	return dot(p, normal) - offset;
}

// Signed distance field of a sphere
float SphereSDF(vec3 p, float radius)
{
	return length(p) - radius;
}

// Signed distance field of a sphere with analytic normal
float SphereSDF(vec3 p, out vec3 normal, float radius)
{
	float distance = length(p);
	normal = p / distance;
	return distance - radius;
}

// Signed distance field of a box
float BoxSDF(vec3 p, vec3 halfsize)
{
	vec3 q = abs(p) - halfsize;
	float outerDist = length(max(q, 0.0f));
	float innerDist = min(max(q.x, max(q.y, q.z)), 0.0f);
	return outerDist + innerDist;
}

// Signed distance field of a cylinder
float CylinderSDF(vec3 p, float height, float radius)
{
	vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(radius, height);
	float outerDist = length(max(d, 0.0f));
	float innerDist = min(max(d.x, d.y), 0.0f);
	return outerDist + innerDist;
}

// Signed distance field of a torus
float TorusSDF(vec3 p, float mainRadius, float sideRadius)
{
	vec2 q = vec2(length(p.xz) - mainRadius, p.y);
	return length(q) - sideRadius;
}

// Operations ---

float Invert(float d)
{
	return -d;
}

// Union of two SDFs
float Union(float a, float b)
{
	return min(a, b);
}

// Intersection of two SDFs
float Intersection(float a, float b)
{
	return max(a, b);
}

// Substract SDF b from SDF a
float Substraction(float a, float b)
{
	return max(a, -b);
}

// Smooth union with smoothness k
float SmoothUnion(float a, float b, float k)
{
	float h = max(k - abs(a - b), 0.0) / k;
	return min(a, b) - h * h * k * (1.0 / 4.0);
}

mat2 Rotate (float angle) {
  float s = sin (angle);
  float c = cos (angle);

  return mat2 (c, -s, s, c);
}

// Smooth union with smoothness k and returning blend value in range (0-1)
float SmoothUnion(float a, float b, float k, out float blend)
{
	vec3 v = max(vec3(k) - vec3(b, a, abs(a - b)), 0.0f) / k;
	blend = (v.x*v.x - v.y*v.y);

	blend = blend * 0.5f + 0.5f;
	float h = v.z;
	return min(a, b) - h * h * k * (1.0 / 4.0);
}

float MandelbulbSDF(vec3 pos, int iterations, float power) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    int Iterations = iterations;
    float Power = power;

    for (int i = 0; i < Iterations; i++) {
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
vec3 triplexMul(vec3 n1, vec3 n2, float r1, float theta1, float phi1) {
    float r2 = length(n2);
    float theta2 = atan(n2.y, n2.x);
    float phi2 = asin(n2.z / r2);

    float r = r1 * r2;
    float theta = theta1 + theta2;
    float phi = phi1 + phi2;

    return vec3(r * cos(theta) * cos(phi), r * sin(theta) * cos(phi), r * sin(phi));
}

vec3 triplexPow(vec3 z, float phase, float power) {
    float r = length(z);
    float theta = atan(z.y, z.x);
    float phi = acos(z.z / r);
    r = r * r * r * r;
    theta *= power;
    phi = phi * power + phase;
    return vec3(r * sin(phi) * cos(theta), r * sin(phi) * sin(theta), r * cos(phi));
}
float sphereFold(vec4 z, float minR, float maxR, float bloatFactor) { float r2 = dot(z.xyz, z.xyz); return max(maxR / max(minR, r2), bloatFactor); }
vec4 boxFold(vec4 z, vec3 r) { z.xyz = clamp(z.xyz, -r, r) * 2.0 - z.xyz; return z; }
float de_box(vec4 p, vec3 s) { vec3 a = abs(p.xyz) - s; return (min(max(max(a.x, a.y), a.z), 0.0) + length(max(a, 0.0))) / p.w; }


float MandelboxSDF(vec3 pos, int iterations, float power) {
	vec4 p = vec4(pos, 1.0) * 5.0;
    vec4 o = p;
    float scale = 2.0;

	for (int i = 0; i < iterations; i++) {
		p = boxFold(p, vec3(1.0));
		p *= sphereFold(p, 0.0, 1.0, 1.0) * power;
		p += o;
	}

	return de_box(p, vec3(10));
}


float LambdabulbSDF(vec3 p, int iterations, float power) {
    vec3 z = p;
    vec3 c = vec3(1.035, -0.317, 0.013);
    float r1 = length(c);
    float theta1 = atan(c.y, c.x);
    float phi1 = asin(c.z / r1);
    float r = length(z);
    float dz = 1.0;
    float powercache1 = (power - 1.0) * 0.5;

    for (int i = 0; i < int(iterations); i++) {
        dz = power * pow(r, powercache1) * dz + 2.0;
        
        if (z.z > z.x) z.zx = z.xz;
        if (z.z > z.y) z.zy = z.yz;
        if (z.x > z.y) z.xy = z.yx;
        z.xy = z.yx; // Put negative sign before z.yx to make a more coral like variation

        z = triplexMul(c, z - triplexPow(z, 1.815142, power), r1, theta1, phi1);
        z = 2.0 * clamp(z, vec3(0.0), vec3(0.5)) - z;
        
        r = length(z);
		
        if (r > 2.0) break;
    }

    return 0.5 * log(r) * sqrt(r) / dz;
}

