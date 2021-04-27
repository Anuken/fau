import gl, strutils, gltypes, tables, fmath, streams, macros, math, algorithm, sugar, futils
import stb_image/read as stbi

export gltypes, fmath, futils

#KEYS

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

#IO

const rootDir = if getProjectPath().endsWith("src"): getProjectPath()[0..^5] else: getProjectPath()

template staticReadString*(filename: string): string = 
  const realDir = rootDir & "/assets/" & filename
  const str = staticRead(realDir)
  str

template staticReadStream*(filename: string): StringStream =
  newStringStream(staticReadString(filename))

#RENDERING

#basic camera
type Cam* = ref object
  pos*: Vec2
  w*, h*: float32
  mat*, inv*: Mat

proc update*(cam: Cam) = 
  cam.mat = ortho(cam.pos.x - cam.w/2, cam.pos.y - cam.h/2, cam.w, cam.h)
  cam.inv = cam.mat.inv()

proc newCam*(w: float32 = 1, h: float32 = 1): Cam = 
  result = Cam(pos: vec2(0.0, 0.0), w: w, h: h)
  result.update()

proc resize*(cam: Cam, w, h: float32) = 
  cam.w = w
  cam.h = h
  cam.update()

#defines a RGBA color
type Color* = object
  rv*, gv*, bv*, av*: uint8

static: assert sizeof(Color) == 4, "Size of Color must be 4 bytes, but is: " & $sizeof(Color)

#float accessors for colors
func r*(col: Color): float32 {.inline.} = col.rv.float32 / 255f
func g*(col: Color): float32 {.inline.} = col.gv.float32 / 255f
func b*(col: Color): float32 {.inline.} = col.bv.float32 / 255f
func a*(col: Color): float32 {.inline.} = col.av.float32 / 255f

#float setters for colors
func `r=`*(col: var Color, val: float32) {.inline.} = col.rv = clamp(val * 255f, 0, 255f).uint8
func `g=`*(col: var Color, val: float32) {.inline.} = col.gv = clamp(val * 255f, 0, 255f).uint8
func `b=`*(col: var Color, val: float32) {.inline.} = col.bv = clamp(val * 255f, 0, 255f).uint8
func `a=`*(col: var Color, val: float32) {.inline.} = col.av = clamp(val * 255f, 0, 255f).uint8

func rgba*(r: float32, g: float32, b: float32, a: float32 = 1.0): Color {.inline.} = Color(rv: (clamp(r.float32) * 255f).uint8, gv: (clamp(g) * 255f).uint8, bv: (clamp(b) * 255f).uint8, av: (clamp(a) * 255f).uint8)

func rgb*(r: float32, g: float32, b: float32): Color {.inline.} = rgba(r, g, b, 1f)

func rgb*(rgba: float32): Color {.inline.} = rgb(rgba, rgba, rgba)

func alpha*(a: float32): Color {.inline.} = rgba(1.0, 1.0, 1.0, a)

func `*`*(a, b: Color): Color {.inline.} = rgba(a.r * b.r, a.g * b.g, a.b * b.b, a.a * b.a)
func `*`*(a: Color, b: float32): Color {.inline.} = rgba(a.r * b, a.g * b, a.b * b, a.a)

proc mix*(color: Color, other: Color, alpha: float32): Color =
  let inv = 1.0 - alpha
  return rgba(color.r*inv + other.r*alpha, color.g*inv + other.g*alpha, color.b*inv + other.b*alpha, color.a*inv + other.a*alpha)

#convert a color to a ABGR float representation; result may be NaN
proc f*(color: Color): float32 {.inline.} = cast[float32](color)
proc col*(fv: float32): Color {.inline.} = cast[Color](fv)

let
  colorClear* = rgba(0, 0, 0, 0)
  colorWhite* = rgb(1, 1, 1)
  colorBlack* = rgba(0, 0, 0)
  colorWhiteF* = colorWhite.f
  colorClearF* = colorClear.f

#converts a hex string to a color at compile-time; no overhead
export parseHexInt
template `%`*(str: static[string]): Color =
  const ret = Color(r: str[0..1].parseHexInt().float32 / 255.0, g: str[2..3].parseHexInt().float32 / 255.0, b: str[4..5].parseHexInt().float32 / 255.0, a: if str.len > 6: str[6..7].parseHexInt().float32 / 255.0 else: 1.0)
  ret

#types of draw alignment
const
  daLeft* = 1
  daRight* = 2
  daTop* = 4
  daBot* = 8
  daTopLeft* = daTop or daLeft
  daTopRight* = daTop or daRight
  daBotLeft* = daBot or daLeft
  daBotRight* = daBot or daRight
  daCenter* = daLeft or daRight or daTop or daBot

#types of blending
type Blending* = object
  src*: GLenum
  dst*: Glenum

const 
  blendNormal* = Blending(src: GlSrcAlpha, dst: GlOneMinusSrcAlpha)
  blendAdditive* = Blending(src: GlSrcAlpha, dst: GlOne)
  blendDisabled* = Blending(src: GlZero, dst: GlZero)

#activate a blending function
proc use*(blend: Blending) = 
  if blend == blendDisabled:
    glDisable(GLBlend)
  else:
    glEnable(GlBlend)
    glBlendFunc(blend.src, blend.dst)

#UTILITIES

proc clearScreen*(col: Color) =
  glClearColor(col.r, col.g, col.b, col.a)
  glClear(GlColorBufferBit)

#TEXTURE

#an openGL image
type TextureObj = object
  handle: Gluint
  uwrap, vwrap: Glenum
  minfilter, magfilter: Glenum
  target: Glenum
  width*, height*: int
type Texture* = ref TextureObj

proc `=destroy`*(texture: var TextureObj) =
  if texture.handle != 0 and glInitialized:
    glDeleteTexture(texture.handle)
    texture.handle = 0

#binds the texture
proc use*(texture: Texture, unit: int = 0) =
  glActiveTexture((GlTexture0.int + unit).GLenum)
  glBindTexture(texture.target, texture.handle)

