import gltypes, tables, fmath

## any type that has a time and lifetime
type Timeable* = concept t
  t.time is float32
  t.lifetime is float32

type AnyVec2* = concept t
  t.x is float32
  t.y is float32

## any type that can fade in linearly
type Scaleable* = concept s
  s.fin() is float32

type Vec2i* = object
  x*, y*: int

type Vec2* = object
  x*, y*: float32

#TODO xywh can be vec2s, maybe?
type Rect* = object
  x*, y*, w*, h*: float32

#3x3 matrix for 2D transformations
type Mat* = array[9, float32]

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
  feResize

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

type FauListener* = proc(e: FauEvent)

#basic camera
type Cam* = ref object
  #world position
  pos*: Vec2
  #viewport size
  size*: Vec2
  #projection and inverse projection matrix
  mat*, inv*: Mat

#defines a RGBA color
type Color* = object
  rv*, gv*, bv*, av*: uint8

#types of blending
type Blending* = object
  src*: GLenum
  dst*: Glenum

#an openGL image
type TextureObj = object
  handle: Gluint
  uwrap, vwrap: Glenum
  minfilter, magfilter: Glenum
  target: Glenum
  width*, height*: int
type Texture* = ref TextureObj

#region of a texture
type Patch* = object
  texture*: Texture
  u*, v*, u2*, v2*: float32

#a grid of 9 patches of a texture, used for rendering UI elements
type Patch9* = object
  texture*: Texture
  left*, right*, top*, bot*, width*, height*: int
  #the 9 patches, arranged in left to right, then bottom to top order
  patches*: array[9, Patch]

#Internal shader attribute.
type ShaderAttr* = object
  name*: string
  gltype*: GLenum
  size*: GLint
  length*: Glsizei
  location*: GLint

#OpenGL Shader program.
type ShaderObj = object
  handle, vertHandle, fragHandle: GLuint
  compileLog: string
  compiled: bool
  uniforms: Table[string, int]
  attributes: Table[string, ShaderAttr]
type Shader* = ref ShaderObj

#Vertex index.
type Index* = GLushort

#Basic 2D vertex.
type Vert2* = object
  pos: Vec2
  uv: Vec2
  color, mixcolor: Color

#Uncolored 2D vertex
type SVert2* = object
  pos: Vec2
  uv: Vec2

#Generic mesh, optionally indexed.
type MeshObj[V] = object
  vertices*: seq[V]
  indices*: seq[Glushort]
  vertexBuffer: GLuint
  indexBuffer: GLuint
  isStatic: bool
  modifiedVert: bool
  modifiedInd: bool
  vertSlice: Slice[int]
  indSlice: Slice[int]
  primitiveType*: GLenum
#Generic mesh
type Mesh*[T] = ref MeshObj[T]
#Basic 2D mesh
type Mesh2* = Mesh[Vert2]
#Uncolored mesh
type SMesh* = Mesh[SVert2]

#OpenGL Framebuffer wrapper.
type FramebufferObj = object
  handle: Gluint
  width: int
  height: int
  texture: Texture
  isDefault: bool
type Framebuffer* = ref FramebufferObj

#A single-texture atlas.
type Atlas* = ref object
  patches*: Table[string, Patch]
  patches9*: Table[string, Patch9]
  texture*: Texture
  error*: Patch
  error9*: Patch9

#TODO use vec2 for xy, origin, size
type
  ReqKind = enum
    reqVert,
    reqRect,
    reqProc
  Req = object
    blend: Blending
    z: float32
    case kind: ReqKind:
    of reqVert:
      verts: array[4, Vert2]
      tex: Texture
    of reqRect:
      patch: Patch
      x, y, originX, originY, width, height, rotation: float32
      color, mixColor: Color
    of reqProc:
      draw: proc()

type Batch* = ref object
  mesh: Mesh2
  shader: Shader
  lastTexture: Texture
  index: int
  size: int
  reqs: seq[Req]
  
#A touch position.
type Touch = object
  pos*, delta*, last*: Vec2
  down*: bool

#Hold all the graphics state.
type FauState = object
  #Screen clear color
  clearColor*: Color
  #The batch that does all the drawing
  batch*: Batch
  #The currently-used batch shader - nil to use standard shader
  batchShader*: Shader
  #The current blending type used by the batch
  batchBlending*: Blending
  #The matrix being used by the batch
  batchMat*: Mat
  #Whether sorting is enabled for the batch - requires sorted batch
  batchSort*: bool
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
  #The main (screen) framebuffer
  buffer*: Framebuffer
  #Currently bound framebuffers
  bufferStack*: seq[Framebuffer]
  #Global texture atlas.
  atlas*: Atlas
  #Frame number
  frameId*: int64
  #Smoothed frames per second
  fps*: int
  #Delta time between frames in 60th of a second
  delta*: float32
  #Maximum value that the delta can be - prevents erratic behavior at low FPS values. Default: 1/60
  maxDelta*: float32
  #Time passed since game launch, in seconds
  time*: float32
  #All input listeners
  listeners: seq[FauListener]

  #Game window size
  sizei*: vec2i
  #Game window size in floats
  size*: vec2
  #Screen density, for mobile devices
  screenDensity*: float32
  #Safe insets for mobile devices. Order: top, right, bot, left
  insets*: array[4, float32]

  #Mouse position
  mouse*: Vec2
  #Last scroll values
  scroll*: Vec2
  #All last known touch pointer states
  touches*: array[10, Touch]