// Forward declare distance function
float GetDistance(vec3 p);

// Shadows
float self_shadow_bias = 0.01;
float shadow_darkness = 0.2;
int shadow_steps = 15;
float shadow_softness = 64.0;
float min_step_size = 0.2;

// Lighting
float light_intensity = 3.6;
vec3 light1_position = vec3(10.0);
vec3 light2_position = vec3(-10.0);
vec3 light1_color = vec3(1.0, 1.0, 1.0);
vec3 light2_color = vec3(1.0, 1.0, 1.0);
float ambient_light = 0.5;

// Refraction
float refraction_intensity = 2.611;
float refraction_sharpness = 2.0;

void GetLightConfig(out float maxDistance, out float surfaceDistance);

float soft_shadow(vec3 p, vec3 light_pos, float k) {
	vec3 rd = normalize(light_pos - p);
	float res = 1.0;
	float ph = 1e20;

    float maxDistance, surfaceDistance;
    GetLightConfig(maxDistance, surfaceDistance);

	float t = surfaceDistance + self_shadow_bias;

	for (int i = 0; i < shadow_steps; i++) {
		float h = GetDistance(p + rd * t);

		if (h < surfaceDistance) {
			return 0.0;
		}

		float y = h * h / (2.0 * ph);
		float d = sqrt(h * h - y * y);
		res = min(res, k * d / max(0.0, t - y));
		ph = h;

		t += max(h, min_step_size);

		if (t >= maxDistance) {
			break;
		}
	}

	return clamp(res, 0.0, 1.0);
}

vec3 get_light(vec3 p, vec3 rd, vec3 ro, vec3 light_pos, vec3 light_color, vec3 normal) {
	vec3 to_light = normalize(light_pos - p);
	float light = light_intensity * clamp(dot(to_light, normal), 0.05, 1.0);

	float shadow = soft_shadow(p, light_pos, shadow_softness);
	light *= max(shadow, shadow_darkness);
	vec3 reflection = reflect(to_light, normal);
	float specular = pow(max(dot(reflection, rd), 0.0), refraction_sharpness);
	light *= max(specular * refraction_intensity, 1.0);// + (1.0 - metallicness), metallic_darkness);

	return max(light_color * light, ambient_light);
}