#assigns min and mag filters
proc `filter=`*(texture: Texture, filter: Glenum) =
  if texture.minfilter != filter or texture.magfilter != filter:
    texture.minfilter = filter
    texture.magfilter = filter
    texture.use()
    glTexParameteri(texture.target, GlTextureMinFilter, texture.minfilter.GLint)
    glTexParameteri(texture.target, GlTextureMagFilter, texture.magfilter.GLint)

proc filterLinear*(texture: Texture) = texture.filter = GlLinear
proc filterNearest*(texture: Texture) = texture.filter = GlNearest

#assigns wrap modes for each axis
proc `wrap=`*(texture: Texture, wrap: Glenum) =
  texture.uwrap = wrap
  texture.vwrap = wrap
  texture.use()
  glTexParameteri(texture.target, GlTextureWrapS, texture.uwrap.GLint)
  glTexParameteri(texture.target, GlTextureWrapT, texture.vwrap.GLint)

proc `filterMin=`*(texture: Texture, filter: Glenum) =
  texture.minfilter = filter
  texture.use()
  glTexParameteri(texture.target, GlTextureMinFilter, texture.minfilter.GLint)

proc `filterMag=`*(texture: Texture, filter: Glenum) =
  texture.magfilter = filter
  texture.use()
  glTexParameteri(texture.target, GlTextureMagFilter, texture.magfilter.GLint)

proc `wrapU=`*(texture: Texture, wrap: Glenum) =
  texture.uwrap = wrap
  texture.use()
  glTexParameteri(texture.target, GlTextureWrapS, texture.uwrap.GLint)

proc `wrapV=`*(texture: Texture, wrap: Glenum) =
  texture.vwrap = wrap
  texture.use()
  glTexParameteri(texture.target, GlTextureWrapT, texture.vwrap.GLint)

proc wrapRepeat*(texture: Texture) =
  texture.wrap = GlRepeat

#completely reloads texture data
proc load*(texture: Texture, width: int, height: int, pixels: pointer) =
  #bind texture
  texture.use()
  glPixelStorei(GlUnpackAlignment, 1)
  glTexImage2D(texture.target, 0, GlRGBA.Glint, width.GLsizei, height.GLsizei, 0, GlRGBA, GlUnsignedByte, pixels)
  texture.width = width
  texture.height = height

#updates a portion of a texture with some pixels.
proc update*(texture: Texture, x, y, width, height: int, pixels: pointer) =
  #bind texture
  texture.use()
  glTexSubImage2D(texture.target, 0, x.GLint, y.GLint, width.GLsizei, height.GLsizei, GlRGBA, GlUnsignedByte, pixels)

#creates a base texture with no data uploaded
proc newTexture*(width, height: int = 1): Texture = 
  result = Texture(handle: glGenTexture(), uwrap: GlClampToEdge, vwrap: GlClampToEdge, minfilter: GlNearest, magfilter: GlNearest, target: GlTexture2D, width: width, height: height)
  result.use()

  #set parameters
  glTexParameteri(result.target, GlTextureMinFilter, result.minfilter.GLint)
  glTexParameteri(result.target, GlTextureMagFilter, result.magfilter.GLint)
  glTexParameteri(result.target, GlTextureWrapS, result.uwrap.GLint)
  glTexParameteri(result.target, GlTextureWrapT, result.vwrap.GLint)

#load texture from ptr to decoded PNG data
proc loadTexturePtr*(width, height: int, data: pointer): Texture =
  result = newTexture()

  result.width = width
  result.height = height

  result.load(width, height, data)

#load texture from bytes
proc loadTextureBytes*(bytes: string): Texture =
  result = newTexture()

  var
    width, height, channels: int
    data: seq[uint8]

  data = stbi.loadFromMemory(cast[seq[byte]](bytes), width, height, channels, 4)
  result.load(width, height, addr data[0])

  
#load texture from path
proc loadTexture*(path: string): Texture = 
  result = newTexture()

  var
    width, height, channels: int
    data: seq[uint8]

  data = stbi.load(path, width, height, channels, 4)
  result.load(width, height, addr data[0])

proc loadTextureStatic*(path: static[string]): Texture =
  when not defined(emscripten):
    loadTextureBytes(staticReadString(path))
  else: #load from filesystem on emscripten
    loadTexture("assets/" & path)

#region of a texture
type Patch* = object
  texture*: Texture
  u*, v*, u2*, v2*: float32

#creates a patch based on pixel coordinates of a texture
proc newPatch*(texture: Texture, x, y, width, height: int): Patch = 
  Patch(texture: texture, u: x / texture.width, v: y / texture.height, u2: (x + width) / texture.width, v2: (y + height) / texture.height)

#properties that calculate size of a patch in pixels
proc x*(patch: Patch): int = (patch.u * patch.texture.width.float32).int
proc y*(patch: Patch): int = (patch.v * patch.texture.height.float32).int
proc width*(patch: Patch): int = ((patch.u2 - patch.u) * patch.texture.width.float32).int
proc height*(patch: Patch): int = ((patch.v2 - patch.v) * patch.texture.height.float32).int
proc widthf*(patch: Patch): float32 = ((patch.u2 - patch.u) * patch.texture.width.float32)
proc heightf*(patch: Patch): float32 = ((patch.v2 - patch.v) * patch.texture.height.float32)
template exists*(patch: Patch): bool = patch != fau.atlas.error

proc scroll*(patch: var Patch, u, v: float32) =
  patch.u += u
  patch.v += v
  patch.u2 += u
  patch.v2 += v

converter toPatch*(texture: Texture): Patch {.inline.} = Patch(texture: texture, u: 0.0, v: 0.0, u2: 1.0, v2: 1.0)

#SHADER

type ShaderAttr* = object
  name*: string
  gltype*: GLenum
  size*: GLint
  length*: Glsizei
  location*: GLint

