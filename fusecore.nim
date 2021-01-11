import gl, strutils, gltypes, tables, fmath, streams, macros, math, algorithm, sugar, futils

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

const rootDir = getProjectPath()[0..^5]

template staticReadString*(filename: string): string = 
  const realDir = rootDir & "/" & filename
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
#TODO switch to uint8 for better mem usage
type Color* = object
  r*, g*, b*, a*: float32

proc rgba*(r: float32, g: float32, b: float32, a: float32 = 1.0): Color = Color(r: r, g: g, b: b, a: a)

proc rgb*(r: float32, g: float32, b: float32): Color = Color(r: r, g: g, b: b, a: 1.0)

proc mix*(color: Color, other: Color, alpha: float32): Color =
  let inv = 1.0 - alpha
  return rgba(color.r*inv + other.r*alpha, color.g*inv + other.g*alpha, color.b*inv + other.b*alpha, color.a*inv + other.a*alpha)

#convert a color to a ABGR float representation; result may be NaN
proc toFloat*(color: Color): float32 {.inline.} = 
  cast[float32]((((255 * color.a).int shl 24) or ((255 * color.b).int shl 16) or ((255 * color.g).int shl 8) or ((255 * color.r).int)) and 0xfeffffff)

proc fromFloat*(fv: float32): Color {.inline.} = 
  let val = cast[uint32](fv)
  return rgba(((val and 0x00ff0000.uint32) shr 16).float32 / 255.0, ((val and 0x0000ff00.uint32) shr 8).float32 / 255.0, (val and 0x000000ff.uint32).float32 / 255.0, ((val and 0xff000000.uint32) shr 24).float32 / 255.0 * 255.0/254.0)

converter floatColor*(color: Color): float32 = color.toFloat

let
  colorClear* = rgba(0, 0, 0, 0)
  colorWhite* = rgb(1, 1, 1)
  colorBlack* = rgba(0, 0, 0)
  colorWhiteF* = colorWhite.toFloat()
  colorClearF* = colorClear.toFloat()

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
  daCenter = daLeft or daRight or daTop or daBot

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
type Texture* = ref object
  handle: Gluint
  uwrap, vwrap: Glenum
  minfilter, magfilter: Glenum
  target: Glenum
  width*, height*: int

#binds the texture
proc use*(texture: Texture, unit: GLenum = GlTexture0) =
  glActiveTexture(unit)
  glBindTexture(texture.target, texture.handle)
  
proc dispose*(texture: Texture) = 
  if texture.handle != 0:
    glDeleteTexture(texture.handle)
    texture.handle = 0

#assigns min and mag filters
proc `filter=`*(texture: Texture, filter: Glenum) =
  texture.minfilter = filter
  texture.magfilter = filter
  texture.use()
  glTexParameteri(texture.target, GlTextureMinFilter, texture.minfilter.GLint)
  glTexParameteri(texture.target, GlTextureMagFilter, texture.magfilter.GLint)

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

#stb is faster
when not defined(useStb):
  import nimPNG
else:
  import stb_image/read as stbi

#load texture from bytes
proc loadTextureBytes*(bytes: string): Texture =
  result = newTexture()

  when not defined(useStb):
    var data = decodePNG32(bytes)
    result.load(data.width, data.height, addr data.data[0])
  else:
    var
      width, height, channels: int
      data: seq[uint8]

    data = stbi.loadFromMemory(cast[seq[byte]](bytes), width, height, channels, 4)
    result.load(width, height, addr data[0])

  
#load texture from path
proc loadTexture*(path: string): Texture = loadTextureBytes(readFile(path))

proc loadTextureStatic*(path: static[string]): Texture = loadTextureBytes(staticReadString(path))

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

converter toPatch*(texture: Texture): Patch {.inline.} = Patch(texture: texture, u: 0.0, v: 0.0, u2: 1.0, v2: 1.0)

#SHADER

type ShaderAttr* = object
  name*: string
  gltype*: GLenum
  size*: GLint
  length*: Glsizei
  location*: GLint

