import pkg/sdl3

import ../gl/[glproc], ../util/misc, std/strutils

#SDL3 backend - used in place of the GLFW backend for better support for controllers

type 
  CursorObj = object
    handle: sdl3.Cursor
  Cursor* = ref CursorObj

var 
  running: bool = true
  window: Window
  glContext: GLContext

proc `=destroy`(cursor: var CursorObj) =
  if cursor.handle != nil and glInitialized:
    destroyCursor(cursor.handle)
    cursor.handle = nil

template checkError(val: bool): untyped =
  if not val:
    let error = getError()
    raise newException(Exception, "SDL error: " & $error)

proc newCursor*(path: static string): Cursor =
  let 
    img = loadRawImage(path)
    surface = createSurfaceFrom(img.width.cint, img.height.cint, PixelFormatRgba32, cast[pointer](img.data), (img.width * 4).cint)
  
  if surface == nil:
    freeRawImage(img)
    return nil

  let handle = createColorCursor(surface, (img.width div 2).cint, (img.height div 2).cint)
  destroySurface(surface)
  freeRawImage(img)

  return Cursor(handle: handle)

proc newCursor*(standardType: CursorType): Cursor = 
  let mapped = case standardType:
  of cursorArrow: SystemCursorDefault
  of cursorIbeam: SystemCursorText
  of cursorCrosshair: SystemCursorCrosshair
  of cursorHand: SystemCursorPointer
  of cursorResizeH: SystemCursorEwResize
  of cursorResizeV: SystemCursorNsResize
  of cursorResizeNwse: SystemCursorNwseResize
  of cursorResizeNesw: SystemCursorNeswResize
  of cursorResizeAll: SystemCursorNwseResize
  of cursorNotAllowed: SystemCursorNotAllowed

  let handle = createSystemCursor(mapped)

  return if handle == nil and mapped != SystemCursorDefault: newCursor(cursorArrow) else: Cursor(handle: handle)

proc getSdlWindow*(): Window = window