type ShaderObj = object
  handle, vertHandle, fragHandle: GLuint
  compileLog: string
  compiled: bool
  uniforms: Table[string, int]
  attributes: Table[string, ShaderAttr]
type Shader* = ref ShaderObj

proc `=destroy`*(shader: var ShaderObj) =
  if shader.handle != 0 and glInitialized:
    glDeleteProgram(shader.handle)
    if shader.vertHandle != 0: glDeleteShader(shader.vertHandle)
    if shader.fragHandle != 0: glDeleteShader(shader.fragHandle)
    
    shader.handle = 0
    shader.vertHandle = 0
    shader.fragHandle = 0

proc loadSource(shader: Shader, shaderType: GLenum, source: string): GLuint =
  result = glCreateShader(shaderType)
  if result == 0: return 0.GLuint

  #attach source
  glShaderSource(result, source)
  glCompileShader(result)

  #check compiled status
  let compiled = glGetShaderiv(result, GlCompileStatus)

  if compiled == 0:
    shader.compiled = false
    shader.compileLog &= ("[" & (if shaderType == GlFragmentShader: "fragment shader" else: "vertex shader") & "]\n")
    let infoLen = glGetShaderiv(result, GlInfoLogLength)
    if infoLen > 1:
      let infoLog = glGetShaderInfoLog(result)
      shader.compileLog &= infoLog #append reason to log
    glDeleteShader(result)

proc use*(shader: Shader) =
  glUseProgram(shader.handle)

proc preprocess(source: string, fragment: bool): string =
  #disallow gles qualifiers
  if source.contains("#ifdef GL_ES"):
    raise newException(GlError, "Shader contains GL_ES specific code; this should be handled by the preprocessor. Code: \n" & source);
  
  #disallow explicit versions
  if source.contains("#version"):
    raise newException(GlError, "Shader contains explicit version requirement; this should be handled by the preprocessor. Code: \n" & source)

  #add GL_ES precision qualifiers
  if fragment: 
    return """

    #ifdef GL_ES
    precision mediump float;
    precision mediump int;
    #else
    #define lowp  
    #define mediump 
    #define highp 
    #endif

    """ & source
  else:
    #strip away precision qualifiers
    return """

    #ifndef GL_ES
    #define lowp  
    #define mediump 
    #define highp 
    #endif

    """ & source

proc newShader*(vertexSource, fragmentSource: string): Shader =
  result = Shader()
  result.uniforms = initTable[string, int]()
  result.compiled = true
  
  result.vertHandle = loadSource(result, GlVertexShader, preprocess(vertexSource, false))
  result.fragHandle = loadSource(result, GlFragmentShader, preprocess(fragmentSource, true))

  if not result.compiled:
    raise newException(GLerror, "Failed to compile shader: \n" & result.compileLog)

  var program = glCreateProgram()
  glAttachShader(program, result.vertHandle)
  glAttachShader(program, result.fragHandle)
  glLinkProgram(program)

  let status = glGetProgramiv(program, GlLinkStatus)

  if status == 0:
    let infoLen = glGetProgramiv(program, GlInfoLogLength)
    if infoLen > 1:
      let infoLog = glGetProgramInfoLog(program)
      result.compileLog &= infoLog #append reason to log
      result.compiled = false
    raise Exception.newException("Failed to link shader: " & result.compileLog) 

  result.handle = program

  #fetch attributes for shader
  let numAttrs = glGetProgramiv(program, GlActiveAttributes)
  for i in 0..<numAttrs:
    var alen: GLsizei
    var asize: GLint
    var atype: GLenum
    var aname: string
    glGetActiveAttrib(program, i.GLuint, alen, asize, atype, aname)
    let aloc = glGetAttribLocation(program, aname)

    result.attributes[aname] = ShaderAttr(name: aname, size: asize, length: alen, gltype: atype, location: aloc)

#attribute functions

proc getAttributeLoc*(shader: Shader, alias: string): int = 
  if not shader.attributes.hasKey(alias): return -1
  return shader.attributes[alias].location

proc enableAttribute*(shader: Shader, location: GLuint, size: GLint, gltype: Glenum, normalize: GLboolean, stride: GLsizei, offset: int) = 
  glEnableVertexAttribArray(location)
  glVertexAttribPointer(location, size, gltype, normalize, stride, cast[pointer](offset));

#uniform setting functions
#note that all of these bind the shader; this is optimized away later

proc findUniform(shader: Shader, name: string): int =
  if shader.uniforms.hasKey(name):
    return shader.uniforms[name]
  let location = glGetUniformLocation(shader.handle, name)
  shader.uniforms[name] = location
  return location

proc seti*(shader: Shader, name: string, value: int) =
  shader.use()
  let loc = shader.findUniform(name)
  if loc != -1: glUniform1i(loc.GLint, value.GLint)

proc setmat4*(shader: Shader, name: string, value: Mat) =
  shader.use()
  let loc = shader.findUniform(name)
  if loc != -1: glUniformMatrix4fv(loc.GLint, 1, false, value.toMat4())

proc setf*(shader: Shader, name: string, value: float) =
  shader.use()
  let loc = shader.findUniform(name)
  if loc != -1: glUniform1f(loc.GLint, value.GLfloat)

proc setf*(shader: Shader, name: string, value1, value2: float) =
  shader.use()
  let loc = shader.findUniform(name)
  if loc != -1: glUniform2f(loc.GLint, value1.GLfloat, value2.GLfloat)

proc setf*(shader: Shader, name: string, value: Vec2) =
  shader.setf(name, value.x, value.y)

proc setf*(shader: Shader, name: string, value1, value2, value3: float) =
  shader.use()
  let loc = shader.findUniform(name)
  if loc != -1: glUniform3f(loc.GLint, value1.GLfloat, value2.GLfloat, value3.GLfloat)

proc setf*(shader: Shader, name: string, value1, value2, value3, value4: float) =
  shader.use()
  let loc = shader.findUniform(name)
  if loc != -1: glUniform4f(loc.GLint, value1.GLfloat, value2.GLfloat, value3.GLfloat, value4.GLfloat)

