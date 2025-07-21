// Uniforms
// Replace constants with uniforms with the same name
uniform vec3 Center = vec3(0, 0, -4);
uniform int Iterations = 8;
uniform float Power = 8.0;
uniform bool Animate = true;
uniform float Time = 0.0;
uniform float AOStrength;
uniform float ShadowSoftness;
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
	float time = Time;

	if(!Animate)
	{
		time = 0.0;
	}

	float power = Power + (5.0 * Map (sin (time * PI / 10.0 + PI), -1.0, 1.0, 0.0, 1.0));

	p.yz *= Rotate (-0.3 * PI);

	float mandelbulb = MandelbulbSDF(TransformToLocalPoint(p, Center), Iterations, power);

	return mandelbulb;
}

float GetTime()
{
	if(Animate)
	{
		return Time;
	}
	else
	{
		return 0.0;
	}
}

int GetSteps()
{
	return Steps;
}

float GetAOStrength()
{
	return AOStrength;
}

float GetShadowSoftness()
{
	return ShadowSoftness;
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
