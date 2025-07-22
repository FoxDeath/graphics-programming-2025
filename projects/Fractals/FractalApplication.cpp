#include "FractalApplication.h"

#include <ituGL/asset/ShaderLoader.h>
#include <ituGL/camera/Camera.h>
#include <ituGL/scene/SceneCamera.h>
#include <ituGL/lighting/DirectionalLight.h>
#include <ituGL/shader/Material.h>
#include <ituGL/renderer/PostFXRenderPass.h>
#include <ituGL/scene/RendererSceneVisitor.h>
#include <imgui.h>
#include <glm/gtx/transform.hpp>
#include <glm/gtx/euler_angles.hpp>
#include <iostream>

FractalApplication::FractalApplication()
    : Application(1024*1.5, 1024*1.5, "Fractal demo")
    , m_renderer(GetDevice())
{
}

void FractalApplication::Initialize()
{
    Application::Initialize();

    // Initialize DearImGUI
    m_imGui.Initialize(GetMainWindow());

    InitializeCamera();
    InitializeMaterial();
    InitializeRenderer();
}

void FractalApplication::Update()
{
    Application::Update();

    FractalApplication::UpdateCamera();

    // Update camera controller
    m_cameraController.Update(GetMainWindow(), GetDeltaTime());

    // Set renderer camera
    const Camera& camera = *m_cameraController.GetCamera()->GetCamera();
    m_renderer.SetCurrentCamera(camera);

    // Update the material properties
    m_material->SetUniformValue("ProjMatrix", camera.GetProjectionMatrix());
    m_material->SetUniformValue("InvProjMatrix", glm::inverse(camera.GetProjectionMatrix()));
    m_material->SetUniformValue("ViewMatrix", camera.GetViewMatrix());
	// Update time uniform
	m_material->SetUniformValue("Time", Application::GetCurrentTime());
}

void FractalApplication::Render()
{
    Application::Render();

    GetDevice().Clear(true, Color(0.0f, 0.0f, 0.0f, 1.0f), true, 1.0f);

    // Render the scene
    m_renderer.Render();

    // Render the debug user interface
    RenderGUI();
}

void FractalApplication::Cleanup()
{
    // Cleanup DearImGUI
    m_imGui.Cleanup();

    Application::Cleanup();
}

void FractalApplication::InitializeCamera()
{
    // Create the main camera
    std::shared_ptr<Camera> camera = std::make_shared<Camera>();
    camera->SetViewMatrix(glm::vec3(0.0f), glm::vec3(0.0f, 0.0f, -1.0), glm::vec3(0.0f, 1.0f, 0.0));
    float fov = 20.0f;
    camera->SetPerspectiveProjectionMatrix(fov, GetMainWindow().GetAspectRatio(), 0.1f, 100.0f);

    // Create a scene node for the camera
    std::shared_ptr<SceneCamera> sceneCamera = std::make_shared<SceneCamera>("camera", camera);

    // Set the camera scene node to be controlled by the camera controller
    m_cameraController.SetCamera(sceneCamera);
}

void FractalApplication::InitializeMaterial()
{
    m_material = CreateRaymarchingMaterial("shaders/fractal.glsl");

    // Initialize material uniforms
    m_material->SetUniformValue("FractalType", 0);
    m_material->SetUniformValue("Animate", 1);
    m_material->SetUniformValue("Iterations", 8);
    m_material->SetUniformValue("Center", glm::vec3(0, -2, -1.5));
    m_material->SetUniformValue("Power", 8.0f);
    m_material->SetUniformValue("Steps", 400);

    m_material->SetUniformValue("AOStrength", 1.0f);
    m_material->SetUniformValue("AOSteps", 5);
    m_material->SetUniformValue("AOStepSize", 0.1f);

    m_material->SetUniformValue("SelfShadowBias", 0.1f);
    m_material->SetUniformValue("ShadowDarkness", 0.2f);
    m_material->SetUniformValue("ShadowSteps", 15);
    m_material->SetUniformValue("ShadowSoftness", 64.0f);
    m_material->SetUniformValue("ShadowMinStepSize", 0.2f);

    m_material->SetUniformValue("LightIntensity", 3.6f);
    m_material->SetUniformValue("Light0Position", glm::vec3(10.0f));
    m_material->SetUniformValue("Light1Position", glm::vec3(-10.0f));
    m_material->SetUniformValue("Light0Color", glm::vec3(1.0f, 1.0f, 1.0f));
    m_material->SetUniformValue("Light1Color", glm::vec3(1.0f, 1.0f, 1.0f));
    m_material->SetUniformValue("AmbientLight", 0.5f);

    m_material->SetUniformValue("RefractionIntensity", 2.611f);
    m_material->SetUniformValue("RefractionSharpness", 2.0f);
}

