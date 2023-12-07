import fmath, framebuffer, shader, batch, color, patch, texture, mesh, atlas

const 
  isMobile* = defined(ios) or defined(Android)
  isAndroid* = defined(Android)
  isIos* = defined(ios)
  isDesktop* = not isMobile

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
  keyCrsel, keyExsel, keyDecimalseparator, keyLctrl, keyLshift, keyLalt, keyLgui, keyRctrl,
  keyRshift, keyRalt, keyRgui, keyMode, keyUnknown,
  keyMouseLeft, keyMouseMiddle, keyMouseRight

type GamepadAxis* = enum
  leftX, leftY, rightX, rightY, leftTrigger, rightTrigger

type GamepadAxis2* = enum
  left, right

type GamepadButton* = enum
  a, b, x, y, leftBumper, rightBumper, back, start, guide, 
  leftThumb, rightThumb, dpadUp, dpadRight, dpadDown, dpadLeft

#A game controller.
type Gamepad* = ref object
  name*: string
  index*: int
  buttons*, buttonsJustDown*, buttonsJustUp*: array[GamepadButton, bool]
  axes*: array[GamepadAxis, float]

#discriminator for the various types of input events
type FauEventKind* = enum
  ## any key down/up, including mouse
  feKey,
  ## mouse/pointer moved across screen
  feDrag,
  ## finger up/down at location
  feTouch,
  ## mousewheel scroll up/down
  feScroll,
  ## window resized
  feResize,
  ## visibility changed (show/hide)
  feVisible,
  # controller connected / disconnected
  feGamepadChanged

#a generic input event
type FauEvent* = object
  case kind*: FauEventKind
  of feKey:
    key*: KeyCode
    keyDown*: bool
  of feDrag:
    dragId*: int
    dragPos*: Vec2
  of feTouch:
    touchId*: int
    touchPos*: Vec2
    touchDown*: bool
    touchButton*: KeyCode
  of feScroll:
    scroll*: Vec2
  of feResize:
    size*: Vec2i
  of feVisible:
    shown*: bool
  of feGamepadChanged:
    connected*: bool
    gamepad*: Gamepad

type FauListener* = proc(e: FauEvent)

#A touch position.
type Touch* = object
  pos*, delta*, last*: Vec2
  down*: bool

#Paramters for initialization of Fau across many backends.
type FauInitParams* = object
  #size of window
  size*: Vec2i
  #title of window
  title*: string
  #whether to maximize window at start
  maximize*: bool
  #whether to use a depth buffer
  depth*: bool
  #whether the window has no border
  undecorated*: bool
  #whether the window has a transparent framebuffer
  transparent*: bool
  #default background clear color
  clearColor*: Color

proc initParams*(size = vec2i(800, 600), title = "frog", maximize = true, depth = false, undecorated = false, transparent = false, clearColor = colorClear): FauInitParams =
  FauInitParams(size: size, title: title, maximize: maximize, depth: depth, undecorated: undecorated, transparent: transparent, clearColor: clearColor)

#Hold all the graphics state.
type FauState* = object
  #Screen clear color
  clearColor*: Color
  #The batch that does all the drawing
  batch*: Batch
  #Scaling of each pixel when drawn with a batch
  pixelScl*: float32
  #A white 1x1 patch
  white*: Patch
  #A white circle patch
  circle*: Patch
  #The global camera.
  cam*: Cam
  #Fullscreen quad mesh.
  quad*: SMesh
  #Screenspace shader
  screenspace*: Shader
  #Global texture atlas.
  atlas*: Atlas
  #Frame number
  frameId*: int64
  #Smoothed frames per second
  fps*: int
  #Delta time between frames in 60th of a second
  delta*: float32
  #Raw time between frames with no clamping applied.
  rawDelta*: float
  #Target FPS; 0 to ignore.
  targetFps*: float32
  #Maximum value that the delta can be - prevents erratic behavior at low FPS values. Default: 1/60
  maxDelta*: float32
  #Time passed since game launch, in seconds
  time*: float32
  #All input listeners
  listeners*: seq[FauListener]
  #All currently plugged-in gamepads.
  gamepads*: seq[Gamepad]

  #Game window size
  sizei*: Vec2i
  #Game window size in floats
  size*: Vec2
  #Screen density, for mobile devices
  screenDensity*: float32
  #Safe insets for mobile devices. Order: top, right, bot, left
  insets*: array[4, float32]
  #Whether the game window is in the forground
  shown*: bool

  #Mouse position
  mouse*: Vec2
  #Last scroll values
  scroll*: Vec2
  #All last known touch pointer states
  touches*: array[10, Touch]

#Global instance of fau state.
var fau* = FauState()

proc fireFauEvent*(ev: FauEvent) =
  for l in fau.listeners: l(ev)

proc addFauListener*(ev: FauListener) =
  fau.listeners.add ev

#TODO not sure where else to put this?

#Turns pixel units into world units
proc px*(val: float32): float32 {.inline.} = val * fau.pixelScl

proc unproject*(matInv: Mat, vec: Vec2, viewRect = rect(vec2(), fau.size)): Vec2 = (((vec - viewRect.xy) * 2f) / max(viewRect.size, vec2(1f)) - 1f) * matInv
proc project*(mat: Mat, vec: Vec2, viewRect = rect(vec2(), fau.size)): Vec2 = viewRect.size * (vec * mat + 1f) / 2f + viewRect.xy

proc unproject*(cam: Cam, vec: Vec2, viewRect = rect(vec2(), fau.size)): Vec2 {.inline.} = unproject(cam.inv, vec, viewRect)
proc project*(cam: Cam, vec: Vec2, viewRect = rect(vec2(), fau.size)): Vec2 {.inline.} = project(cam.mat, vec, viewRect)

proc mouseWorld*(fau: FauState): Vec2 {.inline.} = fau.cam.unproject(fau.mouse, fau.cam.screenBounds)
proc mouseDelta*(fau: FauState): Vec2 {.inline.} = fau.touches[0].delta

proc bounds*(fau: FauState): Rect {.inline.} = rect(0f, 0f, fau.size)