proc setf*(shader: Shader, name: string, col: Color) = shader.setf(name, col.r, col.g, col.b, col.a)

#MESH

type VertexAttribute* = object
  componentType: Glenum
  components: GLint
  normalized: bool
  offset: int
  alias: string

#returns the size of avertex attribute in bytes
proc size(attr: VertexAttribute): int =
  return case attr.componentType:
    of cGlFloat, cGlFixed: 4 * attr.components
    of GlUnsignedByte, cGlByte: attr.components
    of GlUnsignedShort, cGlShort: 2 * attr.components
    else: 0

#standard attributes
const 
  attribPos* = VertexAttribute(componentType: cGlFloat, components: 2, alias: "a_position")
  attribPos3* = VertexAttribute(componentType: cGlFloat, components: 3, alias: "a_position")
  attribNormal* = VertexAttribute(componentType: cGlFloat, components: 3, alias: "a_normal")
  attribTexCoords* = VertexAttribute(componentType: cGlFloat, components: 2, alias: "a_texc")
  attribColor* = VertexAttribute(componentType: GlUnsignedByte, components: 4, alias: "a_color", normalized: true)
  attribMixColor* = VertexAttribute(componentType: GlUnsignedByte, components: 4, alias: "a_mixcolor", normalized: true)

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

proc `=destroy`*(mesh: var MeshObj) =
  if mesh.vertexBuffer != 0 and glInitialized:
    glDeleteBuffer(mesh.vertexBuffer)
    mesh.vertexBuffer = 0
  if mesh.indexBuffer != 0 and glInitialized:
    glDeleteBuffer(mesh.indexBuffer)
    mesh.indexBuffer = 0

#marks a mesh as modified, so its vertices get reuploaded
proc update*(mesh: Mesh) = 
  mesh.modifiedVert = true
  mesh.modifiedInd = true

#schedules an index buffer update
proc updateIndices*(mesh: Mesh) = mesh.modifiedInd = true

#schedules a vertex buffer update
proc updateVertices*(mesh: Mesh) = mesh.modifiedVert = true

#schedule a vertex buffer update in a slice; grows slice if one is already queued
proc updateVertices*(mesh: Mesh, slice: Slice[int]) =
  mesh.vertSlice.a = min(mesh.vertSlice.a, slice.a)
  mesh.vertSlice.b = max(mesh.vertSlice.b, slice.b)

#schedule an index buffer update in a slice; grows slice if one is already queued
proc updateIndices*(mesh: Mesh, slice: Slice[int]) =
  mesh.indSlice.a = min(mesh.indSlice.a, slice.a)
  mesh.indSlice.b = max(mesh.indSlice.b, slice.b)

#creates a mesh with a set of attributes
proc newMesh*(attrs: seq[VertexAttribute], isStatic: bool = false, primitiveType: Glenum = GlTriangles, vertices: seq[GLfloat] = @[], indices: seq[GLushort] = @[]): Mesh = 
  result = Mesh(
    isStatic: isStatic, 
    attributes: attrs, 
    primitiveType: primitiveType, 
    vertices: vertices, 
    indices: indices,
    modifiedVert: true,
    modifiedInd: true,
    vertexBuffer: glGenBuffer(),
    indexBuffer: glGenBuffer()
  )

  #calculate total vertex size
  for attr in result.attributes.mitems:
    #calculate vertex offset
    attr.offset = result.vertexSize
    result.vertexSize += attr.size().GLsizei

proc beginBind(mesh: Mesh, shader: Shader) =
  #draw usage
  let usage = if mesh.isStatic: GlStaticDraw else: GlStreamDraw

  #bind the vertex buffer
  glBindBuffer(GlArrayBuffer, mesh.vertexBuffer)

  #bind indices if there are any
  if mesh.indices.len > 0:
    glBindBuffer(GlElementArrayBuffer, mesh.indexBuffer)

  #update vertices if modified
  if mesh.modifiedVert:
    glBufferData(GlArrayBuffer, mesh.vertices.len * 4, mesh.vertices[0].addr, usage)
  elif mesh.vertSlice.b != 0:
    glBufferSubData(GlArrayBuffer, mesh.vertSlice.a * 4, mesh.vertSlice.len * 4, mesh.vertices[mesh.vertSlice.a].addr)
  
  #update indices if relevant and modified
  if mesh.modifiedInd and mesh.indices.len > 0:
    glBufferData(GlElementArrayBuffer, mesh.indices.len * 2, mesh.indices[0].addr, usage)
  elif mesh.indSlice.b != 0 and mesh.indices.len > 0:
    glBufferSubData(GlElementArrayBuffer, mesh.indSlice.a * 2, mesh.indSlice.len * 2, mesh.indices[mesh.indSlice.a].addr)
  
  mesh.vertSlice = 0..0
  mesh.indSlice = 0..0
  mesh.modifiedVert = false
  mesh.modifiedInd = false

  for attrib in mesh.attributes:
    let loc = shader.getAttributeLoc(attrib.alias)
    if loc != -1:
      glEnableVertexAttribArray(loc.GLuint)
      glVertexAttribPointer(loc.GLuint, attrib.components, attrib.componentType, attrib.normalized, mesh.vertexSize, 
        cast[pointer](attrib.offset));

proc endBind(mesh: Mesh, shader: Shader) =
  #TODO may not be necessary
  for attrib in mesh.attributes:
    if shader.attributes.hasKey(attrib.alias):
      glDisableVertexAttribArray(shader.attributes[attrib.alias].location.GLuint)

proc render*(mesh: Mesh, shader: Shader, offset = 0, count = mesh.vertices.len) =
  shader.use() #binds the shader if it isn't already bound

  beginBind(mesh, shader)

  if mesh.indices.len == 0:
    glDrawArrays(mesh.primitiveType, (offset.GLint * 4) div mesh.vertexSize, (count.Glint * 4) div mesh.vertexSize)
  else:
    glDrawElements(mesh.primitiveType, count.Glint, GlUnsignedShort, cast[pointer](offset * Glushort.sizeof))
  
  endBind(mesh, shader)