type Shader* = ref object
  handle, vertHandle, fragHandle: GLuint
  compileLog: string
  compiled: bool
  uniforms: Table[string, int]
  attributes: Table[string, ShaderAttr]

proc loadSource(shader: Shader, shaderType: GLenum, source: string): GLuint =
  result = glCreateShader(shaderType)
  if result == 0: return 0.GLuint

  #attach source
  glShaderSource(result, source)
  glCompileShader(result)

  #check compiled status
  let compiled = glGetShaderiv(result, GL_COMPILE_STATUS)

  if compiled == 0:
    shader.compiled = false
    shader.compileLog &= ("[" & (if shaderType == GL_FRAGMENT_SHADER: "fragment shader" else: "vertex shader") & "]\n")
    let infoLen = glGetShaderiv(result, GL_INFO_LOG_LENGTH)
    if infoLen > 1:
      let infoLog = glGetShaderInfoLog(result)
      shader.compileLog &= infoLog #append reason to log
    glDeleteShader(result)

proc dispose*(shader: Shader) = 
  glUseProgram(0)
  glDeleteShader(shader.vertHandle)
  glDeleteShader(shader.fragHandle)
  glDeleteProgram(shader.handle)

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
  
  result.vertHandle = loadSource(result, GL_VERTEX_SHADER, preprocess(vertexSource, false))
  result.fragHandle = loadSource(result, GL_FRAGMENT_SHADER, preprocess(fragmentSource, true))

  if not result.compiled:
    raise newException(GLerror, "Failed to compile shader: \n" & result.compileLog)

  var program = glCreateProgram()
  glAttachShader(program, result.vertHandle)
  glAttachShader(program, result.fragHandle)
  glLinkProgram(program)

  let status = glGetProgramiv(program, GL_LINK_STATUS)

  if status == 0:
    let infoLen = glGetProgramiv(program, GL_INFO_LOG_LENGTH)
    if infoLen > 1:
      let infoLog = glGetProgramInfoLog(program)
      result.compileLog &= infoLog #append reason to log
      result.compiled = false
    raise Exception.newException("Failed to link shader: " & result.compileLog) 

  result.handle = program

  #fetch attributes for shader
  let numAttrs = glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES)
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

type Mesh* = ref object
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

