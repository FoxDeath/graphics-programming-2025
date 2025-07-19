// Uniforms
// Replace constants with uniforms with the same name
uniform vec3 MandelbulbCenter = vec3(0, 0, -4);
uniform int MandelbulbIterations = 8;
uniform float MandelbulbPower = 8.0;
uniform float Time = 0.0;
uniform int Steps = 100;

#define PI 3.141592653589793238

// Output structure
struct Output
{
	// color of the closest figure
	vec3 color;
};

// Signed distance function
float GetDistance(vec3 p, inout Output o)
{
	float power = MandelbulbPower + (5.0 * map (sin (Time * PI / 10.0 + PI), -1.0, 1.0, 0.0, 1.0));

	p.yz *= Rotate (-0.3 * PI);

	float mandelbulb = MandelbulbSDF(TransformToLocalPoint(p, MandelbulbCenter), MandelbulbIterations, power);

	return mandelbulb;
}

float GetTime()
{
	// Return the time value, which is used to animate the Mandelbulb
	return Time;
}

int GetSteps()
{
	return Steps;
}

// Default value for o
void InitOutput(out Output o)
{
	o.color = vec3(0.0);
}

// Output function: Just a dot with the normal and view vectors
vec4 GetOutputColor(vec3 p, float distance, Output o)
{
	vec3 normal = CalculateNormal(p);
	vec3 viewDir = normalize(-p);
	float dotNV = dot(normalize(-p), normal);
	return vec4(dotNV * o.color, 1.0);
}
