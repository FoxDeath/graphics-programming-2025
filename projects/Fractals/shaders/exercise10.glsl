
// Uniforms
// Replace constants with uniforms with the same name
uniform vec3 MandelbulbColor = vec3(1, 0, 0);
uniform vec3 MandelbulbCenter = vec3(0, 0, -4);
uniform int MandelbulbIterations = 8;
uniform float MandelbulbPower = 8.0;

// Output structure
struct Output
{
	// color of the closest figure
	vec3 color;
};

// Signed distance function
float GetDistance(vec3 p, inout Output o)
{
	// Sphere in position "SphereCenter" and size "SphereRadius"
	float mandelbulb = MandelbulbSDF(TransformToLocalPoint(p, MandelbulbCenter), MandelbulbIterations, MandelbulbPower);

	// Replace this with a mix, using the blend factor from SmoothUnion
	o.color = MandelbulbColor;

	return mandelbulb;
}

// Default value for o
void InitOutput(out Output o)
{
	o.color = vec3(0.0f);
}

// Output function: Just a dot with the normal and view vectors
vec4 GetOutputColor(vec3 p, float distance, Output o)
{
	vec3 normal = CalculateNormal(p);
	vec3 viewDir = normalize(-p);
	float dotNV = dot(normalize(-p), normal);
	return vec4(dotNV * o.color, 1.0f);
}
