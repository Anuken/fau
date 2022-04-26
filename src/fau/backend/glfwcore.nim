import staticglfw, ../gl/[glad, gltypes, glproc], ../globals, ../fmath, ../assets, stb_image/read as stbi

# Mostly complete GLFW backend, based on treeform/staticglfw

var running: bool = true
var window: Window

proc getGlfwWindow*(): Window = window

proc toKeyCode(scancode: cint): KeyCode = 
  result = case scancode:
    of KEY_SPACE: keySpace
    of KEY_APOSTROPHE: keyApostrophe
    of KEY_COMMA: keyComma
    of KEY_MINUS: keyMinus
    of KEY_PERIOD: keyPeriod
    of KEY_SLASH: keySlash
    of KEY_0: key0
    of KEY_1: key1
    of KEY_2: key2
    of KEY_3: key3
    of KEY_4: key4
    of KEY_5: key5
    of KEY_6: key6
    of KEY_7: key7
    of KEY_8: key8
    of KEY_9: key9
    of KEY_SEMICOLON: keySemicolon
    of KEY_EQUAL: keyEquals
    of KEY_A: keyA
    of KEY_B: keyB
    of KEY_C: keyC
    of KEY_D: keyD
    of KEY_E: keyE
    of KEY_F: keyF
    of KEY_G: keyG
    of KEY_H: keyH
    of KEY_I: keyI
    of KEY_J: keyJ
    of KEY_K: keyK
    of KEY_L: keyL
    of KEY_M: keyM
    of KEY_N: keyN
    of KEY_O: keyO
    of KEY_P: keyP
    of KEY_Q: keyQ
    of KEY_R: keyR
    of KEY_S: key_s
    of KEY_T: keyT
    of KEY_U: keyU
    of KEY_V: keyV
    of KEY_W: keyW
    of KEY_X: keyX
    of KEY_Y: keyY
    of KEY_Z: keyZ
    of KEY_LEFT_BRACKET: keyLeftBracket
    of KEY_BACKSLASH: keyBackslash
    of KEY_RIGHT_BRACKET: keyRightBracket
    of KEY_GRAVE_ACCENT: keyGrave
    of KEY_ESCAPE: keyEscape
    of KEY_ENTER: keyReturn
    of KEY_TAB: keyTab
    of KEY_BACKSPACE: keyBackspace
    of KEY_INSERT: keyInsert
    of KEY_DELETE: keyDelete
    of KEY_RIGHT: keyRight
    of KEY_LEFT: keyLeft
    of KEY_DOWN: keyDown
    of KEY_UP: keyUp
    of KEY_PAGE_UP: keyPageUp
    of KEY_PAGE_DOWN: keyPageDown
    of KEY_HOME: keyHome
    of KEY_END: keyEnd
    of KEY_CAPS_LOCK: keyCapsLock
    of KEY_SCROLL_LOCK: keyScrollLock
    of KEY_NUM_LOCK: keyNumlockclear
    of KEY_PRINT_SCREEN: keyPrintScreen
    of KEY_PAUSE: keyPause
    of KEY_F1: keyF1
    of KEY_F2: keyF2
    of KEY_F3: keyF3
    of KEY_F4: keyF4
    of KEY_F5: keyF5
    of KEY_F6: keyF6
    of KEY_F7: keyF7
    of KEY_F8: keyF8
    of KEY_F9: keyF9
    of KEY_F10: keyF10
    of KEY_F11: keyF11
    of KEY_F12: keyF12
    of KEY_F13: keyF13
    of KEY_F14: keyF14
    of KEY_F15: keyF15
    of KEY_F16: keyF16
    of KEY_F17: keyF17
    of KEY_F18: keyF18
    of KEY_F19: keyF19
    of KEY_F20: keyF20
    of KEY_F21: keyF21
    of KEY_F22: keyF22
    of KEY_F23: keyF23
    of KEY_F24: keyF24
    of KEY_KP_0: keyKp0
    of KEY_KP_1: keyKp1
    of KEY_KP_2: keyKp2
    of KEY_KP_3: keyKp3
    of KEY_KP_4: keyKp4
    of KEY_KP_5: keyKp5
    of KEY_KP_6: keyKp6
    of KEY_KP_7: keyKp7
    of KEY_KP_8: keyKp8
    of KEY_KP_9: keyKp9
    of KEY_KP_DIVIDE: keyKpDivide
    of KEY_KP_MULTIPLY: keyKpMultiply
    of KEY_KP_ENTER: keyKpEnter
    of KEY_LEFT_SHIFT: keyLshift
    of KEY_LEFT_CONTROL: keyLctrl
    of KEY_LEFT_ALT: keyLalt
    of KEY_RIGHT_SHIFT: keyRShift
    of KEY_RIGHT_CONTROL: keyRCtrl
    of KEY_RIGHT_ALT: keyRAlt
    of KEY_MENU: keyMenu
    else: keyUnknown

