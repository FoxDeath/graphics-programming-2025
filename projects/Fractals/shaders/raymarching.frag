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

	// Invoke GetDistance again to get the output value
	Output o;
	InitOutput(o);
	GetDistance(point, o);

	// With the output value, get the final color
	FragColor = ro.color;

	// Convert linear depth to normalized depth (same as projecting the point and taking the Z/W)
	gl_FragDepth = -ProjMatrix[2][2] - ProjMatrix[3][2] / point.z;
}