proc toKeyCode(keycode: Scancode): globals.KeyCode = 
  result = case keycode:
    of SCANCODE_SPACE: keySpace
    of SCANCODE_APOSTROPHE: keyApostrophe
    of SCANCODE_COMMA: keyComma
    of SCANCODE_MINUS: keyMinus
    of SCANCODE_PERIOD: keyPeriod
    of SCANCODE_SLASH: keySlash
    of SCANCODE_0: key0
    of SCANCODE_1: key1
    of SCANCODE_2: key2
    of SCANCODE_3: key3
    of SCANCODE_4: key4
    of SCANCODE_5: key5
    of SCANCODE_6: key6
    of SCANCODE_7: key7
    of SCANCODE_8: key8
    of SCANCODE_9: key9
    of SCANCODE_SEMICOLON: keySemicolon
    of SCANCODE_EQUALS: keyEquals
    of SCANCODE_A: keyA
    of SCANCODE_B: keyB
    of SCANCODE_C: keyC
    of SCANCODE_D: keyD
    of SCANCODE_E: keyE
    of SCANCODE_F: keyF
    of SCANCODE_G: keyG
    of SCANCODE_H: keyH
    of SCANCODE_I: keyI
    of SCANCODE_J: keyJ
    of SCANCODE_K: keyK
    of SCANCODE_L: keyL
    of SCANCODE_M: keyM
    of SCANCODE_N: keyN
    of SCANCODE_O: keyO
    of SCANCODE_P: keyP
    of SCANCODE_Q: keyQ
    of SCANCODE_R: keyR
    of SCANCODE_S: keyS
    of SCANCODE_T: keyT
    of SCANCODE_U: keyU
    of SCANCODE_V: keyV
    of SCANCODE_W: keyW
    of SCANCODE_X: keyX
    of SCANCODE_Y: keyY
    of SCANCODE_Z: keyZ
    of SCANCODE_LEFTBRACKET: keyLeftBracket
    of SCANCODE_BACKSLASH: keyBackslash
    of SCANCODE_RIGHTBRACKET: keyRightBracket
    of SCANCODE_GRAVE: keyGrave
    of SCANCODE_ESCAPE: keyEscape
    of SCANCODE_RETURN: keyReturn
    of SCANCODE_TAB: keyTab
    of SCANCODE_BACKSPACE: keyBackspace
    of SCANCODE_INSERT: keyInsert
    of SCANCODE_DELETE: keyDelete
    of SCANCODE_RIGHT: keyRight
    of SCANCODE_LEFT: keyLeft
    of SCANCODE_DOWN: keyDown
    of SCANCODE_UP: keyUp
    of SCANCODE_PAGEUP: keyPageUp
    of SCANCODE_PAGEDOWN: keyPageDown
    of SCANCODE_HOME: keyHome
    of SCANCODE_END: keyEnd
    of SCANCODE_CAPSLOCK: keyCapsLock
    of SCANCODE_SCROLLLOCK: keyScrollLock
    of SCANCODE_NUMLOCKCLEAR: keyNumlockclear
    of SCANCODE_PRINTSCREEN: keyPrintScreen
    of SCANCODE_PAUSE: keyPause
    of SCANCODE_F1: keyF1
    of SCANCODE_F2: keyF2
    of SCANCODE_F3: keyF3
    of SCANCODE_F4: keyF4
    of SCANCODE_F5: keyF5
    of SCANCODE_F6: keyF6
    of SCANCODE_F7: keyF7
    of SCANCODE_F8: keyF8
    of SCANCODE_F9: keyF9
    of SCANCODE_F10: keyF10
    of SCANCODE_F11: keyF11
    of SCANCODE_F12: keyF12
    of SCANCODE_F13: keyF13
    of SCANCODE_F14: keyF14
    of SCANCODE_F15: keyF15
    of SCANCODE_F16: keyF16
    of SCANCODE_F17: keyF17
    of SCANCODE_F18: keyF18
    of SCANCODE_F19: keyF19
    of SCANCODE_F20: keyF20
    of SCANCODE_F21: keyF21
    of SCANCODE_F22: keyF22
    of SCANCODE_F23: keyF23
    of SCANCODE_F24: keyF24
    of SCANCODE_KP_0: keyKp0
    of SCANCODE_KP_1: keyKp1
    of SCANCODE_KP_2: keyKp2
    of SCANCODE_KP_3: keyKp3
    of SCANCODE_KP_4: keyKp4
    of SCANCODE_KP_5: keyKp5
    of SCANCODE_KP_6: keyKp6
    of SCANCODE_KP_7: keyKp7
    of SCANCODE_KP_8: keyKp8
    of SCANCODE_KP_9: keyKp9
    of SCANCODE_KP_MINUS: keyKpMinus
    of SCANCODE_KP_PLUS: keyKpPlus
    of SCANCODE_KP_DIVIDE: keyKpDivide
    of SCANCODE_KP_MULTIPLY: keyKpMultiply
    of SCANCODE_KP_ENTER: keyKpEnter
    of SCANCODE_LSHIFT: keyLshift
    of SCANCODE_LCTRL: keyLctrl
    of SCANCODE_LALT: keyLalt
    of SCANCODE_LGUI: keyLsuper
    of SCANCODE_RSHIFT: keyRShift
    of SCANCODE_RCTRL: keyRCtrl
    of SCANCODE_RALT: keyRAlt
    of SCANCODE_RGUI: keyRsuper
    of SCANCODE_MENU: keyMenu
    else: keyUnknown

proc mapMouseCode(code: uint8): globals.KeyCode = 
  result = case code:
  of ButtonLeft: keyMouseLeft
  of ButtonRight: keyMouseRight
  of ButtonMiddle: keyMouseMiddle
  of ButtonX2: keyMouseForward
  of ButtonX1: keyMouseBack
  else: keyUnknown

#will return an empty string for unknown keys
proc getKeyName*(code: Scancode): string = 
  var keyNames {.global.}: array[290, string]

  once:
    for i in 0..<keyNames.len:
      let key = toKeyCode(i.Scancode)
      if key != keyUnknown:
        let val = $getScancodeName(i.Scancode)
        keyNames[i] = (if val.len == 1: capitalizeAscii(val) else: val)
    
  return keyNames[code.int]

var theLoop: proc()

#wraps the main loop for emscripten compatibility
proc mainLoop(target: proc()) =
  theLoop = target

  when defined(emscripten):
    proc emscripten_set_main_loop(f: proc() {.cdecl.}, a: cint, b: bool) {.importc.}
    emscripten_set_main_loop(proc() {.cdecl.} = theLoop(), 0, true)
  else:
    while running:
      target()