#creates a mesh with position and tex coordinate attributes that covers the screen.
proc newScreenMesh*(): Mesh = newMesh(@[attribPos, attribTexCoords], isStatic = true, primitiveType = GlTriangleFan, vertices = @[-1f, -1, 0, 0, 1, -1, 1, 0, 1, 1, 1, 1, -1, 1, 0, 1])

#FRAMEBUFFER

type FramebufferObj = object
  handle: Gluint
  width: int
  height: int
  texture: Texture
  isDefault: bool
type Framebuffer* = ref FramebufferObj

proc `=destroy`*(buffer: var FramebufferObj) =
  if buffer.handle != 0 and glInitialized:
    glDeleteFramebuffer(buffer.handle)
    buffer.handle = 0

#accessors; read-only
proc width*(buffer: Framebuffer): int {.inline.} = buffer.width
proc height*(buffer: Framebuffer): int {.inline.} = buffer.height
proc texture*(buffer: Framebuffer): Texture {.inline.} = buffer.texture

proc resize*(buffer: Framebuffer, fwidth: int, fheight: int) =
  let 
    width = max(fwidth, 2)
    height = max(fheight, 2)
  
  #don't resize unnecessarily
  if width == buffer.width and height == buffer.height: return
  
  #delete old buffer handle.
  if buffer.handle != 0: 
    glDeleteFramebuffer(buffer.handle)
    buffer.handle = 0
  
  buffer.width = width
  buffer.height = height

  buffer.handle = glGenFramebuffer()
  buffer.texture = Texture(handle: glGenTexture(), target: GlTexture2D, width: width, height: height)

  #get previous buffer handle - this does incur a slight overhead, but resizing happens rarely anyway
  let previous = glGetIntegerv(GlFramebufferBinding)

  glBindFramebuffer(GlFramebuffer, buffer.handle)
  glBindTexture(GlTexture2D, buffer.texture.handle)

  buffer.texture.filter = GlNearest

  glTexImage2D(GlTexture2D, 0, GlRgba.Glint, width.GLsizei, height.GLsizei, 0, GlRgba, GlUnsignedByte, nil)
  glFramebufferTexture2D(GlFramebuffer, GlColorAttachment0, GlTexture2D, buffer.texture.handle, 0)

  let status = glCheckFramebufferStatus(GlFramebuffer)

  #restore old buffer
  glBindFramebuffer(GlFramebuffer, previous.GLuint)

  #check for errors
  if status != GlFramebufferComplete:
    let message = case status:
      of GlFramebufferIncompleteAttachment: "Framebuffer error: incomplete attachment"
      of GlFramebufferIncompleteDimensions: "Framebuffer error: incomplete dimensions"
      of GlFramebufferIncompleteMissingAttachment: "Framebuffer error: missing attachment"
      of GlFramebufferUnsupported: "Framebuffer error: unsupported combination of formats"
      else: "Framebuffer: Error code " & $status
    
    raise GlError.newException(message)

#If not size arguments are provided, this buffer cannot be used until it is resized.
proc newFramebuffer*(width: int = 2, height: int = 2): Framebuffer = 
  result = Framebuffer()
  
  if width != 2 or height != 2: result.resize(width, height)

#Returns a new default framebuffer object.
proc newDefaultFramebuffer*(): Framebuffer = Framebuffer(handle: glGetIntegerv(GlFramebufferBinding).GLuint, isDefault: true)

#ATLAS

type Atlas* = ref object
  patches*: Table[string, Patch]
  texture*: Texture
  error*: Patch

#Loads an atlas from static resources.
proc loadAtlasStatic*(path: static[string]): Atlas =
  result = Atlas()

  const dataPath = path & ".dat"
  const pngPath = path & ".png"
  
  result.texture = loadTextureStatic(pngPath)

  let stream = staticReadStream(dataPath)

  let amount = stream.readInt32()
  for i in 0..<amount:
    let 
      nameLen = stream.readInt16()
      name = stream.readStr(nameLen)
      x = stream.readInt16()
      y = stream.readInt16()
      width = stream.readInt16()
      height = stream.readInt16()
      patch = newPatch(result.texture, x, y, width, height)

    result.patches[name] = patch
  stream.close()
  result.error = result.patches["error"]
# accesses a region from an atlas
proc `[]`*(atlas: Atlas, name: string): Patch {.inline.} = atlas.patches.getOrDefault(name, atlas.error)

const
  vertexSize = 2 + 2 + 1 + 1
  spriteSize = 4 * vertexSize

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

#STATE

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
  #Mouse position
  mouseX*, mouseY*: float32
  #Last scroll values
  scrollX*, scrollY*: float32

#Global instance of fau state.
var fau* = FauState()

#Turns pixel units into world units
proc px*(val: float32): float32 {.inline.} = val * fau.pixelScl

proc unproject*(cam: Cam, vec: Vec2): Vec2 = 
  vec2((2 * vec.x) / fau.widthf - 1, (2 * vec.y) / fau.heightf - 1) * cam.inv

proc project*(cam: Cam, vec: Vec2): Vec2 = 
  let pro = vec * cam.mat
  return vec2(fau.widthf * (1) / 2 + pro.x, fau.heightf * ( 1) / 2 + pro.y)

proc mouse*(): Vec2 = vec2(fau.mouseX, fau.mouseY)
proc mouseWorld*(): Vec2 = fau.cam.unproject(vec2(fau.mouseX, fau.mouseY))
proc screen*(): Vec2 = vec2(fau.width.float32, fau.height.float32)

proc patch*(name: string): Patch {.inline.} = fau.atlas[name]