void FractalApplication::InitializeRenderer()
{
    m_renderer.AddRenderPass(std::make_unique<PostFXRenderPass>(m_material));
}

std::shared_ptr<Material> FractalApplication::CreateRaymarchingMaterial(const char* fragmentShaderPath)
{
    // We could keep this vertex shader and reuse it, but it looks simpler this way
    std::vector<const char*> vertexShaderPaths;
    vertexShaderPaths.push_back("shaders/version330.glsl");
    vertexShaderPaths.push_back("shaders/renderer/fullscreen.vert");
    Shader vertexShader = ShaderLoader(Shader::VertexShader).Load(vertexShaderPaths);

    std::vector<const char*> fragmentShaderPaths;
    fragmentShaderPaths.push_back("shaders/version330.glsl");
    fragmentShaderPaths.push_back("shaders/utils.glsl");
    fragmentShaderPaths.push_back("shaders/sdflibrary.glsl");
    fragmentShaderPaths.push_back("shaders/ao.glsl");
    fragmentShaderPaths.push_back("shaders/light.glsl");
    fragmentShaderPaths.push_back("shaders/raymarcher.glsl");
    fragmentShaderPaths.push_back(fragmentShaderPath);
    fragmentShaderPaths.push_back("shaders/raymarching.frag");
    Shader fragmentShader = ShaderLoader(Shader::FragmentShader).Load(fragmentShaderPaths);

    std::shared_ptr<ShaderProgram> shaderProgramPtr = std::make_shared<ShaderProgram>();
    shaderProgramPtr->Build(vertexShader, fragmentShader);

    // Create material
    std::shared_ptr<Material> material = std::make_shared<Material>(shaderProgramPtr);
    
    return material;
}