proc fixMouse(x, y: float32): Vec2 =
  var
    fwidth: cint
    fheight: cint
    winwidth: cint
    winheight: cint
  
  checkError window.getWindowSizeInPixels(fwidth, fheight)
  checkError window.getWindowSize(winwidth, winheight)

  if winwidth == 0 or winheight == 0 or fwidth == 0 or fheight == 0:
    return vec2()

  let
    sclx = fwidth.float32 / winwidth.float32
    scly = fheight.float32 / winheight.float32

  #scale mouse position by framebuffer size
  let pos = vec2((x * max(sclx, 1f)).float32, fau.size.y - 1f - (y * max(scly, 1f)).float32)

  return pos

proc processEvents() =
  var event: Event
  while pollEvent(event):
    case event.type:
    of EventQuit:
      running = false

    of EventWindowResized:
      fireFauEvent(FauEvent(kind: feResize, size: vec2i(event.window.data1.int, event.window.data2.int)))

    of EventMouseMotion:
      fireFauEvent(FauEvent(kind: feDrag, dragPos: fixMouse(event.motion.x, event.motion.y)))

    of EventTextInput:
      if event.text.text != nil and event.text.text[0] != '\0':
        fireFauEvent(FauEvent(kind: feText, text: event.text.text[0].uint32))

    of EventKeyDown, EventKeyUp:
      let down = event.type == EventKeyDown
      let code = toKeyCode(event.key.scancode)
      fireFauEvent(FauEvent(kind: feKey, key: code, keyDown: down))

    of EventMouseWheel:
      let yOffset = when defined(emscripten): -event.wheel.y else: event.wheel.y
      fireFauEvent(FauEvent(kind: feScroll, scroll: vec2(event.wheel.x, yOffset)))

    of EventMouseButtonDown, EventMouseButtonUp:
      let down = event.type == EventMouseButtonDown
      let code = mapMouseCode(event.button.button)
      let pos = fixMouse(event.button.x, event.button.y)
      fireFauEvent(FauEvent(kind: feTouch, touchPos: pos, touchDown: down, touchButton: code))

    of EventWindowMinimized, EventWindowRestored:
      fireFauEvent(FauEvent(kind: feVisible, shown: event.type == EventWindowRestored))

    of EventGamepadAdded:
      let id = event.gdevice.which
      let gamepadHandle = openGamepad(id)
      if gamepadHandle != nil:
        let gamepad = globals.Gamepad(index: id.int, name: $getGamepadName(gamepadHandle))
        fau.gamepads.add(gamepad)
        fireFauEvent(FauEvent(kind: feGamepadChanged, connected: true, gamepad: gamepad))

    of EventGamepadRemoved:
      let id = event.gdevice.which
      let index = fau.gamepads.findIt(it.index == id.int)
      if index != -1:
        fireFauEvent(FauEvent(kind: feGamepadChanged, connected: false, gamepad: fau.gamepads[index]))
        fau.gamepads.delete(index)

    else: discard

