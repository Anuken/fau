#I would like to avoid the jnim dependency, but it's necessary for string conversion.
import ../gl/[glad, gltypes, glproc], ../globals, ../fmath, jnim

#avert your eyes, this is an abomination

proc NimMain() {.importc.}

proc toKeyCode(id: int): KeyCode =
  case id
  of 38: keyA
  of 43: keyB
  of 46: keyC
  of 51: keyD
  of 65: keyE
  of 71: keyF
  of 73: keyG
  of 75: keyH
  of 78: keyI
  of 79: keyJ
  of 80: keyK
  of 81: keyL
  of 83: keyM
  of 93: keyN
  of 96: keyO
  of 97: keyP
  of 102: keyQ
  of 103: keyR
  of 105: keyS
  of 116: keyT
  of 118: keyU
  of 120: keyV
  of 123: keyW
  of 124: keyX
  of 125: keyY
  of 126: keyZ
  of 136: keyEscape
  of 53: keyBackspace
  of 117: keyTab
  of 113: keySpace
  of 91: keyMinus
  of 69: keyEquals
  of 82: keyLeftbracket
  of 104: keyRightbracket
  of 45: keyBackslash
  of 107: keySemicolon
  of 41: keyApostrophe
  of 50: keyComma
  of 98: keyPeriod
  of 110: keySlash
  of 185: keyCapslock
  of 170: keyF1
  of 171: keyF2
  of 172: keyF3
  of 173: keyF4
  of 174: keyF5
  of 175: keyF6
  of 176: keyF7
  of 177: keyF8
  of 178: keyF9
  of 179: keyF10
  of 180: keyF11
  of 181: keyF12
  of 187: keyPrintscreen
  of 188: keyScrolllock
  of 186: keyPause
  of 138: keyInsert
  of 77: keyHome
  of 139: keyPageup
  of 137: keyEnd
  of 140: keyPagedown
  of 63: keyRight
  of 62: keyLeft
  of 61: keyDown
  of 64: keyUp
  of 183: keyApplication
  of 101: keyPower
  of 90: keyMenu
  of 92: keyMute
  of 122: keyVolumeup
  of 121: keyVolumedown
  of 49: keyClear
  of 119: keyUnknown
  of 21: keyMouseLeft
  of 23: keyMouseMiddle
  of 22: keyMouseRight
  else: keyUnknown

var
  running: bool = true
  cloopProc: proc()
  cinitProc: proc()

type jint = int32

#most parameters are ignored here, unnecessary
proc initCore*(loopProc: proc(), initProc: proc() = (proc() = discard), windowWidth = 800, windowHeight = 600, windowTitle = "Unknown", maximize = true, depth = false) =
  cloopProc = loopProc
  cinitProc = initProc

when defined(Android):
  #this is only necessary for glfmGetProcAddress!
  import glfm
else:
  when defined(windows):
    const sdlLibName* = "SDL2.dll"
  elif defined(macosx):
    const sdlLibName* = "libSDL2.dylib"
  elif defined(openbsd):
    const sdlLibName* = "libSDL2.so.0.6"
  else:
    const sdlLibName* = "libSDL2.so"

  #assume SDL backend is used, import that
  proc glGetProcAddress*(procedure: cstring): pointer {.cdecl, dynlib: sdlLibName, importc: "SDL_GL_GetProcAddress".}

proc Java_mindustry_debug_NimBridge_init*(vm: JNIEnvPtr, obj: pointer, assetPath: jstring, screenW, screenH: jint): jint {.cdecl, exportc, dynlib.} =
  #invoked from java so NimMain is necessary
  NimMain()

  echo "the nightmare begins"

  let str = $assetPath
  echo "asset path: ", str

  glInitialized = true
  when defined(Android):
    if not loadGl(glfmGetProcAddress): return 1
  else:
    if not loadGl(glGetProcAddress): return 1

  fau.sizei = vec2i(screenW.int, screenH.int)

  cinitProc()

  return 0

type JavaEvent = enum
  jeLoop,
  jeResize,
  jeKeyDown,
  jeKeyUp,
  jeKeyType, #TODO
  jeTouchDown,
  jeTouchUp,
  jeTouchDrag,
  jeMouseMove,
  jeScroll,
  jeVisible

proc Java_mindustry_debug_NimBridge_inputEvent*(vm, obj: pointer, kind, p1, p2, p3, p4, p5: jint) {.cdecl, exportc, dynlib.} =
  case kind.JavaEvent:
  of jeLoop: cloopProc()
  of jeResize: fireFauEvent(FauEvent(kind: feResize, size: vec2i(p1.int, p2.int)))
  of jeKeyDown: fireFauEvent FauEvent(kind: feKey, key: p1.int.toKeyCode, keyDown: true)
  of jeKeyUp: fireFauEvent FauEvent(kind: feKey, key: p1.int.toKeyCode, keyDown: false)
  of jeTouchDown, jeTouchUp: fireFauEvent FauEvent(kind: feTouch, touchPos: vec2(p1.float32, p2.float32), touchId: p3.int, touchDown: kind.JavaEvent == jeTouchDown, touchButton: keyMouseLeft)
  of jeTouchDrag: fireFauEvent FauEvent(kind: feDrag, dragPos: vec2(p1.float32, p2.float32), dragId: p3.int)
  of jeMouseMove: fireFauEvent FauEvent(kind: feDrag, dragPos: vec2(p1.float32, p2.float32))
  of jeScroll: fireFauEvent FauEvent(kind: feScroll, scroll: vec2(cast[float32](p1), cast[float32](p2)))
  of jeVisible: fireFauEvent FauEvent(kind: feVisible, shown: p1.bool)
  else: discard #TODO key typing

#no quitting for you
#I tried making it just call quit() but that segfaults, which still technically solves the problem
proc quitApp*() = 
  echo "an attempt was made to exit. but you're not going anywhere."