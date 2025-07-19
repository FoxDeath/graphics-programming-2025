//Inputs
in vec2 TexCoord;

//Outputs
out vec4 FragColor;

//Uniforms
uniform mat4 ProjMatrix;
uniform mat4 InvProjMatrix;

// Implement GetDistance based on version with output
float GetDistance(vec3 p)
{
	Output o;
	return GetDistance(p, o);
}

// Configure ray marcher
void GetRayMarcherConfig(out int maxSteps, out float time, out float maxDistance, out float surfaceDistance)
{
	maxSteps = GetSteps(); // Maximum number of steps to take in ray marching
	time = GetTime(); // Time for the ray march, used for animation
    maxDistance = ProjMatrix[3][2] / (ProjMatrix[2][2] + 1.0); // Far plane
    surfaceDistance = 0.0001;
}

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

vec3 EstimateNormal(vec3 p) {
    float h = 0.001;
    vec2 k = vec2(1, -1);
    return normalize(
        k.xyy * GetDistance(p + k.xyy*h) + 
        k.yyx * GetDistance(p + k.yyx*h) + 
        k.yxy * GetDistance(p + k.yxy*h) + 
        k.xxx * GetDistance(p + k.xxx*h)
    );
}

void main()
{
	// Start from transformed position
	vec4 viewPos = InvProjMatrix * vec4(TexCoord.xy * 2.0f - 1.0f, 0.0f, 1.0f);
	vec3 origin = viewPos.xyz / viewPos.w;
	RayMarchOutput ro;
	InitRayMarchOutput(ro);

	// Initial distance to camera
	float distance = length(origin);

	// Normalize to get view direction
	vec3 dir = origin / distance;

	RayMarchering(origin, dir, ro);

	// Get Distance from the origin to the closest object
	distance += ro.dist;

	// Hit point in view space is given by the direction from the camera and the distance
	vec3 point = dir * distance;

	vec3 normal = EstimateNormal(point);
	float ao = pow(AmbientOcclusion(point, normal), GetAOStrength());

	// Invoke GetDistance again to get the output value
	Output o;
	InitOutput(o);
	GetDistance(point, o);

	// With the output value, get the final color
	FragColor = ro.color * ao ;

	// Convert linear depth to normalized depth (same as projecting the point and taking the Z/W)
	gl_FragDepth = -ProjMatrix[2][2] - ProjMatrix[3][2] / point.z;
}
