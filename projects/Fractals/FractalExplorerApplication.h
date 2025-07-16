#pragma once

#include <ituGL/application/Application.h>
#include <ituGL/renderer/Renderer.h>
#include <ituGL/camera/CameraController.h>
#include <ituGL/utils/DearImGui.h>

class Material;

class FractalExplorerApplication : public Application {
public:
    FractalExplorerApplication();

protected:
    void Initialize() override;
    void Update() override;
    void Render() override;
    void Cleanup() override;

private:
    void InitializeCamera();
    void InitializeMaterials();
    void InitializeRenderer();
    void SetupUI();

    std::shared_ptr<Material> CreateRaymarchMaterial(const char* fragmentShaderPath);

    // Helpers
    DearImGui m_imGui;
    CameraController m_cameraController;
    Renderer      m_renderer;
    std::vector<std::shared_ptr<Material>> m_fractalMaterials;
    int m_currentFractal = 0;
};