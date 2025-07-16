#include "FractalExplorerApplication.h"
#include <ituGL/asset/ShaderLoader.h>
#include <ituGL/camera/Camera.h>
#include <ituGL/scene/SceneCamera.h>
#include <ituGL/lighting/DirectionalLight.h>
#include <ituGL/shader/Material.h>
#include <ituGL/renderer/PostFXRenderPass.h>
#include <ituGL/utils/DearImGui.h>
#include <imgui.h>
#include <glm/gtx/transform.hpp>
#include <glm/gtx/euler_angles.hpp>

FractalExplorerApplication::FractalExplorerApplication()
    : Application(1024, 768, "Interactive Fractal Explorer")
    , m_renderer(GetDevice()) {
}

void FractalExplorerApplication::Initialize() {
    Application::Initialize();
    m_imGui.Initialize(GetMainWindow());
    InitializeCamera();
    InitializeMaterials();
    InitializeRenderer();
}

void FractalExplorerApplication::InitializeCamera() {
    auto cam = std::make_shared<Camera>();
    cam->SetViewMatrix({ 0,0,5 }, { 0,0,-1 }, { 0,1,0 });
    cam->SetPerspectiveProjectionMatrix(
        1.0f,
        GetMainWindow().GetAspectRatio(),
        0.1f,
        100.0f
    );
    auto sceneCam = std::make_shared<SceneCamera>("camera", cam);
    m_cameraController.SetCamera(sceneCam);
}

void FractalExplorerApplication::InitializeMaterials() {
    m_fractalMaterials.clear();
    m_fractalMaterials.push_back(
        CreateRaymarchMaterial("shaders/mandelbulb.frag")
    );
    m_fractalMaterials.push_back(
        CreateRaymarchMaterial("shaders/menger.frag")
    );
    // ... add more fractals as needed
}

void FractalExplorerApplication::InitializeRenderer() {
    // Re-create renderer and apply the current fractal material
    m_renderer.AddRenderPass(
        std::make_unique<PostFXRenderPass>(
            m_fractalMaterials[m_currentFractal]
        )
    );
}

void FractalExplorerApplication::Update() {
    Application::Update();
    m_cameraController.Update(
        GetMainWindow(),
        GetDeltaTime()
    );
    const Camera& cam = *m_cameraController
        .GetCamera()
        ->GetCamera();
    auto material = m_fractalMaterials[m_currentFractal];
    material->SetUniformValue(
        "ProjMatrix",
        cam.GetProjectionMatrix()
    );
    material->SetUniformValue(
        "InvProjMatrix",
        glm::inverse(cam.GetProjectionMatrix())
    );
}

void FractalExplorerApplication::Render() {
    Application::Render();
    GetDevice().Clear(
        true, { 0,0,0,1 },
        true, 1.0f
    );
    m_renderer.Render();
    m_imGui.BeginFrame();
    SetupUI();
    m_imGui.EndFrame();
}

void FractalExplorerApplication::SetupUI() {
    if (auto window = m_imGui.UseWindow("Fractal Explorer")) {
        ImGui::Combo(
            "Fractal Type",
            &m_currentFractal,
            "Mandelbulb�Menger Sponge�Julia Set�"
        );
        if (ImGui::Button("Apply")) {
            InitializeRenderer();
        }
        if (m_currentFractal == 0) {
            float* powerPtr =
                m_fractalMaterials[0]
                ->GetDataUniformPointer<float>("Power");
            ImGui::SliderFloat(
                "Power",
                powerPtr,
                2.0f,
                8.0f
            );
            // Additional Mandelbulb parameters...
        }
        // Add UI for other fractals here
    }
}

std::shared_ptr<Material> FractalExplorerApplication::CreateRaymarchMaterial(
    const char* fragPath
) {
    std::vector<const char*> vert = {
        "shaders/version330.glsl",
        "shaders/renderer/fullscreen.vert"
    };
    Shader vs = ShaderLoader(Shader::VertexShader)
        .Load(vert);

    std::vector<const char*> frag = {
        "shaders/version330.glsl",
        "shaders/utils.glsl",
        "shaders/sdflibrary.glsl",
        "shaders/raymarcher.glsl",
        "shaders/fractals.glsl",
        fragPath,
        "shaders/raymarching.frag"
    };
    Shader fs = ShaderLoader(Shader::FragmentShader)
        .Load(frag);

    auto prog = std::make_shared<ShaderProgram>();
    prog->Build(vs, fs);
    return std::make_shared<Material>(prog);
}

void FractalExplorerApplication::Cleanup() {
    m_imGui.Cleanup();
    Application::Cleanup();
}