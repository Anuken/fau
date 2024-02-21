import staticglfw, ../gl/[glad, gltypes, glproc], ../globals, ../fmath, ../assets, ../util/util, stb_image/read as stbi

# Mostly complete GLFW backend, based on treeform/staticglfw

type 
  CursorObj = object
    handle: CursorHandle
  Cursor* = ref CursorObj

var 
  running: bool = true
  window: Window
  windowedRect: (cint, cint, cint, cint) = (0, 0, 480, 320)

proc `=destroy`(cursor: var CursorObj) =
  if cursor.handle != nil and glInitialized:
    destroyCursor(cursor.handle)
    cursor.handle = nil

proc toGLfwImage(img: Img): GlfwImage = GlfwImage(width: img.width.cint, height: img.height.cint, pixels: cstring(cast[string](img.data)))

proc newCursor*(path: static string): Cursor =
  let 
    img = loadImg(path)
    glfwImage = toGlfwImage(img)
    handle = createCursor(addr glfwImage, (img.width div 2).cint, (img.height div 2).cint)
  return Cursor(handle: handle)

proc getGlfwWindow*(): Window = window

proc toKeyCode(keycode: cint): KeyCode = 
  result = case keycode:
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
    winwidth: cint
    winheight: cint
  
  window.getFramebufferSize(addr fwidth, addr fheight)
  window.getWindowSize(addr winwidth, addr winheight)

  if winwidth == 0 or winheight == 0 or fwidth == 0 or fheight == 0:
    return vec2()

  let
    sclx = fwidth.float32 / winwidth.float32
    scly = fheight.float32 / winheight.float32

  #scale mouse position by framebuffer size
  let pos = vec2((x * max(sclx, 1f)).float32, fau.size.y - 1f - (y * max(scly, 1f)).float32)

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
  windowHint(FLOATING, params.floating.cint)
  if params.transparent:
    windowHint(TRANSPARENT_FRAMEBUFFER, 1.cint)
  
  if params.undecorated:
    windowHint(DECORATED, 0.cint)

  if (paramCount() > 0 and paramStr(1) == "-coreProfile") or defined(macosx):
    windowHint(CONTEXT_VERSION_MAJOR, 3)
    windowHint(CONTEXT_VERSION_MINOR, 2)
    windowHint(OPENGL_PROFILE, OPENGL_CORE_PROFILE)

  window = createWindow(params.size.x.cint, params.size.y.cint, params.title.cstring, nil, nil)
  window.makeContextCurrent()

  swapInterval(1)

  #center window on primary monitor if it's not maximized
  if not params.maximize:
    let 
      monitor = getPrimaryMonitor()
      mode = monitor.getVideoMode()
    
    if mode != nil:
      var mx, my: cint
      getMonitorPos(monitor, mx.addr, my.addr)
      window.setWindowPos(mx + (mode.width - params.size.x.cint) div 2, my + (mode.height - params.size.y.cint) div 2)

  if not loadGl(getProcAddress, extensionSupported):
    raise Exception.newException("Failed to load OpenGL.")

  echo "Initialized OpenGL v", glVersionMajor, ".", glVersionMinor, " [VAO: ", supportsVertexArrays, "]"

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
  
  #emscripten does not support the gamepad API https://github.com/emscripten-core/emscripten/issues/20446
  when not defined(emscripten):
    discard setJoystickCallback(proc(joy: cint, event: cint) {.cdecl.} =
      if event == Connected and joystickIsGamepad(joy) != 0:
        let gamepad = Gamepad(index: joy.int, name: $getGamepadName(joy))
        fau.gamepads.add(gamepad)

        fireFauEvent FauEvent(kind: feGamepadChanged, connected: true, gamepad: gamepad)
      elif event == Disconnected:
        let index = fau.gamepads.findIt(it.index == joy.int)
        if index != -1:
          fireFauEvent FauEvent(kind: feGamepadChanged, connected: true, gamepad: fau.gamepads[index])
          fau.gamepads.delete(index)
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

  #find existing gamepads at game startup
  when not defined(emscripten):
    for i in 0..<8:
      if joystickPresent(i.cint) != 0 and joystickIsGamepad(i.cint) != 0:
        let gamepad = Gamepad(index: i.int, name: $getGamepadName(i.cint))
        fau.gamepads.add(gamepad)

        fireFauEvent FauEvent(kind: feGamepadChanged, connected: true, gamepad: gamepad)

  mainLoop(proc() =
    pollEvents()

    #update controller/gamepad state
    when not defined(emscripten):
      for pad in fau.gamepads:
        var state: GamepadState
        if getGamepadState(pad.index.cint, addr state) != 0:
          pad.axes[leftX] = state.axes[GamepadAxisLeftX]
          pad.axes[leftY] = -state.axes[GamepadAxisLeftY]
          pad.axes[rightX] = state.axes[GamepadAxisRightX]
          pad.axes[rightY] = -state.axes[GamepadAxisRightY]
          pad.axes[leftTrigger] = state.axes[GamepadAxisLeftTrigger]
          pad.axes[rightTrigger] = state.axes[GamepadAxisRightTrigger]
          
          var buttons: array[GamepadButton, bool]

          buttons[a] = state.buttons[GamepadButtonA].bool
          buttons[b] = state.buttons[GamepadButtonB].bool
          buttons[x] = state.buttons[GamepadButtonX].bool
          buttons[y] = state.buttons[GamepadButtonY].bool

          buttons[leftBumper] = state.buttons[GamepadButtonLeftBumper].bool
          buttons[rightBumper] = state.buttons[GamepadButtonRightBumper].bool
          buttons[back] = state.buttons[GamepadButtonBack].bool
          buttons[start] = state.buttons[GamepadButtonStart].bool
          buttons[guide] = state.buttons[GamepadButtonGuide].bool
          buttons[leftThumb] = state.buttons[GamepadButtonLeftThumb].bool
          buttons[rightThumb] = state.buttons[GamepadButtonRightThumb].bool
          buttons[dpadUp] = state.buttons[GamepadButtonDpadUp].bool
          buttons[dpadRight] = state.buttons[GamepadButtonDpadRight].bool
          buttons[dpadDown] = state.buttons[GamepadButtonDpadDown].bool
          buttons[dpadLeft] = state.buttons[GamepadButtonDpadLeft].bool
        
          for but in GamepadButton:
            pad.buttonsJustDown[but] = buttons[but] and not pad.buttons[but]
            pad.buttonsJustUp[but]= not buttons[but] and pad.buttons[but]
          
          pad.buttons = buttons

    loopProc()
    window.swapBuffers()
  )

  glInitialized = false
  window.destroyWindow()
  terminate()

proc setWindowTitle*(title: string) =
  window.setWindowTitle(title)

proc setWindowDecorated*(decorated: bool) =
  window.setWindowAttrib(DECORATED, decorated.cint)

proc setWindowFloating*(floating: bool) =
  window.setWindowAttrib(FLOATING, floating.cint)

proc setClipboardString*(text: string) =
  window.setClipboardString(text.cstring)

proc getClipboardString*(): string =
  $window.getClipboardString()

proc setCursor*(cursor: Cursor) =
  window.setCursor(cursor.handle)

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

proc getWindowSize*(): Vec2i =
  var 
    w: cint
    h: cint
  window.getWindowSize(addr w, addr h)
  return vec2i(w.int, h.int)

proc setWindowSize*(size: Vec2i) =
  window.setWindowSize(size.x.cint, size.y.cint)

proc setVsync*(on: bool) =
  swapInterval(on.cint)

proc isMaximized*(): bool = window.getWindowAttrib(MAXIMIZED).bool

proc isFullscreen*(): bool =
  return window.getWindowMonitor() != nil

proc setFullscreen*(on: bool) =
  #pointless
  if isFullscreen() == on or defined(emscripten):
    return

  let mode = getVideoMode(getPrimaryMonitor())
  if on:
    #save fullscreen rectangle
    window.getWindowPos(addr windowedRect[0], addr windowedRect[1])
    window.getWindowSize(addr windowedRect[2], addr windowedRect[3])

    window.setWindowMonitor(getPrimaryMonitor(), 0, 0, mode.width, mode.height, mode.refreshRate)
  else:
    window.setWindowMonitor(nil, windowedRect[0], windowedRect[1], windowedRect[2], windowedRect[3], 0)

proc toggleFullscreen*() =
  setFullscreen(not isFullscreen())

proc setCursorHidden*(hidden: bool) =
  window.setInputMode(staticglfw.CURSOR, if hidden: CursorHidden.cint else: CursorNormal.cint)

#stops the game, does not quit immediately
proc quitApp*() = running = false