void FractalApplication::RenderGUI()
{
    m_imGui.BeginFrame();

    // Draw GUI for camera controller
    //m_cameraController.DrawGUI(m_imGui);

    if (auto window = m_imGui.UseWindow("Scene parameters"))
    {
        // Get the camera view matrix and transform the sphere center and the box matrix
        glm::mat4 viewMatrix = m_cameraController.GetCamera()->GetCamera()->GetViewMatrix();

        static const char* fractalTypes[] = { "Mandelbulb", "Mandelbox", "Lambdaklein" };
        static int fractalType = 0;
		static glm::vec3 baseColor = glm::vec3(0.2f, 1.0f, 0.3f);
        static glm::vec3 secondaryColor = glm::vec3(0.0, 0.4, 0.8);
        static bool animate = 1;
        static glm::vec3 center(0, -2, -1.5);
        static int iterations = 10;
        static float power = 8.0f;
        static int steps = 400;

        static float aoStrength = 1.0f;
        static int AOSteps = 5;
        static float AOStepSize = 0.1f;

        static float SelfShadowBias = 0.01f;
        static float ShadowDarkness = 0.2f;
        static int ShadowSteps = 15;
        static float ShadowSoftness = 64.0f;
        static float ShadowMinStepSize = 0.2f;

        static float LightIntensity = 3.6f;
        static glm::vec3 Light1Position = glm::vec3(10.0f);
        static glm::vec3 Light2Position = glm::vec3(-10.0f);
        static glm::vec3 Light1Color = glm::vec3(1.0f, 1.0f, 1.0f);
        static glm::vec3 Light2Color = glm::vec3(1.0f, 1.0f, 1.0f);
        static float AmbientLight = 0.5f;

        static float RefractionIntensity = 2.611f;
        static float RefractionSharpness = 2.0f;

        if (ImGui::Button("Reset Uniforms"))
        {
			fractalType = 0;
			baseColor = glm::vec3(0.2f, 1.0f, 0.3f);
			secondaryColor = glm::vec3(0.0, 0.4, 0.8);
            animate = true;
            center = glm::vec3(0, -2, -1.5);
            iterations = 10;
            power = 8.0f;
            steps = 400;
			aoStrength = 1.0f;
            AOSteps = 5;
            AOStepSize = 0.1f;
            SelfShadowBias = 0.01f;
            ShadowDarkness = 0.2f;
            ShadowSteps = 15;
            ShadowSoftness = 64.0f;
            ShadowMinStepSize = 0.2f;
            LightIntensity = 3.6f;
            Light1Position = glm::vec3(10.0f);
            Light2Position = glm::vec3(-10.0f);
            Light1Color = glm::vec3(1.0f, 1.0f, 1.0f);
            Light2Color = glm::vec3(1.0f, 1.0f, 1.0f);
            AmbientLight = 0.5f;
            RefractionIntensity = 2.611f;
			RefractionSharpness = 2.0f;
        }

        if (ImGui::TreeNodeEx("Fractal", ImGuiTreeNodeFlags_DefaultOpen))
        {
            ImGui::ListBox("Fractal Type", &fractalType, fractalTypes, 3, 5);
            m_material->SetUniformValue("FractalType", fractalType);

			ImGui::ColorEdit3("Base Color", &baseColor[0]);
			m_material->SetUniformValue("BaseColor", baseColor);

			ImGui::ColorEdit3("Secondary Color", &secondaryColor[0]);
			m_material->SetUniformValue("SecondaryColor", secondaryColor);

            ImGui::Checkbox("Animate", &animate);
            m_material->SetUniformValue("Animate", (int)animate);

            ImGui::DragFloat3("Center", &center[0], 0.1f);
            m_material->SetUniformValue("Center", glm::vec3(viewMatrix * glm::vec4(center, 1.0f)));

            ImGui::SliderInt("Iterations", &iterations, 1, 25);
            m_material->SetUniformValue("Iterations", iterations);

            ImGui::SliderFloat("Power", &power, 0.1f, 8.0f);
            m_material->SetUniformValue("Power", power);

            ImGui::SliderInt("Steps", &steps, 10, 500);
            m_material->SetUniformValue("Steps", steps);

            ImGui::TreePop();
        }

        if (ImGui::TreeNodeEx("AO", ImGuiTreeNodeFlags_DefaultOpen))
        {
            ImGui::SliderFloat("AO Strength", &aoStrength, 0.0f, 3.0f);
            m_material->SetUniformValue("AOStrength", aoStrength);

            ImGui::SliderInt("AO Steps", &AOSteps, 1, 20);
            m_material->SetUniformValue("AOSteps", AOSteps);

            ImGui::SliderFloat("AO Step Size", &AOStepSize, 0.01f, 0.15f);
            m_material->SetUniformValue("AOStepSize", AOStepSize);

            ImGui::TreePop();
        }

        if (ImGui::TreeNodeEx("Shadow", ImGuiTreeNodeFlags_DefaultOpen))
        {
            ImGui::SliderFloat("Self Shadow Bias", &SelfShadowBias, 0.0f, 0.1f);
            m_material->SetUniformValue("SelfShadowBias", SelfShadowBias);

            ImGui::SliderFloat("Shadow Darkness", &ShadowDarkness, 0.0f, 1.0f);
            m_material->SetUniformValue("ShadowDarkness", ShadowDarkness);

            ImGui::SliderInt("Shadow Steps", &ShadowSteps, 1, 50);
            m_material->SetUniformValue("ShadowSteps", ShadowSteps);

            ImGui::SliderFloat("Shadow Softness", &ShadowSoftness, 0.0f, 128.0f);
            m_material->SetUniformValue("ShadowSoftness", ShadowSoftness);

            ImGui::SliderFloat("Shadow Min Step Size", &ShadowMinStepSize, 0.0f, 1.0f);
            m_material->SetUniformValue("ShadowMinStepSize", ShadowMinStepSize);

            ImGui::TreePop();
        }

        if (ImGui::TreeNodeEx("Light", ImGuiTreeNodeFlags_DefaultOpen))
        {
            ImGui::SliderFloat("Light Intensity", &LightIntensity, 0.0f, 10.0f);
            m_material->SetUniformValue("LightIntensity", LightIntensity);

            ImGui::DragFloat3("Light 1 Position", &Light1Position[0], 0.1f);
            m_material->SetUniformValue("Light0Position", glm::vec3(viewMatrix * glm::vec4(Light1Position, 1.0f)));

            ImGui::DragFloat3("Light 2 Position", &Light2Position[0], 0.1f);
            m_material->SetUniformValue("Light1Position", glm::vec3(viewMatrix * glm::vec4(Light1Position, 1.0f)));

            ImGui::ColorEdit3("Light 1 Color", &Light1Color[0]);
            m_material->SetUniformValue("Light0Color", Light1Color);

            ImGui::ColorEdit3("Light 2 Color", &Light2Color[0]);
            m_material->SetUniformValue("Light1Color", Light2Color);

            ImGui::SliderFloat("Ambient Light", &AmbientLight, 0.0f, 1.0f);
            m_material->SetUniformValue("AmbientLight", AmbientLight);

            ImGui::TreePop();
        }

        if (ImGui::TreeNodeEx("Refraction", ImGuiTreeNodeFlags_DefaultOpen))
        {
            ImGui::SliderFloat("Refraction Intensity", &RefractionIntensity, 0.0f, 10.0f);
            m_material->SetUniformValue("RefractionIntensity", RefractionIntensity);

            ImGui::SliderFloat("Refraction Sharpness", &RefractionSharpness, 0.0f, 10.0f);
            m_material->SetUniformValue("RefractionSharpness", RefractionSharpness);

            ImGui::TreePop();
        }
    }

    m_imGui.EndFrame();
}