#Batch methods
proc flush(batch: Batch) =
  if batch.index == 0: return

  batch.lastTexture.use()
  fau.batchBlending.use()

  #use global shader if there is one set
  let shader = if fau.batchShader.isNil: batch.shader else: fau.batchShader

  shader.seti("u_texture", 0)
  shader.setmat4("u_proj", fau.batchMat)

  batch.mesh.updateVertices(0..<batch.index)
  batch.mesh.render(shader, 0, batch.index div spriteSize * 6)
  
  batch.index = 0

proc prepare(batch: Batch, texture: Texture) =
  if batch.lastTexture != texture or batch.index >= batch.size:
    batch.flush()
    batch.lastTexture = texture

proc drawRaw(batch: Batch, texture: Texture, vertices: array[spriteSize, Glfloat], z: float32) =
  if fau.batchSort:
    batch.reqs.add(Req(kind: reqVert, tex: texture, verts: vertices, blend: fau.batchBlending, z: z))
  else:
    batch.prepare(texture)

    let
      verts = addr batch.mesh.vertices
      idx = batch.index

    #copy over the vertices
    for i in 0..<spriteSize:
      verts[i + idx] = vertices[i]

    batch.index += spriteSize

proc drawRaw(batch: Batch, region: Patch, x, y, z, width, height, originX, originY, rotation: float32, color, mixColor: Color) =
  if fau.batchSort:
    batch.reqs.add(Req(kind: reqRect, patch: region, x: x, y: y, z: z, width: width, height: height, originX: originX, originY: originY, rotation: rotation, color: color, mixColor: mixColor, blend: fau.batchBlending))
  else:
    batch.prepare(region.texture)

    if rotation == 0.0f:
      let
        x2 = width + x
        y2 = height + y
        u = region.u
        v = region.v2
        u2 = region.u2
        v2 = region.v
        idx = batch.index
        verts = addr batch.mesh.vertices
        cf = color.f
        mf = mixColor.f

      verts.minsert(idx, [x, y, u, v, cf, mf, x, y2, u, v2, cf, mf, x2, y2, u2, v2, cf, mf, x2, y, u2, v, cf, mf])
    else:
      let
        #bottom left and top right corner points relative to origin
        worldOriginX = x + originX
        worldOriginY = y + originY
        fx = -originX
        fy = -originY
        fx2 = width - originX
        fy2 = height - originY
        #rotate
        cos = cos(rotation)
        sin = sin(rotation)
        x1 = cos * fx - sin * fy + worldOriginX
        y1 = sin * fx + cos * fy + worldOriginY
        x2 = cos * fx - sin * fy2 + worldOriginX
        y2 = sin * fx + cos * fy2 + worldOriginY
        x3 = cos * fx2 - sin * fy2 + worldOriginX
        y3 = sin * fx2 + cos * fy2 + worldOriginY
        x4 = x1 + (x3 - x2)
        y4 = y3 - (y2 - y1)
        u = region.u
        v = region.v2
        u2 = region.u2
        v2 = region.v
        idx = batch.index
        verts = addr batch.mesh.vertices
        cf = color.f
        mf = mixColor.f

      verts.minsert(idx, [x1, y1, u, v, cf, mf, x2, y2, u, v2, cf, mf, x3, y3, u2, v2, cf, mf, x4, y4, u2, v, cf, mf])

    batch.index += spriteSize

const defaultBatchVert* = """
attribute vec4 a_position;
attribute vec4 a_color;
attribute vec2 a_texc;
attribute vec4 a_mixcolor;
uniform mat4 u_proj;
varying vec4 v_color;
varying vec4 v_mixcolor;
varying vec2 v_texc;
void main(){
  v_color = a_color;
  v_color.a = v_color.a * (255.0/254.0);
  v_mixcolor = a_mixcolor;
  v_mixcolor.a = v_mixcolor.a * (255.0/254.0);
  v_texc = a_texc;
  gl_Position = u_proj * a_position;
}
"""

proc newBatch*(size: int = 4092): Batch = 
  let batch = Batch(
    mesh: newMesh(
      @[attribPos, attribTexCoords, attribColor, attribMixColor],
      vertices = newSeq[Glfloat](size * spriteSize),
      indices = newSeq[Glushort](size * 6)
    ),
    size: size * spriteSize
  )

  #set up default indices
  let len = size * 6
  let indices = addr batch.mesh.indices
  var j = 0
  var i = 0
  
  while i < len:
    indices.minsert(i, [j.GLushort, (j+1).GLushort, (j+2).GLushort, (j+2).GLushort, (j+3).GLushort, (j).GLushort])
    i += 6
    j += 4
  
  #create default shader
  batch.shader = newShader(defaultBatchVert,

  """
  varying lowp vec4 v_color;
  varying lowp vec4 v_mixcolor;
  varying vec2 v_texc;
  uniform sampler2D u_texture;
  void main(){
    vec4 c = texture2D(u_texture, v_texc);
    gl_FragColor = v_color * mix(c, vec4(v_mixcolor.rgb, c.a), v_mixcolor.a);
  }
  """)

  result = batch

#Flush the batched items.
proc drawFlush*() =
  if fau.batchSort:
    #sort requests by their Z value
    fau.batch.reqs.sort((a, b) => a.z.cmp b.z)
    #disable it so following reqs are not sorted again
    fau.batchSort = false

    let last = fau.batchBlending
    
    for req in fau.batch.reqs:
      if fau.batchBlending != req.blend:
        fau.batch.flush()
        req.blend.use()
        fau.batchBlending = req.blend
      
      case req.kind:
      of reqVert:
        fau.batch.drawRaw(req.tex, req.verts, 0)
      of reqRect:
        fau.batch.drawRaw(req.patch, req.x, req.y, 0.0, req.width, req.height, req.originX, req.originY, req.rotation, req.color, req.mixColor)
      of reqProc:
        req.draw()
    
    fau.batch.reqs.setLen(0)
    fau.batchSort = true
    fau.batchBlending = last

  #flush the base batch
  fau.batch.flush()

#Set a shader to be used for rendering. This flushes the batch.
proc drawShader*(shader: Shader) = 
  drawFlush()
  fau.batchShader = shader

