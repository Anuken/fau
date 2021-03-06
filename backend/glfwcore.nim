import staticglfw, glad

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

proc initCore*(loopProc: proc(), initProc: proc() = (proc() = discard), windowWidth = 800, windowHeight = 600, windowTitle = "Unknown", maximize = true) =
  
  discard setErrorCallback(proc(code: cint, desc: cstring) {.cdecl.} =
    raise Exception.newException("Error initializing GLFW: " & $desc & " (error code: " & $code & ")")
  )

  if init() == 0: raise newException(Exception, "Failed to Initialize GLFW")

  echo "Initialized GLFW v3.3.2" #the version constants given are currently incorrect

  defaultWindowHints()
  windowHint(CONTEXT_VERSION_MINOR, 0)
  windowHint(CONTEXT_VERSION_MAJOR, 2)
  windowHint(DOUBLEBUFFER, 1)
  windowHint(MAXIMIZED, maximize.cint)

  window = createWindow(windowWidth.cint, windowHeight.cint, windowTitle, nil, nil)
  window.makeContextCurrent()

  #center window on primary monitor if it's not maximized
  if not maximize:
    let 
      monitor = getPrimaryMonitor()
      mode = monitor.getVideoMode()
    
    if mode != nil:
      var mx, my: cint
      getMonitorPos(monitor, mx.addr, my.addr)
      window.setWindowPos(mx + (mode.width - windowWidth.cint) div 2, my + (mode.height - windowHeight.cint) div 2)

  if not loadGl(getProcAddress):
    raise Exception.newException("Failed to load OpenGL.")

  echo "Initialized OpenGL v" & $glVersionMajor & "." & $glVersionMinor

  #listen to window size changes and relevant events.

  discard window.setFramebufferSizeCallback(proc(window: Window, width: cint, height: cint) {.cdecl.} = 
    fireFauEvent(FauEvent(kind: feResize, w: width.int, h: height.int))
  )

  discard window.setCursorPosCallback(proc(window: Window, x: cdouble, y: cdouble) {.cdecl.} = 
    fireFauEvent FauEvent(kind: feDrag, dragPos: vec2(x.float32, fau.height.float32 - 1 - y.float32))
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

    case action:
      of PRESS:
        fireFauEvent FauEvent(kind: feTouch, touchPos: fau.mouse, touchDown: true, touchButton: code)
      of RELEASE:
        fireFauEvent FauEvent(kind: feTouch, touchPos: fau.mouse, touchDown: false, touchButton: code)
      else: discard
  )

  #grab the state at application start
  var 
    inMouseX: cdouble = 0
    inMouseY: cdouble = 0
    inWidth: cint = 0
    inHeight: cint = 0

  window.getCursorPos(addr inMouseX, addr inMouseY)
  window.getFramebufferSize(addr inWidth, addr inHeight)
  fau.mouse = vec2(inHeight.float32 - 1 - inMouseX.float32, inMouseY.float32)
  fau.width = inWidth.int
  fau.height = inHeight.int
  
  glViewport(0.GLint, 0.GLint, inWidth.GLsizei, inHeight.GLsizei)

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

#set window title
proc `windowTitle=`*(title: string) =
  window.setWindowTitle(title)

#stops the game, does not quit immediately
proc quitApp*() = running = false