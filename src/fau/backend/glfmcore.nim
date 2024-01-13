import glfm, ../gl/[glad, gltypes, glproc], ../globals, ../fmath

# backend for mobile platforms
# NOTE: this backend is unfinished! keyboard doesn't work

proc NimMain() {.importc.}

var
  cloopProc: proc()
  cinitProc: proc()

proc toKeyCode(code: GLFMKey): Keycode =
  return case code:
  of GLFMKeyNavBack, GLFMKeyEscape: keyEscape
  of GLFMKeyLeft: keyLeft
  of GLFMKeyRight: keyRight
  of GLFMKeyUp: keyUp
  of GLFMKeyDown: keyDown
  else: keyUnknown

proc updateInsets(display: ptr GLFMDisplay) =
  var
    top: cdouble
    right: cdouble
    bot: cdouble
    left: cdouble

  display.glfmGetDisplayChromeInsets(top.addr, right.addr, bot.addr, left.addr)
  fau.insets[0] = top.float32
  fau.insets[1] = right.float32
  fau.insets[2] = bot.float32
  fau.insets[3] = left.float32

proc glfmExtensionSupportedWrap(extension: cstring): cint {.cdecl.} =
  let res = glfmExtensionSupported(extension)
  return if res: 1.cint else: 0.cint

proc glfmMain*(display: ptr GLFMDisplay) {.exportc, cdecl.} =
  NimMain()

  when defined(androidFullscreen):
    display.glfmSetDisplayChrome(GLFMUserInterfaceChromeFullscreen)
  
  when defined(androidStatusBar):
    display.glfmSetDisplayChrome(GLFMUserInterfaceChromeNavigationAndStatusBar)

  display.glfmSetDisplayConfig(GLFMRenderingAPIOpenGLES2, GLFMColorFormatRGBA8888, GLFMDepthFormatNone, GLFMStencilFormatNone, GLFMMultisampleNone)

  fau.screenDensity = display.glfmGetDisplayScale().float32

  display.glfmSetSurfaceErrorFunc(proc(display: ptr GLFMDisplay; message: cstring) {.cdecl.} =
    raise Exception.newException("GLFM error: " & $message)
  )

  echo "Initialized GLFM v" & $GLFM_VERSION_MAJOR & "." & $GLFM_VERSION_MINOR

  display.glfmSetSurfaceResizedFunc(proc(surf: ptr GLFMDisplay, width, height: cint) {.cdecl.} = 
    updateInsets(surf)
    fireFauEvent(FauEvent(kind: feResize, size: vec2i(width.int, height.int)))
  )

  display.glfmSetTouchFunc(proc(display: ptr GLFMDisplay, touch: cint, phase: GLFMTouchPhase, x, y: cdouble): bool {.cdecl.} = 
    fau.mouse = vec2(x.float32, fau.size.y - 1 - y.float32)

    if phase == GLFMTouchPhaseBegan or phase == GLFMTouchPhaseEnded:
      fireFauEvent(FauEvent(kind: feTouch, touchId: touch.int, touchPos: vec2(x.float32, fau.size.y - 1 - y.float32), touchDown: phase == GLFMTouchPhaseBegan, touchButton: keyMouseLeft))
    elif phase == GLFMTouchPhaseMoved:
      fireFauEvent(FauEvent(kind: feDrag, dragId: touch.int, dragPos: vec2(x.float32, fau.size.y - 1 - y.float32)))

    return true
  )

  
  display.glfmSetKeyFunc(proc(display: ptr GLFMDisplay, keyCode: GLFMKey, action: GLFMKeyAction, modifiers: cint): bool {.cdecl.} = 
    let code = toKeyCode(keyCode)
    
    case action:
      of GLFMKeyActionPressed:
        fireFauEvent FauEvent(kind: feKey, key: code, keyDown: true)
        return true
      of GLFMKeyActionReleased: 
        fireFauEvent FauEvent(kind: feKey, key: code, keyDown: false)
        return true
      else: discard

    return false
  )

  display.glfmSetSurfaceCreatedFunc(proc(surf: ptr GLFMDisplay, width, height: cint) {.cdecl.} = 

    if not loadGl(glfmGetProcAddress, glfmExtensionSupportedWrap):
      raise Exception.newException("Failed to load OpenGL.")

    echo "Initialized OpenGL v" & $glVersionMajor & "." & $glVersionMinor

    fau.sizei = vec2i(width.int, height.int)
    updateInsets(surf)

    glInitialized = true
    cinitProc()
  )

  display.glfmSetMainLoopFunc(proc(display: ptr GLFMDisplay; frameTime: cdouble) {.cdecl.} =
    cloopProc()
  )

  display.glfmSetSurfaceDestroyedFunc(proc(display: ptr GLFMDisplay) {.cdecl.} =
    glInitialized = false
    #force an exit to clean up resources, ditch the Android app lifecycle
    quit(QuitSuccess)
  )

  display.glfmSetAppFocusFunc(proc(display: ptr GLFMDisplay, focused: bool) {.cdecl.} =
    fireFauEvent(FauEvent(kind: feVisible, shown: focused))
  )
  
#TODO most parameters are ignored here, depth matters!
proc initCore*(loopProc: proc(), initProc: proc() = (proc() = discard), params: FauInitParams) =
  cloopProc = loopProc
  cinitProc = initProc

#implemented as a stub method for feature parity
proc `windowTitle=`*(title: string) = discard

#stops the game immediately
proc quitApp*() = quit(0)

#dummy code for cross-platform support, does nothing
type Cursor* = object
proc newCursor*(path: static string): Cursor = Cursor()
proc setCursor*(cursor: Cursor) = discard