template withShader*(shader: Shader, body: untyped) =
  shader.drawShader()
  body
  drawShader(nil)

#Sets the matrix used for rendering. This flushes the batch.
proc drawMat*(mat: Mat) = 
  drawFlush()
  fau.batchMat = mat

proc screenMat*() =
  drawMat(ortho(0f, 0f, fau.widthf, fau.heightf))

#Draws something custom at a specific Z layer
proc draw*(z: float32, value: proc()) =
  if fau.batchSort:
    fau.batch.reqs.add(Req(kind: reqProc, draw: value, z: z, blend: fau.batchBlending))
  else:
    value()

#Custom handling of begin/end for a specific Z layer
proc drawLayer*(z: float32, layerBegin, layerEnd: proc(), spread: float32 = 1) =
  draw(z - spread, layerBegin)
  draw(z + spread, layerEnd)

proc draw*(region: Patch, x, y: float32, z = 0f, width = region.widthf * fau.pixelScl, height = region.heightf * fau.pixelScl,
  xscl: float32 = 1.0, yscl: float32 = 1.0,
  originX = width * 0.5 * xscl, originY = height * 0.5 * yscl, rotation = 0f, align = daCenter,
  color = colorWhite, mixColor = colorClear) {.inline.} =

  let 
    alignH = (-((align and daLeft) != 0).int + ((align and daRight) != 0).int + 1) / 2
    alignV = (-((align and daBot) != 0).int + ((align and daTop) != 0).int + 1) / 2

  fau.batch.drawRaw(region, x - width * alignH * xscl, y - height * alignV * yscl, z, width * xscl, height * yscl, originX, originY, rotation, color, mixColor)

#draws a region with rotated bits
proc drawv*(region: Patch, x, y: float32, mutator: proc(x, y: float32, idx: int): Vec2, z = 0f, width = region.widthf * fau.pixelScl, height = region.heightf * fau.pixelScl,
  originX = width * 0.5, originY = height * 0.5, rotation = 0f, align = daCenter,
  color = colorWhite, mixColor = colorClear) =
  
  let
    alignH = (-((align and daLeft) != 0).int + ((align and daRight) != 0).int + 1) / 2
    alignV = (-((align and daBot) != 0).int + ((align and daTop) != 0).int + 1) / 2
    worldOriginX: float32 = x + originX - width * alignH
    worldOriginY: float32 = y + originY - height * alignV
    fx: float32 = -originX
    fy: float32 = -originY
    fx2: float32 = width - originX
    fy2: float32 = height - originY
    cos: float32 = cos(rotation.degToRad)
    sin: float32 = sin(rotation.degToRad)
    x1 = cos * fx - sin * fy + worldOriginX
    y1 = sin * fx + cos * fy + worldOriginY
    x2 = cos * fx - sin * fy2 + worldOriginX
    y2 = sin * fx + cos * fy2 + worldOriginY
    x3 = cos * fx2 - sin * fy2 + worldOriginX
    y3 = sin * fx2 + cos * fy2 + worldOriginY
    x4 = x1 + (x3 - x2)
    y4 = y3 - (y2 - y1)
    u = region.u
    v = region.v2
    u2 = region.u2
    v2 = region.v
    cor1 = mutator(x1, y1, 0)
    cor2 = mutator(x2, y2, 1)
    cor3 = mutator(x3, y3, 2)
    cor4 = mutator(x4, y4, 3)
    cf = color.f
    mf = mixColor.f

  fau.batch.drawRaw(region.texture, [cor1.x, cor1.y, u, v, cf, mf, cor2.x, cor2.y, u, v2, cf, mf, cor3.x, cor3.y, u2, v2, cf, mf, cor4.x, cor4.y, u2, v, cf, mf], z)

#draws a region with rotated bits
proc drawv*(region: Patch, x, y: float32, c1 = vec2(0, 0), c2 = vec2(0, 0), c3 = vec2(0, 0), c4 = vec2(0, 0), z = 0f, width = region.widthf * fau.pixelScl, height = region.heightf * fau.pixelScl,
  originX = width * 0.5, originY = height * 0.5, rotation = 0f, align = daCenter,
  color = colorWhite, mixColor = colorClear) =

  let
    alignH = (-((align and daLeft) != 0).int + ((align and daRight) != 0).int + 1) / 2
    alignV = (-((align and daBot) != 0).int + ((align and daTop) != 0).int + 1) / 2
    worldOriginX: float32 = x + originX - width * alignH
    worldOriginY: float32 = y + originY - height * alignV
    fx: float32 = -originX
    fy: float32 = -originY
    fx2: float32 = width - originX
    fy2: float32 = height - originY
    cos: float32 = cos(rotation.degToRad)
    sin: float32 = sin(rotation.degToRad)
    x1 = cos * fx - sin * fy + worldOriginX
    y1 = sin * fx + cos * fy + worldOriginY
    x2 = cos * fx - sin * fy2 + worldOriginX
    y2 = sin * fx + cos * fy2 + worldOriginY
    x3 = cos * fx2 - sin * fy2 + worldOriginX
    y3 = sin * fx2 + cos * fy2 + worldOriginY
    x4 = x1 + (x3 - x2)
    y4 = y3 - (y2 - y1)
    u = region.u
    v = region.v2
    u2 = region.u2
    v2 = region.v
    cor1 = c1 + vec2(x1, y1)
    cor2 = c2 + vec2(x2, y2)
    cor3 = c3 + vec2(x3, y3)
    cor4 = c4 + vec2(x4, y4)
    cf = color.f
    mf = mixColor.f

  fau.batch.drawRaw(region.texture, [cor1.x, cor1.y, u, v, cf, mf, cor2.x, cor2.y, u, v2, cf, mf, cor3.x, cor3.y, u2, v2, cf, mf, cor4.x, cor4.y, u2, v, cf, mf], z)