proc mapMouseCode(code: cint): KeyCode = 
  result = case code:
    of MOUSE_BUTTON_LEFT: keyMouseLeft
    of MOUSE_BUTTON_RIGHT: keyMouseRight
    of MOUSE_BUTTON_MIDDLE: keyMouseMiddle
    else: keyUnknown

var theLoop: proc()

#wraps the main loop for emscripten compatibility
proc mainLoop(target: proc()) =
  theLoop = target

  when defined(emscripten):
    proc emscripten_set_main_loop(f: proc() {.cdecl.}, a: cint, b: bool) {.importc.}

    emscripten_set_main_loop(proc() {.cdecl.} = theLoop(), 0, true)
  else:
    while window.windowShouldClose() == 0 and running:
      target()

proc fixMouse(x, y: cdouble): Vec2 =
  var
    fwidth: cint
    fheight: cint
  
  window.getFramebufferSize(addr fwidth, addr fheight)

  if fau.size.zero or fwidth == 0 or fheight == 0:
    return vec2()

  let
    sclx = fwidth.float32 / fau.size.x
    scly = fheight.float32 / fau.size.y

  #scale mouse position by framebuffer size
  let pos = vec2((x / max(sclx, 1f)).float32, fau.size.y - 1f - (y / max(scly, 1f)).float32)

  return pos