proc updateGamepads() =
  for pad in fau.gamepads:
    let gamepad = getGamepadFromID(pad.index.JoystickID)
    if gamepad != nil:

      #thumbsticks are scaled from [0, 32767] to [-1.0f, 1.0f] to match GLFW boundaries
      pad.axes[leftX] = getGamepadAxis(gamepad, GamepadAxisLeftX).float32 / 32767.0f
      pad.axes[leftY] = -(getGamepadAxis(gamepad, GamepadAxisLeftY).float32 / 32767.0f)
      pad.axes[rightX] = getGamepadAxis(gamepad, GamepadAxisRightX).float32 / 32767.0f
      pad.axes[rightY] = -(getGamepadAxis(gamepad, GamepadAxisRightY).float32 / 32767.0f)
      
      #triggers are scaled from [0, 32767] to [-1.0f, 1.0f] to match GLFW boundaries
      pad.axes[globals.GamepadAxis.leftTrigger] = (getGamepadAxis(gamepad, GamepadAxisLeftTrigger).float32 / 32767.0f) * 2.0f - 1.0f
      pad.axes[globals.GamepadAxis.rightTrigger] = (getGamepadAxis(gamepad, GamepadAxisRightTrigger).float32 / 32767.0f) * 2.0f - 1.0f
      
      var buttons: array[globals.GamepadButton, bool]

      buttons[a] = getGamepadButton(gamepad, GamepadButtonSouth)
      buttons[b] = getGamepadButton(gamepad, GamepadButtonEast)
      buttons[x] = getGamepadButton(gamepad, GamepadButtonWest)
      buttons[y] = getGamepadButton(gamepad, GamepadButtonNorth)

      buttons[leftBumper] = getGamepadButton(gamepad, GamepadButtonLeftShoulder)
      buttons[rightBumper] = getGamepadButton(gamepad, GamepadButtonRightShoulder)
      buttons[back] = getGamepadButton(gamepad, GamepadButtonBack)
      buttons[start] = getGamepadButton(gamepad, GamepadButtonStart)
      buttons[guide] = getGamepadButton(gamepad, GamepadButtonGuide)
      buttons[leftThumb] = getGamepadButton(gamepad, GamepadButtonLeftStick)
      buttons[rightThumb] = getGamepadButton(gamepad, GamepadButtonRightStick)
      
      buttons[dpadUp] = getGamepadButton(gamepad, GamepadButtonDpadUp)
      buttons[dpadRight] = getGamepadButton(gamepad, GamepadButtonDpadRight)
      buttons[dpadDown] = getGamepadButton(gamepad, GamepadButtonDpadDown)
      buttons[dpadLeft] = getGamepadButton(gamepad, GamepadButtonDpadLeft)
      
      buttons[globals.GamepadButton.leftTrigger] = pad.axes[globals.GamepadAxis.leftTrigger] > -1f + gamepadDeadzone
      buttons[globals.GamepadButton.rightTrigger] = pad.axes[globals.GamepadAxis.rightTrigger] > -1f + gamepadDeadzone
    
      for but in globals.GamepadButton:
        pad.buttonsJustDown[but] = buttons[but] and not pad.buttons[but]
        pad.buttonsJustUp[but] = not buttons[but] and pad.buttons[but]

        if pad.buttonsJustDown[but]: fireFauEvent FauEvent(kind: feGamepadButton, buttonGamepad: pad, buttonDown: true, button: but)
        if pad.buttonsJustUp[but]: fireFauEvent FauEvent(kind: feGamepadButton, buttonGamepad: pad, buttonDown: false, button: but)
      
      pad.buttons = buttons

      #TODO: better rumble system
      if pad.rumbleDuration > 0f:
        pad.rumbleDuration -= fau.rawDelta
        let scl = clamp(pad.rumbleDuration/pad.rumbleDurationMax).powout(2f)
        
        let lowFreq = (pad.rumbleIntensitySlow * scl * 65535.0f).uint16
        let highFreq = (pad.rumbleIntensityFast * scl * 65535.0f).uint16
        discard rumbleGamepad(gamepad, lowFreq, highFreq, 100)
      else:
        if pad.rumbleIntensityFast > 0f or pad.rumbleIntensitySlow > 0f:
          discard rumbleGamepad(gamepad, 0, 0, 0)
        pad.rumbleIntensityFast = 0f
        pad.rumbleIntensitySlow = 0f
        pad.rumbleDuration = 0f
        pad.rumbleDurationMax = 0f