#TODO inline
proc drawRect*(region: Patch, x, y, width, height: float32, originX = 0f, originY = 0f,
  rotation = 0f, color = colorWhite, mixColor = colorClear, z: float32 = 0.0) {.inline.} =
  fau.batch.drawRaw(region, x, y, z, width, height, originX, originY, rotation, color, mixColor)

#TODO inline
proc drawVert*(texture: Texture, vertices: array[24, Glfloat], z: float32 = 0) {.inline.} = 
  fau.batch.drawRaw(texture, vertices, z)

#Activates a camera.
proc use*(cam: Cam) =
  cam.update()
  drawMat cam.mat

#Binds the framebuffer. Internal use only.
proc use(buffer: Framebuffer) =
  #assign size if it is default
  if buffer.isDefault: (buffer.width, buffer.height) = (fau.width, fau.height)

  glBindFramebuffer(GlFramebuffer, buffer.handle)
  glViewport(0, 0, buffer.width.Glsizei, buffer.height.Glsizei)

#returns the current framebuffer
proc currentBuffer*(): Framebuffer {.inline.} = fau.bufferStack[^1]

#Begin rendering to the buffer
proc push*(buffer: Framebuffer) = 
  if buffer == currentBuffer(): raise GLerror.newException("Can't begin framebuffer twice")

  drawFlush()

  #add buffer to stack
  fau.bufferStack.add buffer

  buffer.use()

#Begin rendering to the buffer, but clear it as well
proc push*(buffer: Framebuffer, clearColor: Color) =
  buffer.push()
  clearScreen(clearColor)

#End rendering to the buffer
proc pop*(buffer: Framebuffer) =
  #pop current buffer from the stack, make sure it's correct
  if buffer != fau.bufferStack.pop(): raise GLerror.newException("Framebuffer was not begun, can't end")

  #flush anything drawn
  drawFlush()
  #use previous buffer
  currentBuffer().use()

#Returns whether this buffer is currently being used
proc isCurrent*(buffer: Framebuffer): bool = buffer == fau.bufferStack[^1]

#Draw something inside a framebuffer
template inside*(buffer: Framebuffer, body: untyped) =
  buffer.push(rgba(0, 0, 0, 0))
  body
  buffer.pop()

#Blits a framebuffer as a sorted rect.
proc blit*(buffer: Framebuffer, z: float32 = 0, color: Color = colorWhite) =
  draw(buffer.texture, fau.cam.pos.x, fau.cam.pos.y, z = z, color = color, width = fau.cam.w, height = -fau.cam.h)

#Blits a framebuffer immediately as a fullscreen quad. Does not use batch.
proc blitQuad*(buffer: Framebuffer, shader = fau.screenspace, unit = 0) =
  drawFlush()
  buffer.texture.use(unit)
  fau.quad.render(shader)

#BACKEND & INITIALIZATION

when defined(Android):
  include backend/glfmcore
else:
  include backend/glfwcore

import times, audio, shapes, random, font
export audio, shapes, font

#TODO move this somewhere else
proc axis*(left, right: KeyCode): int = 
  if left.down() and right.down(): return 0
  if left.down(): return -1
  if right.down(): return 1
  return 0

var 
  lastFrameTime: int64 = -1
  frameCounterStart: int64
  frames: int
  startTime: Time

proc initFau*(loopProc: proc(), initProc: proc() = (proc() = discard), windowWidth = 800, windowHeight = 600, windowTitle = "Unknown", maximize = true, 
  depthBits = 0, stencilBits = 0, clearColor = rgba(0, 0, 0, 0), atlasFile: static[string] = "atlas", visualizer = false) =

  initCore(
  (proc() =
    let time = (times.getTime() - startTime).inNanoseconds
    if lastFrameTime == -1: lastFrameTime = time

    fau.delta = min(float(time - lastFrameTime) / 1000000000.0, fau.maxDelta)
    fau.time += fau.delta
    lastFrameTime = time

    if time - frameCounterStart >= 1000000000:
      fau.fps = frames
      frames = 0
      frameCounterStart = time

    inc frames

    (fau.widthf, fau.heightf) = (fau.width.float32, fau.height.float32)

    loopProc()

    #flush any pending draw operations
    drawFlush()

    inc fau.frameId
  ), 
  (proc() =

    #randomize so it doesn't have to be done somewhere else
    randomize()

    #initialize audio
    initAudio(visualizer)
    #load the necessary audio files (macro generated)
    loadAudio()

    #add default framebuffer to state
    fau.bufferStack.add newDefaultFramebuffer()
    
    #create and use batch
    fau.batch = newBatch()

    fau.pixelScl = 1.0f

    fau.maxDelta = 1f / 60f
      
    #enable sorting by default
    fau.batchSort = true
    
    #use standard blending
    fau.batchBlending = blendNormal

    #set matrix to ortho
    fau.batchMat = ortho(0, 0, fau.width.float32, fau.height.float32)

    #create default camera
    fau.cam = newCam(fau.width.float32, fau.height.float32)

    #load sprites
    fau.atlas = loadAtlasStatic(atlasFile)

    fau.quad = newScreenMesh()
    fau.screenspace = newShader("""
    attribute vec4 a_position;
    attribute vec2 a_texc;
    varying vec2 v_texc;

    void main(){
        v_texc = a_texc;
        gl_Position = a_position;
    }
    """,

    """
    uniform sampler2D u_texture;
    varying vec2 v_texc;

    void main(){
      gl_FragColor = texture2D(u_texture, v_texc);
    }
    """)

    #load specialregions
    fau.white = fau.atlas["white"]
    fau.circle = fau.atlas["circle"]

    #center the UVs to prevent artifacts
    let avg = ((fau.white.u + fau.white.u2) / 2.0, (fau.white.v + fau.white.v2) / 2.0)
    (fau.white.u, fau.white.v, fau.white.u2, fau.white.v2) = (avg[0], avg[1], avg[0], avg[1])
    
    initProc()
  ), windowWidth = windowWidth, windowHeight = windowHeight, windowTitle = windowTitle, maximize = maximize)
