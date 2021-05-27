import gltypes, tables, fmath

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
    dragX*, dragY*: float32
  of feTouch:
    touchId*: int
    touchX*, touchY*: float32
    touchDown*: bool
  of feScroll:
    scrollX*, scrollY*: float32
  of feResize:
    w*, h*: int

type FauListener* = proc(e: FauEvent)


#basic camera
type Cam* = ref object
  pos*: Vec2
  w*, h*: float32
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

#A single mesh vertex attribute.
type VertexAttribute* = object
  componentType: Glenum
  components: GLint
  normalized: bool
  offset: int
  alias: string

#Generic mesh, optionally indexed.
type MeshObj = object
  vertices*: seq[GLfloat]
  indices*: seq[Glushort]
  vertexBuffer: GLuint
  indexBuffer: GLuint
  attributes: seq[VertexAttribute]
  isStatic: bool
  modifiedVert: bool
  modifiedInd: bool
  vertSlice: Slice[int]
  indSlice: Slice[int]
  primitiveType*: GLenum
  vertexSize: Glsizei
type Mesh* = ref MeshObj

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
      verts: array[24, Glfloat]
      tex: Texture
    of reqRect:
      patch: Patch
      x, y, originX, originY, width, height, rotation: float32
      color, mixColor: Color
    of reqProc:
      draw: proc()

type Batch* = ref object
  mesh: Mesh
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
  quad*: Mesh
  #Screenspace shader
  screenspace*: Shader
  #Currently bound framebuffers
  bufferStack*: seq[Framebuffer]
  #Global texture atlas.
  atlas*: Atlas
  #Game window size
  width*, height*: int
  #Game window size in floats
  widthf*, heightf*: float32
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

  #Mouse position
  mouseX*, mouseY*: float32
  #Last scroll values
  scrollX*, scrollY*: float32
  #All last known touch pointer states
  touches*: array[10, Touch]