proc dispose*(mesh: var Mesh) =
  if mesh.vertexBuffer != 0: glDeleteBuffer(mesh.vertexBuffer)
  if mesh.indexBuffer != 0: glDeleteBuffer(mesh.indexBuffer)

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
proc newScreenMesh*(): Mesh = newMesh(@[attribPos, attribTexCoords], isStatic = true, primitiveType = GlTriangleFan, vertices = @[-1'f32, -1, 0, 0, 1, -1, 1, 0, 1, 1, 1, 1, -1, 1, 0, 1])

#FRAMEBUFFER

type Framebuffer* = ref object
  handle: Gluint
  width: int
  height: int
  texture: Texture
  isDefault: bool

#accessors; read-only
proc width*(buffer: Framebuffer): int {.inline.} = buffer.width
proc height*(buffer: Framebuffer): int {.inline.} = buffer.height
proc texture*(buffer: Framebuffer): Texture {.inline.} = buffer.texture

proc dispose*(buffer: Framebuffer) = 
  if buffer.handle == 0: return #don't double dispose

  buffer.texture.dispose()
  glDeleteFramebuffer(buffer.handle)

proc resize*(buffer: Framebuffer, fwidth: int, fheight: int) =
  let 
    width = max(fwidth, 2)
    height = max(fheight, 2)
  
  #don't resize unnecessarily
  if width == buffer.width and height == buffer.height: return
  
  #dispose old buffer handle.
  buffer.dispose()
  buffer.width = width
  buffer.height = height

  buffer.handle = glGenFramebuffer()
  buffer.texture = Texture(handle: glGenTexture(), target: GlTexture2D, width: width, height: height)

  #get prrevious buffer handle - this does incur a slight overhead, but resizing happens rarely anyway
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
# accesses a region from an atlas
proc `[]`*(atlas: Atlas, name: string): Patch {.inline.} = atlas.patches.getOrDefault(name, atlas.patches["error"])

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
      x, y, originX, originY, width, height, rotation, color, mixColor: float32
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
type FuseState = object
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
  delta*: float
  #Time passed since game launch, in seconds
  time*: float
  #Mouse position
  mouseX*, mouseY*: float32

#Global instance of fuse state.
var fuse* = FuseState()

#Turns pixel units into world units
proc px*(val: float32): float32 {.inline.} = val * fuse.pixelScl

proc unproject*(cam: Cam, vec: Vec2): Vec2 = 
  vec2((2 * vec.x) / fuse.widthf - 1, (2 * vec.y) / fuse.heightf - 1) * cam.inv

proc project*(cam: Cam, vec: Vec2): Vec2 = 
  let pro = vec * cam.mat
  return vec2(fuse.widthf * (1) / 2 + pro.x, fuse.heightf * ( 1) / 2 + pro.y)

proc mouse*(): Vec2 = vec2(fuse.mouseX, fuse.mouseY)
proc mouseWorld*(): Vec2 = fuse.cam.unproject(vec2(fuse.mouseX, fuse.mouseY))
proc screen*(): Vec2 = vec2(fuse.width.float32, fuse.height.float32)

proc patch*(name: string): Patch {.inline.} = fuse.atlas[name]

#Batch methods
proc flush(batch: Batch) =
  if batch.index == 0: return

  batch.lastTexture.use()
  fuse.batchBlending.use()

  #use global shader if there is one set
  let shader = if fuse.batchShader.isNil: batch.shader else: fuse.batchShader

  shader.seti("u_texture", 0)
  shader.setmat4("u_proj", fuse.batchMat)

  batch.mesh.updateVertices()
  batch.mesh.render(batch.shader, 0, batch.index div spriteSize * 6)
  
  batch.index = 0

proc prepare(batch: Batch, texture: Texture) =
  if batch.lastTexture != texture or batch.index >= batch.size:
    batch.flush()
    batch.lastTexture = texture

proc drawRaw(batch: Batch, texture: Texture, vertices: array[spriteSize, Glfloat], z: float32) =
  if fuse.batchSort:
    batch.reqs.add(Req(kind: reqVert, tex: texture, verts: vertices, blend: fuse.batchBlending, z: z))
  else:
    batch.prepare(texture)

    let
      verts = addr batch.mesh.vertices
      idx = batch.index

    #copy over the vertices
    for i in 0..<spriteSize:
      verts[i + idx] = vertices[i]

    batch.index += spriteSize

proc drawRaw(batch: Batch, region: Patch, x, y, z, width, height, originX, originY, rotation, color, mixColor: float32) =
  if fuse.batchSort:
    batch.reqs.add(Req(kind: reqRect, patch: region, x: x, y: y, z: z, width: width, height: height, originX: originX, originY: originY, rotation: rotation, color: color, mixColor: mixColor, blend: fuse.batchBlending))
  else:
    batch.prepare(region.texture)

    if rotation == 0.0'f32:
      let
        x2 = width + x
        y2 = height + y
        u = region.u
        v = region.v2
        u2 = region.u2
        v2 = region.v
        idx = batch.index
        verts = addr batch.mesh.vertices

      verts.minsert(idx, [x, y, u, v, color, mixColor, x, y2, u, v2, color, mixColor, x2, y2, u2, v2, color, mixColor, x2, y, u2, v, color, mixColor])
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
        cos = cos(rotation.degToRad)
        sin = sin(rotation.degToRad)
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

      verts.minsert(idx, [x1, y1, u, v, color, mixColor, x2, y2, u, v2, color, mixColor, x3, y3, u2, v2, color, mixColor, x4, y4, u2, v, color, mixColor])

    batch.index += spriteSize

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
  batch.shader = newShader(
  """
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
  """,

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
  if fuse.batchSort:
    #sort requests by their Z value
    fuse.batch.reqs.sort((a, b) => a.z.cmp b.z)
    #disable it so following reqs are not sorted again
    fuse.batchSort = false

    let last = fuse.batchBlending
    
    for req in fuse.batch.reqs:
      if fuse.batchBlending != req.blend:
        fuse.batch.flush()
        req.blend.use()
        fuse.batchBlending = req.blend
      
      case req.kind:
      of reqVert:
        fuse.batch.drawRaw(req.tex, req.verts, 0)
      of reqRect:
        fuse.batch.drawRaw(req.patch, req.x, req.y, 0.0, req.width, req.height, req.originX, req.originY, req.rotation, req.color, req.mixColor)
      of reqProc:
        req.draw()
    
    fuse.batch.reqs.setLen(0)
    fuse.batchSort = true
    fuse.batchBlending = last

  #flush the base batch
  fuse.batch.flush()

#Set a shader to be used for rendering. This flushes the batch.
proc drawShader*(shader: Shader) = 
  drawFlush()
  fuse.batchShader = shader

#Sets the matrix used for rendering. This flushes the batch.
proc drawMat*(mat: Mat) = 
  drawFlush()
  fuse.batchMat = mat

#Draws something custom at a specific Z layer
proc draw*(z: float32, value: proc()) =
  if fuse.batchSort:
    fuse.batch.reqs.add(Req(kind: reqProc, draw: value, z: z, blend: fuse.batchBlending))
  else:
    value()

#Custom handling of begin/end for a specific Z layer
proc drawLayer*(z: float32, layerBegin, layerEnd: proc(), spread: float32 = 1) =
  draw(z - spread, layerBegin)
  draw(z + spread, layerEnd)

proc draw*(region: Patch, x, y: float32, z = 0'f32, width = region.widthf * fuse.pixelScl, height = region.heightf * fuse.pixelScl, 
  originX = width * 0.5, originY = height * 0.5, rotation = 0'f32, align = daCenter,
  color = colorWhiteF, mixColor = colorClearF) {.inline.} = 

  let 
    alignH = (-((align and daLeft) != 0).int + ((align and daRight) != 0).int + 1) / 2
    alignV = (-((align and daBot) != 0).int + ((align and daTop) != 0).int + 1) / 2

  fuse.batch.drawRaw(region, x - width * alignH, y - height * alignV, z, width, height, originX, originY, rotation, color, mixColor)

#draws a region with rotated bits
proc drawv*(region: Patch, x, y: float32, mutator: proc(x, y: float32, idx: int): Vec2, z = 0'f32, width = region.widthf * fuse.pixelScl, height = region.heightf * fuse.pixelScl, 
  originX = width * 0.5, originY = height * 0.5, rotation = 0'f32, align = daCenter,
  color = colorWhiteF, mixColor = colorClearF) =
  
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

  fuse.batch.drawRaw(region.texture, [cor1.x, cor1.y, u, v, color, mixColor, cor2.x, cor2.y, u, v2, color, mixColor, cor3.x, cor3.y, u2, v2, color, mixColor, cor4.x, cor4.y, u2, v, color, mixColor], z)

#TODO inline
proc drawRect*(region: Patch, x, y, width, height: float32, originX = 0'f32, originY = 0'f32, 
  rotation = 0'f32, color = colorWhiteF, mixColor = colorClearF) {.inline.} = 
  fuse.batch.drawRaw(region, x, y, 0, width, height, originX, originY, rotation, color, mixColor)

#TODO inline
proc drawVert*(texture: Texture, vertices: array[24, Glfloat], z: float32 = 0) {.inline.} = 
  fuse.batch.drawRaw(texture, vertices, z)

#Activates a camera.
proc use*(cam: Cam) =
  cam.update()
  drawMat cam.mat

#Binds the framebuffer. Internal use only.
proc use(buffer: Framebuffer) =
  #assign size if it is default
  if buffer.isDefault: (buffer.width, buffer.height) = (fuse.width, fuse.height)

  glBindFramebuffer(GlFramebuffer, buffer.handle)
  glViewport(0, 0, buffer.width.Glsizei, buffer.height.Glsizei)

#returns the current framebuffer
proc currentBuffer*(): Framebuffer {.inline.} = fuse.bufferStack[^1]

#Begin rendering to the buffer
proc push*(buffer: Framebuffer) = 
  if buffer == currentBuffer(): raise GLerror.newException("Can't begin framebuffer twice")

  drawFlush()

  #add buffer to stack
  fuse.bufferStack.add buffer

  buffer.use()

#Begin rendering to the buffer, but clear it as well
proc push*(buffer: Framebuffer, clearColor: Color) =
  buffer.push()
  clearScreen(clearColor)

#End rendering to the buffer
proc pop*(buffer: Framebuffer) =
  #pop current buffer from the stack, make sure it's correct
  if buffer != fuse.bufferStack.pop(): raise GLerror.newException("Framebuffer was not begun, can't end")

  #flush anything drawn
  drawFlush()
  #use previous buffer
  currentBuffer().use()

#Draw something inside a framebuffer
template inside*(buffer: Framebuffer, body: untyped) =
  buffer.push(rgba(0, 0, 0, 0))
  body
  buffer.pop()

#Blits a framebuffer as a sorted rect.
proc blit*(buffer: Framebuffer, z: float32 = 0, color: float32 = colorWhiteF) =
  draw(buffer.texture, fuse.cam.pos.x, fuse.cam.pos.y, z = z, color = color, width = fuse.cam.w, height = -fuse.cam.h)

#Blits a framebuffer immediately as a fullscreen quad. Does not use batch.
proc blitQuad*(buffer: Framebuffer, shader = fuse.screenspace) =
  drawFlush()
  buffer.texture.use()
  fuse.quad.render(shader)

#BACKEND & INITIALIZATION

when defined(Android):
  include backend/glfmcore
else:
  include backend/glfwcore

import times, audio, shapes, random
export audio, shapes

when defined(useFont):
  import font
  export font

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

proc initFuse*(loopProc: proc(), initProc: proc() = (proc() = discard), windowWidth = 800, windowHeight = 600, windowTitle = "Unknown", maximize = true, 
  depthBits = 0, stencilBits = 0, clearColor = rgba(0, 0, 0, 0), atlasFile: static[string] = "assets/atlas", visualizer = false) =

  initCore(
  (proc() =
    let time = (times.getTime() - startTime).inNanoseconds
    if lastFrameTime == -1: lastFrameTime = time

    fuse.delta = float(time - lastFrameTime) / 1000000000.0#[  ]#
    fuse.time += fuse.delta
    lastFrameTime = time

    if time - frameCounterStart >= 1000000000:
      fuse.fps = frames
      frames = 0
      frameCounterStart = time

    inc frames

    (fuse.widthf, fuse.heightf) = (fuse.width.float32, fuse.height.float32)

    loopProc()

    #flush any pending draw operations
    drawFlush()

    inc fuse.frameId
  ), 
  (proc() =

    #randomize so it doesn't have to be done somewhere else
    randomize()

    #initialize audio
    initAudio(visualizer)

    #add default framebuffer to state
    fuse.bufferStack.add newDefaultFramebuffer()
    
    #create and use batch
    fuse.batch = newBatch()

    fuse.pixelScl = 1.0'f32
      
    #enable sorting by default
    fuse.batchSort = true
    
    #use standard blending
    fuse.batchBlending = blendNormal

    #set matrix to ortho
    fuse.batchMat = ortho(0, 0, fuse.width.float32, fuse.height.float32)

    #create default camera
    fuse.cam = newCam(fuse.width.float32, fuse.height.float32)

    #load sprites
    fuse.atlas = loadAtlasStatic(atlasFile)

    fuse.quad = newScreenMesh()
    fuse.screenspace = newShader("""
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

    #load white region
    fuse.white = fuse.atlas["white"]

    #center the UVs to prevent artifacts
    let avg = ((fuse.white.u + fuse.white.u2) / 2.0, (fuse.white.v + fuse.white.v2) / 2.0)
    (fuse.white.u, fuse.white.v, fuse.white.u2, fuse.white.v2) = (avg[0], avg[1], avg[0], avg[1])
    
    initProc()
  ), windowWidth = windowWidth, windowHeight = windowHeight, windowTitle = windowTitle, maximize = maximize)
