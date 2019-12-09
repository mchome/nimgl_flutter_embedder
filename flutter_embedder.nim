# nim c -r -f -d:release --app:gui flutter_embedder.nim

import nimgl/glfw

const kInitialWindowWidth = 800
const kInitialWindowHeight = 600

type
  FlutterPointerPhase* {.size: sizeof(cint).} = enum
    kCancel, kUp, kDown, kMove, kAdd, kRemove, kHover

proc keyCallback(window: GLFWWindow; key: int32; scancode: int32;
             action: int32; mods: int32): void {.cdecl.} =
  if key == GLFWKey.ESCAPE and action == GLFWPress:
    window.setWindowShouldClose(true)

proc make_current(userdata: pointer): bool {.exportc: "export_$1".} =
  makeContextCurrent(cast[GLFWWindow](userdata))
  return true

proc clear_current(userdata: pointer): bool {.exportc: "export_$1".} =
  makeContextCurrent(nil)
  return true

proc present(userdata: pointer): bool {.exportc: "export_$1".} =
  swapBuffers(cast[GLFWWindow](userdata))
  return true

proc glfwGetWindowUserPointer(userdata: pointer): pointer {.
    exportc: "export_$1".} =
  return getWindowUserPointer(cast[GLFWWindow](userdata))

{.compile: "helper.c", passL: "flutter_engine.dll".}
proc runFlutter(window: pointer): pointer {.importc: "runFlutter".}
proc glfwWindowSizeCallback(window: pointer; width: int; height: int) {.
    importc: "glfwWindowSizeCallback".}
proc glfwCursorPositionCallbackAtPhase(window: pointer;
    phase: FlutterPointerPhase; x: float; y: float) {.
    importc: "glfwCursorPositionCallbackAtPhase".}

proc windowSizeCallback(window: GLFWWindow; width: int32;
    height: int32): void {.cdecl.} =
  glfwWindowSizeCallback(window, width, height)

proc cursorPosCallback(window: GLFWWindow; x: float64;
    y: float64): void {.cdecl.} =
  glfwCursorPositionCallbackAtPhase(window, FlutterPointerPhase.kMove, x, y)

proc mouseButtonCallback(window: GLFWWindow; button: int32; action: int32;
    mods: int32): void {.cdecl.} =
  if button == GLFWMouseButton.Button1:
    var x, y: float64
    getCursorPos(window, x.addr, y.addr)
    if action == GLFWPress:
      glfwCursorPositionCallbackAtPhase(window, FlutterPointerPhase.kDown, x, y)
      discard setCursorPosCallback(window, cursorPosCallback)
    elif action == GLFWRelease:
      glfwCursorPositionCallbackAtPhase(window, FlutterPointerPhase.kUp, x, y)
      discard setCursorPosCallback(window, nil)

proc main() =
  assert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  # glfwWindowHint(GLFWResizable, GLFW_FALSE)

  let w: GLFWWindow = glfwCreateWindow(kInitialWindowWidth,
      kInitialWindowHeight, "Flutter Embedder in Nim")
  if w == nil: quit(-1)

  let engine: pointer = runFlutter(w)
  setWindowUserPointer(w, engine)
  glfwWindowSizeCallback(w, kInitialWindowWidth, kInitialWindowHeight);

  discard setKeyCallback(w, keyCallback)
  discard setWindowSizeCallback(w, windowSizeCallback)
  discard setMouseButtonCallback(w, mouseButtonCallback)

  while not windowShouldClose(w):
    glfwWaitEvents()

  destroyWindow(w)
  glfwTerminate()

main()