void FractalApplication::UpdateCamera()
{
    Window& window = GetMainWindow();

	Camera m_camera = *m_cameraController.GetCamera()->GetCamera();

    // Update if camera is enabled (controlled by SPACE key)
    {
        bool enablePressed = window.IsKeyPressed(GLFW_KEY_SPACE);
        if (enablePressed && !m_cameraEnablePressed)
        {
            m_cameraEnabled = !m_cameraEnabled;
        }
        m_cameraEnablePressed = enablePressed;
    }

    if (!m_cameraEnabled)
        return;

    glm::mat4 viewTransposedMatrix = glm::transpose(m_camera.GetViewMatrix());
    glm::vec3 viewRight = viewTransposedMatrix[0];
    glm::vec3 viewForward = -viewTransposedMatrix[2];

    // Update camera translation
    {
        glm::vec3 inputTranslation(0.0f);

        if (window.IsKeyPressed(GLFW_KEY_A))
            inputTranslation.x = -1.0f;
        else if (window.IsKeyPressed(GLFW_KEY_D))
            inputTranslation.x = 1.0f;

        if (window.IsKeyPressed(GLFW_KEY_W))
            inputTranslation.y = 1.0f;
        else if (window.IsKeyPressed(GLFW_KEY_S))
            inputTranslation.y = -1.0f;

        inputTranslation *= m_cameraTranslationSpeed;
        inputTranslation *= GetDeltaTime();

        m_cameraPosition += inputTranslation.x * viewRight + inputTranslation.y * viewForward;
    }

    // Update view matrix
    m_camera.SetViewMatrix(m_cameraPosition, viewForward);
}

