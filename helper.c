#include <assert.h>
#include "embedder.h"

bool export_make_current(void *user_data);
bool export_clear_current(void *user_data);
bool export_present(void *user_data);
void *export_glfwGetWindowUserPointer(void *user_data);

uint32_t fbo_callback(void *user_data) {
    return 0;
}

void glfwWindowSizeCallback(void *window, int width, int height) {
    FlutterWindowMetricsEvent event = {};
    event.struct_size = sizeof(event);
    event.width = width;
    event.height = height;
    event.pixel_ratio = 1.0;
    FlutterEngineSendWindowMetricsEvent(export_glfwGetWindowUserPointer(window), &event);
}

void glfwCursorPositionCallbackAtPhase(void *window,
                                       FlutterPointerPhase phase, double x,
                                       double y) {
    FlutterPointerEvent event = {};
    event.struct_size = sizeof(event);
    event.phase = phase;
    event.x = x;
    event.y = y;
    event.timestamp = (size_t)(FlutterEngineGetCurrentTime() * 1000);
    FlutterEngineSendPointerEvent(export_glfwGetWindowUserPointer(window), &event, 1);
}

#define MY_PROJECT "."

FlutterEngine runFlutter(void *window) {
    FlutterRendererConfig config = {};
    config.type = kOpenGL;
    config.open_gl.struct_size = sizeof(config.open_gl);
    config.open_gl.make_current = export_make_current;
    config.open_gl.clear_current = export_clear_current;
    config.open_gl.present = export_present;
    config.open_gl.fbo_callback = fbo_callback;
    // config.open_gl.make_resource_current = NULL;

    FlutterProjectArgs args = {
        .struct_size = sizeof(FlutterProjectArgs),
        .assets_path = MY_PROJECT "/flutter_assets",
        .main_path__unused__ = NULL,
        .packages_path__unused__ = NULL,
        .icu_data_path = MY_PROJECT "/flutter_assets/icudtl.dat",
    };
    FlutterEngine engine = NULL;

    FlutterEngineResult result = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config, &args, window, &engine);

    assert(result == kSuccess && engine != NULL);

    return engine;
}