proc initCore*(loopProc: proc(), initProc: proc() = (proc() = discard), params: FauInitParams) =
  when defined(Linux):
    if getEnv("FAU_FORCE_WAYLAND", "0") != "1":
      #Prefer x11, as Wayland seems to be broken on some platforms: https://github.com/Anuken/Mindustry/issues/11657
      #yes, I know the issue is for Mindustry, but it seems specific to SDL3
      if "wayland" == getEnv("XDG_SESSION_TYPE", "").toLowerAscii:
        echo "[Fau] Forcing x11 due to Wayland being broken - see https://github.com/Anuken/Mindustry/issues/11657. Set FAU_FORCE_WAYLAND=1 to disable this behavior."
        checkError setHint(HintVideoDriver, "x11,wayland");
  
  if params.appName != "":
    checkError setAppMetadata(params.appTitle.cstring, nil, params.appName.cstring)

  if not init(InitVideo or InitGamepad): 
    raise newException(Exception, "Failed to Initialize SDL3: " & $getError())

  echo "[Fau] Initialized ", getRevision(), " [", getCurrentVideoDriver(), "]"

  checkError glSetAttribute(GlContextMajorVersion, 2)
  checkError glSetAttribute(GlContextMinorVersion, 0)
  checkError glSetAttribute(GlDoublebuffer, 1)
  
  if params.depth: 
    checkError glSetAttribute(GlDepthSize, 16)

  if (paramCount() > 0 and paramStr(1) == "-coreProfile") or isMac or defined(fauGlCoreProfile):
    checkError glSetAttribute(GlContextMajorVersion, 3)
    checkError glSetAttribute(GlContextMinorVersion, 2)
    checkError glSetAttribute(GlContextProfileMask, GlContextProfileCore.cint)
    checkError glSetAttribute(GlContextFlags, GlContextForwardCompatibleFlag.cint)

  var flags = WindowOpenGL or WindowResizable
  if params.maximize: flags = flags or WindowMaximized
  if params.undecorated: flags = flags or WindowBorderless
  if params.transparent: flags = flags or WindowTransparent

  window = createWindow(params.title.cstring, params.size.x.cint, params.size.y.cint, flags)
  if window == nil:
    raise newException(Exception, "Failed to create SDL3 Window: " & $getError())

  glContext = glCreateContext(window)
  if glContext == nil:
    raise newException(Exception, "Failed to create GL Context: " & $getError())

  checkError glMakeCurrent(window, glContext)
  checkError glSetSwapInterval(1)

  if not loadGl(glGetProcAddress, glExtensionSupported):
    raise Exception.newException("Failed to load OpenGL.")

  echo "[Fau] Initialized OpenGL v", glVersionMajor, ".", glVersionMinor, " [VAO: ", supportsVertexArrays, "]"

  #load window icon
  when assetExistsStatic("icon.png") and not defined(macosx):
    let 
      textureBytes = assetReadStatic("icon.png")
      img = loadRawImageMem(textureBytes)
      surface = createSurfaceFrom(img.width.cint, img.height.cint, pixelFormatRgba32, cast[pointer](img.data), (img.width * 4).cint)
    
    if surface != nil:
      #error isn't important here
      discard window.setWindowIcon(surface)
      destroySurface(surface)
    freeRawImage(img)

  var 
    inMouseX: float32 = 0
    inMouseY: float32 = 0
    inWidth: cint = 0
    inHeight: cint = 0

  discard getMouseState(inMouseX, inMouseY)
  checkError window.getWindowSizeInPixels(inWidth, inHeight)
  
  fau.sizei = vec2i(inWidth.int, inHeight.int)
  fau.size = fau.sizei.vec2
  fau.mouse = fixMouse(inMouseX, inMouseY)

  glInitialized = true
  initProc()

  mainLoop(proc() =
    processEvents()
    updateGamepads()
    loopProc()
    checkError glSwapWindow(window)
  )

  glInitialized = false
  fireFauEvent FauEvent(kind: feDestroy)
  discard glDestroyContext(glContext)
  destroyWindow(window)
  sdl3.quit()

proc setWindowTitle*(title: string) =
  discard window.setWindowTitle(title.cstring)

proc setWindowDecorated*(decorated: bool) =
  discard window.setWindowBordered((not decorated).bool)

proc setWindowFloating*(floating: bool) =
  discard window.setWindowAlwaysOnTop(floating.bool)

proc setClipboardString*(text: string) =
  discard setClipboardText(text.cstring)

proc getClipboardString*(): string =
  $getClipboardText()

proc setCursor*(cursor: Cursor) =
  discard setCursor(cursor.handle)

proc getCursorPos*(): Vec2 =
  var 
    mouseX: float32 = 0
    mouseY: float32 = 0
  discard getMouseState(mouseX,mouseY)
  return fixMouse(mouseX, mouseY)

proc setWindowPos*(pos: Vec2i) =
  ## note: not supported on wayland
  discard window.setWindowPosition(pos.x.cint, pos.y.cint)

proc getWindowPos*(): Vec2i =
  ## note: not supported on wayland
  var w, h: cint
  discard window.getWindowPosition(w, h)
  return vec2i(w.int, h.int)

proc getWindowSize*(): Vec2i =
  var w, h: cint
  discard window.getWindowSize(w, h)
  return vec2i(w.int, h.int)

proc setWindowSize*(size: Vec2i) =
  discard window.setWindowSize(size.x.cint, size.y.cint)

proc setVsync*(on: bool) =
  discard glSetSwapInterval(on.cint)

proc isMaximized*(): bool = 
  return (window.getWindowFlags() and WindowMaximized) != 0

proc isFocused*(): bool = 
  return (window.getWindowFlags() and WindowInputFocus) != 0

proc isFullscreen*(): bool =
  return (window.getWindowFlags() and WindowFullscreen) != 0

proc setFullscreen*(on: bool) =
  if isFullscreen() == on or defined(emscripten):
    return

  if on:
    checkError window.setWindowFullscreen(true)
  else:
    checkError window.setWindowFullscreen(false)

proc toggleFullscreen*() =
  setFullscreen(not isFullscreen())

proc setCursorHidden*(hidden: bool) =
  if hidden: discard hideCursor() else: discard showCursor()

proc quitApp*() = 
  running = false