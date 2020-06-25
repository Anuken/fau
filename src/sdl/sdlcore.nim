import sdl2, tables, streams, times, sdlgl, ../gltypes, ../graphics

type KeyCode* = enum
    keyA, keyB, keyC, keyD, keyE, keyF, keyG, keyH, keyI, keyJ, keyK, keyL, keyM, keyN, keyO, keyP, keyQ, keyR, keyS, keyT, keyU, 
    keyV, keyW, keyX, keyY, keyZ, key1, key2, key3, key4, key5, key6, key7, key8, key9, key0, keyReturn, keyEscape, keyBackspace, 
    keyTab, keySpace, keyMinus, keyEquals, keyLeftbracket, keyRightbracket, keyBackslash, keyNonushash, keySemicolon, keyApostrophe, keyGrave, keyComma, keyPeriod, 
    keySlash, keyCapslock, keyF1, keyF2, keyF3, keyF4, keyF5, keyF6, keyF7, keyF8, keyF9, keyF10, keyF11, keyF12, keyPrintscreen, keyScrolllock, 
    keyPause, keyInsert, keyHome, keyPageup, keyDelete, keyEnd, keyPagedown, keyRight, keyLeft, keyDown, keyUp, keyNumlockclear, keyKpDivide, keyKpMultiply, 
    keyKpMinus, keyKpPlus, keyKpEnter, keyKp1, keyKp2, keyKp3, keyKp4, keyKp5, keyKp6, keyKp7, keyKp8, keyKp9, keyKp0, keyKpPeriod, keyNonusbackslash, 
    keyApplication, keyPower, keyKpEquals, keyF13, keyF14, keyF15, keyF16, keyF17, keyF18, keyF19, keyF20, keyF21, keyF22, keyF23, keyF24, 
    keyExecute, keyHelp, keyMenu, keySelect, keyStop, keyAgain, keyUndo, keyCut, keyCopy, keyPaste, keyFind, keyMute, keyVolumeup, keyVolumedown, 
    keyKpComma, keyAlterase, keySysreq, keyCancel, keyClear, keyPrior, keyReturn2, keySeparator, keyOut, keyOper, keyClearagain, 
    keyCrsel, keyExsel, keyThousandsseparator, keyDecimalseparator, keyCurrencyunit, keyCurrencysubunit, keyLctrl, keyLshift, keyLalt, keyLgui, keyRctrl, 
    keyRshift, keyRalt, keyRgui, keyMode, keyUnknown,
    keyMouseLeft, keyMouseMiddle, keyMouseRight

#SDL error check template
template sdlFailIf(cond: typed, reason: string) =
    if cond: raise Exception.newException(reason & ", SDL error: " & $getError())

#whether the app is running, main loop
var coreRunning: bool = true
var coreWindow: WindowPtr

#graphics stuff
var frameId*: int64
var fps*: int
var deltaTime*: float
var lastFrameTime: int64 = -1
var frameCounterStart: int64
var frames: int
var startTime: Time

var screenW*, screenH*, mouseX*, mouseY*: float32

proc mouse*(): Vec2 = vec2(mouseX, mouseY)
proc screen*(): Vec2 = vec2(screenW, screenH)

#input
var keysPressed: array[KeyCode, bool]
var keysJustDown: array[KeyCode, bool]
var keysJustUp: array[KeyCode, bool]
var lastScrollX, lastScrollY: float

