// Forward declare distance function
float GetDistance(vec3 p);

// Shadows
uniform float SelfShadowBias = 0.01;
uniform float ShadowDarkness = 0.2;
uniform int ShadowSteps = 15;
uniform float ShadowSoftness = 64.0;
uniform float ShadowMinStepSize = 0.2;

// Lighting
uniform float LightIntensity = 3.6;
uniform vec3 Light1Position = vec3(10.0);
uniform vec3 Light2Position = vec3(-10.0);
uniform vec3 Light1Color = vec3(1.0, 1.0, 1.0);
uniform vec3 Light2Color = vec3(1.0, 1.0, 1.0);
uniform float AmbientLight = 0.5;

// Refraction
uniform float RefractionIntensity = 2.611;
uniform float RefractionSharpness = 2.0;

void GetRayMarcherConfig(out float maxDistance, out float surfaceDistance);

float SoftShadow(vec3 p, vec3 light_pos, float k) 
{
	vec3 rd = normalize(light_pos - p);
	float res = 1.0;
	float ph = 1e20;

    float maxDistance, surfaceDistance;
    GetRayMarcherConfig(maxDistance, surfaceDistance);

	float t = surfaceDistance + SelfShadowBias;

	for (int i = 0; i < ShadowSteps; i++) {
		float h = GetDistance(p + rd * t);

		if (h < surfaceDistance) 
		{
			return 0.0;
		}

		float y = h * h / (2.0 * ph);
		float d = sqrt(h * h - y * y);
		res = min(res, k * d / max(0.0, t - y));
		ph = h;

		t += max(h, ShadowMinStepSize);

		if (t >= maxDistance) 
		{
			break;
		}
	}

	return clamp(res, 0.0, 1.0);
}

vec3 Light(vec3 p, vec3 rd, vec3 ro, vec3 light_pos, vec3 light_color, vec3 normal) 
{
	vec3 to_light = normalize(light_pos - p);
	float light = LightIntensity * clamp(dot(to_light, normal), 0.05, 1.0);

	float shadow = SoftShadow(p, light_pos, ShadowSoftness);
	light *= max(shadow, ShadowDarkness);
	vec3 reflection = reflect(to_light, normal);
	float specular = pow(max(dot(reflection, rd), 0.0), RefractionSharpness);
	light *= max(specular * RefractionIntensity, 1.0);

	return max(light_color * light, AmbientLight);
}