proc initCore*(loopProc: proc(), initProc: proc() = (proc() = discard), params: FauInitParams) =
  
  discard setErrorCallback(proc(code: cint, desc: cstring) {.cdecl.} =
    raise Exception.newException("Error initializing GLFW: " & $desc & " (error code: " & $code & ")")
  )

  if init() == 0: raise newException(Exception, "Failed to Initialize GLFW")

  echo "Initialized GLFW v3.3.2" #the version constants given are currently incorrect

  defaultWindowHints()
  windowHint(CONTEXT_VERSION_MINOR, 0)
  windowHint(CONTEXT_VERSION_MAJOR, 2)
  if params.depth: windowHint(DEPTH_BITS, 16.cint)
  windowHint(DOUBLEBUFFER, 1)
  windowHint(MAXIMIZED, params.maximize.cint)
  if params.transparent:
    windowHint(TRANSPARENT_FRAMEBUFFER, 1.cint)
  
  if params.undecorated:
    windowHint(DECORATED, 0.cint)

  window = createWindow(params.size.x.cint, params.size.y.cint, params.title, nil, nil)
  window.makeContextCurrent()

  #center window on primary monitor if it's not maximized
  if not params.maximize:
    let 
      monitor = getPrimaryMonitor()
      mode = monitor.getVideoMode()
    
    if mode != nil:
      var mx, my: cint
      getMonitorPos(monitor, mx.addr, my.addr)
      window.setWindowPos(mx + (mode.width - params.size.x.cint) div 2, my + (mode.height - params.size.y.cint) div 2)

  if not loadGl(getProcAddress):
    raise Exception.newException("Failed to load OpenGL.")

  echo "Initialized OpenGL v" & $glVersionMajor & "." & $glVersionMinor

  #load window icon if possible
  when assetExistsStatic("icon.png") and not defined(macosx):
    let textureBytes = assetReadStatic("icon.png")

    var
      width, height, channels: int
      data: seq[uint8]
    
    data = stbi.loadFromMemory(cast[seq[byte]](textureBytes), width, height, channels, 4)

    var image = GlfwImage(width: width.cint, height: height.cint, pixels: cstring(cast[string](data)))
    window.setWindowIcon(1, addr image)

  #listen to window size changes and relevant events.

  discard window.setFramebufferSizeCallback(proc(window: Window, width: cint, height: cint) {.cdecl.} = 
    fireFauEvent(FauEvent(kind: feResize, size: vec2i(width.int, height.int)))
  )

  discard window.setCursorPosCallback(proc(window: Window, x: cdouble, y: cdouble) {.cdecl.} = 
    fireFauEvent FauEvent(kind: feDrag, dragPos: fixMouse(x, y))
  )

  discard window.setKeyCallback(proc(window: Window, key: cint, scancode: cint, action: cint, modifiers: cint) {.cdecl.} = 
    let code = toKeyCode(key)
    
    case action:
      of PRESS: fireFauEvent FauEvent(kind: feKey, key: code, keyDown: true)
      of RELEASE: fireFauEvent FauEvent(kind: feKey, key: code, keyDown: false)
      else: discard
  )

  discard window.setScrollCallback(proc(window: Window, xoffset: cdouble, yoffset: cdouble) {.cdecl.} = 
    #emscripten flips the scrollwheel for some reason: https://github.com/emscripten-core/emscripten/issues/8281
    fireFauEvent FauEvent(kind: feScroll, scroll: vec2(xoffset.float32, when defined(emscripten): -yoffset.float32 else: yoffset.float32))
  )

  discard window.setMouseButtonCallback(proc(window: Window, button: cint, action: cint, modifiers: cint) {.cdecl.} = 
    let code = mapMouseCode(button)

    var 
      mouseX: cdouble = 0
      mouseY: cdouble = 0

    window.getCursorPos(addr mouseX, addr mouseY)

    let pos = fixMouse(mouseX, mouseY)

    case action:
      of PRESS:
        fireFauEvent FauEvent(kind: feTouch, touchPos: pos, touchDown: true, touchButton: code)
      of RELEASE:
        fireFauEvent FauEvent(kind: feTouch, touchPos: pos, touchDown: false, touchButton: code)
      else: discard
  )

  discard window.setWindowIconifyCallback(proc(window: Window, iconified: cint) {.cdecl.} =
    fireFauEvent FauEvent(kind: feVisible, shown: iconified.bool)
  )

  #grab the state at application start
  var 
    inMouseX: cdouble = 0
    inMouseY: cdouble = 0
    inWidth: cint = 0
    inHeight: cint = 0

  window.getCursorPos(addr inMouseX, addr inMouseY)
  window.getFramebufferSize(addr inWidth, addr inHeight)
  
  fau.sizei = vec2i(inWidth.int, inHeight.int)
  fau.size = fau.sizei.vec2
  fau.mouse = fixMouse(inMouseX, inMouseY)

  glInitialized = true
  initProc()

  mainLoop(proc() =
    pollEvents()
    loopProc()
    window.swapBuffers()
  )

  glInitialized = false
  window.destroyWindow()
  terminate()

proc setWindowTitle*(title: string) =
  window.setWindowTitle(title)

proc getCursorPos*(): Vec2 =
  var 
    mouseX: cdouble = 0
    mouseY: cdouble = 0

  getGlfwWindow().getCursorPos(addr mouseX, addr mouseY)

  return fixMouse(mouseX, mouseY)

proc setWindowPos*(pos: Vec2i) =
  window.setWindowPos(pos.x.cint, pos.y.cint)

proc getWindowPos*(): Vec2i =
  var 
    w: cint
    h: cint
  window.getWindowPos(addr w, addr h)
  return vec2i(w.int, h.int)

proc setVsync*(on: bool) =
  swapInterval(on.cint)

#stops the game, does not quit immediately
proc quitApp*() = running = false