proc toKeyCode(scancode: int): KeyCode = 
    result = case scancode:
        of 4: keyA
        of 5: keyB
        of 6: keyC
        of 7: keyD
        of 8: keyE
        of 9: keyF
        of 10: keyG
        of 11: keyH
        of 12: keyI
        of 13: keyJ
        of 14: keyK
        of 15: keyL
        of 16: keyM
        of 17: keyN
        of 18: keyO
        of 19: keyP
        of 20: keyQ
        of 21: keyR
        of 22: KeyCode.keyS
        of 23: keyT
        of 24: keyU
        of 25: keyV
        of 26: keyW
        of 27: keyX
        of 28: keyY
        of 29: keyZ
        of 30: key1
        of 31: key2
        of 32: key3
        of 33: key4
        of 34: key5
        of 35: key6
        of 36: key7
        of 37: key8
        of 38: key9
        of 39: key0
        of 40: keyReturn
        of 41: keyEscape
        of 42: keyBackspace
        of 43: keyTab
        of 44: keySpace
        of 45: keyMinus
        of 46: keyEquals
        of 47: keyLeftbracket
        of 48: keyRightbracket
        of 49: keyBackslash
        of 50: keyNonushash
        of 51: keySemicolon
        of 52: keyApostrophe
        of 53: keyGrave
        of 54: keyComma
        of 55: keyPeriod
        of 56: keySlash
        of 57: keyCapslock
        of 58: keyF1
        of 59: keyF2
        of 60: keyF3
        of 61: keyF4
        of 62: keyF5
        of 63: keyF6
        of 64: keyF7
        of 65: keyF8
        of 66: keyF9
        of 67: keyF10
        of 68: keyF11
        of 69: keyF12
        of 70: keyPrintscreen
        of 71: keyScrolllock
        of 72: keyPause
        of 73: keyInsert
        of 74: keyHome
        of 75: keyPageup
        of 76: keyDelete
        of 77: keyEnd
        of 78: keyPagedown
        of 79: keyRight
        of 80: keyLeft
        of 81: keyDown
        of 82: keyUp
        of 83: keyNumlockclear
        of 84: keyKpDivide
        of 85: keyKpMultiply
        of 86: keyKpMinus
        of 87: keyKpPlus
        of 88: keyKpEnter
        of 89: keyKp1
        of 90: keyKp2
        of 91: keyKp3
        of 92: keyKp4
        of 93: keyKp5
        of 94: keyKp6
        of 95: keyKp7
        of 96: keyKp8
        of 97: keyKp9
        of 98: keyKp0
        of 99: keyKpPeriod
        of 100: keyNonusbackslash
        of 101: keyApplication
        of 102: keyPower
        of 103: keyKpEquals
        of 104: keyF13
        of 105: keyF14
        of 106: keyF15
        of 107: keyF16
        of 108: keyF17
        of 109: keyF18
        of 110: keyF19
        of 111: keyF20
        of 112: keyF21
        of 113: keyF22
        of 114: keyF23
        of 115: keyF24
        of 116: keyExecute
        of 117: keyHelp
        of 118: keyMenu
        of 119: keySelect
        of 120: keyStop
        of 121: keyAgain
        of 122: keyUndo
        of 123: keyCut
        of 124: keyCopy
        of 125: keyPaste
        of 126: keyFind
        of 127: keyMute
        of 128: keyVolumeup
        of 129: keyVolumedown
        of 133: keyKpComma
        of 153: keyAlterase
        of 154: keySysreq
        of 155: keyCancel
        of 156: keyClear
        of 157: keyPrior
        of 158: keyReturn2
        of 159: keySeparator
        of 160: keyOut
        of 161: keyOper
        of 162: keyClearagain
        of 163: keyCrsel
        of 164: keyExsel
        of 178: keyThousandsseparator
        of 179: keyDecimalseparator
        of 180: keyCurrencyunit
        of 181: keyCurrencysubunit
        of 224: keyLctrl
        of 225: keyLshift
        of 226: keyLalt
        of 227: keyLgui
        of 228: keyRctrl
        of 229: keyRshift
        of 230: keyRalt
        of 231: keyRgui
        of 257: keyMode
        else: keyUnknown

#changes SDL button code into keycode enum
proc mapMouseCode(button: uint8): KeyCode =
    result = case button:
        of BUTTON_LEFT: keyMouseLeft
        of BUTTON_MIDDLE: keyMouseMiddle
        of BUTTON_RIGHT: keyMouseRight
        else: keyMouseLeft

#IO

template staticReadStream*(filename: string): string =
    const file = staticRead(filename)
    newStringStream(file)

template staticReadString*(filename: string): string = 
    const str = staticRead(filename)
    str

#INPUT

proc down*(key: KeyCode): bool {.inline.} = keysPressed[key]
proc tapped*(key: KeyCode): bool {.inline.} = keysJustDown[key]
proc released*(key: KeyCode): bool {.inline.} = keysJustUp[key]

