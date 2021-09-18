import stb_image/read as stbi, gl/[glproc, gltypes], fmath, util/util

#an openGL image
type TextureObj = object
  handle*: Gluint
  uwrap, vwrap: Glenum
  minfilter, magfilter: Glenum
  target*: Glenum
  width*, height*: int
type Texture* = ref TextureObj

proc `=destroy`*(texture: var TextureObj) =
  if texture.handle != 0 and glInitialized:
    glDeleteTexture(texture.handle)
    texture.handle = 0

#binds the texture
#TODO do not export, textures should not be used manually.
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

#TODO use enum.
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
proc load*(texture: Texture, width, height: int, pixels: pointer) =
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