proc preUpdate() =
    let time = (getTime() - startTime).inNanoseconds
    if lastFrameTime == -1:
        lastFrameTime = time
    deltaTime = float(time - lastFrameTime) / 1000000000.0 * 60.0
    lastFrameTime = time

    if time - frameCounterStart >= 1000000000:
        fps = frames
        frames = 0
        frameCounterStart = time
    
    inc frames

    var w, h: cint
    coreWindow.getSize(w, h)
    (screenW, screenH) = (w.float32, h.float32)

    var mx, my: cint
    getMouseState(mx, my)
    (mouseX, mouseY) = (mouseX.float32, screenH - 1 - mouseY.float32)

    #poll input
    var event = defaultEvent
    while pollEvent(event):
        case event.kind
        of QuitEvent:
            coreRunning = false
        of KeyDown:
            let code = toKeyCode(event.key.keysym.scancode.int)
            keysPressed[code] = true
            keysJustDown[code] = true
        of KeyUp:
            let code = toKeyCode(event.key.keysym.scancode.int)
            keysPressed[code] = false
            keysJustUp[code] = true
        of MouseButtonDown:
            let code = mapMouseCode(event.button.button)
            keysPressed[code] = true
            keysJustDown[code] = true
        of MouseButtonUp:
            let code = mapMouseCode(event.button.button)
            keysPressed[code] = false
            keysJustUp[code] = true
        of MouseWheel:
            lastScrollX = if event.wheel.x < 0: -1 else: 1
            lastScrollY = if event.wheel.y < 0: -1 else: 1
        of WindowEvent:
            case event.window.event
            of WindowEvent_Resized:
                let width = event.window.data1.cint
                let height = event.window.data2.cint
                glViewport(0.GLint, 0.GLint, width.GLsizei, height.GLsizei)
            else:
                discard
        else:
            discard

proc postUpdate() =
    sdl2.glSwapWindow(coreWindow) 
    #clean up input
    for x in keysJustDown.mitems: x = false
    for x in keysJustUp.mitems: x = false
    lastScrollX = 0
    lastScrollY = 0

    inc frameId

#external functions for use by outside classes

proc initCore*(loopProc: proc(), initProc: proc() = (proc() = discard), windowWidth = 800, windowHeight = 600, windowTitle = "Unknown", depthBits = 0, stencilBits = 0) =

    sdlFailIf(not sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)): "SDL2 initialization failed"
    defer: sdl2.quit()

    var version: SDL_Version
    getVersion(version)
    echo "Initialized SDL v" & $version.major & "." & $version.minor & "." & $version.patch

    #set up openGL requirements
    proc setAttr(attribute: GLattr, value: cint) =
        sdlFailIf sdl2.glSetAttribute(attribute, value) != 0: "Attribute failed to set"

    #initialize RGBA8888 GL2.0
    setAttr(SDL_GL_CONTEXT_MAJOR_VERSION, 2)
    setAttr(SDL_GL_CONTEXT_MINOR_VERSION, 0)
    setAttr(SDL_GL_RED_SIZE, 8)
    setAttr(SDL_GL_GREEN_SIZE, 8)
    setAttr(SDL_GL_BLUE_SIZE, 8)
    setAttr(SDL_GL_ALPHA_SIZE, 8)
    setAttr(SDL_GL_DEPTH_SIZE, depthBits.cint)
    setAttr(SDL_GL_STENCIL_SIZE, stencilBits.cint)
    setAttr(SDL_GL_DOUBLEBUFFER, 1)
    
    coreWindow = createWindow(title = windowTitle, x = SDL_WINDOWPOS_CENTERED, y = SDL_WINDOWPOS_CENTERED, w = windowWidth.cint, h = windowHeight.cint, 
        flags = SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE or SDL_WINDOW_MAXIMIZED or SDL_WINDOW_OPENGL)
    sdlFailIf coreWindow.isNil: "Window could not be created"
    defer: coreWindow.destroy()

    #sdlFailIf(image.init(IMG_INIT_PNG) != IMG_INIT_PNG): "SDL2 Image initialization failed"
    #defer: image.quit()

    let gl = sdl2.glCreateContext(coreWindow)
    sdlFailIf gl.isNil: "GL context could not be created"
    
    if not loadGl(sdl2.glGetProcAddress):
        raise Exception.newException("Failed to load OpenGL.")

    echo "Initialized OpenGL v" & $glVersionMajor & "." & $glVersionMinor

    startTime = getTime()

    var w, h: cint
    coreWindow.getSize(w, h)
    (screenW, screenH) = (w.float32, h.float32)

    glViewport(0.GLint, 0.GLint, screenW.GLsizei, screenH.GLsizei)

    initProc()

    while coreRunning:
        preUpdate()
        loopProc()
        postUpdate()

#set window title
proc `windowTitle=`*(title: string) =
    coreWindow.setTitle(title)

#stops the game, does not quit immediately
proc quitApp*() = coreRunning = false
