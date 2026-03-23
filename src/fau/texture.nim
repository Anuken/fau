import gl/[glproc, gltypes], fmath, assets, os

import stb_image/read {.all.} as stbi

type TextureFilter* = enum
  tfNearest,
  tfLinear,
  tfMipMap

type TextureWrap* = enum
  twClamp,
  twRepeat,
  twMirroredRepeat

type TextureObj = object
  handle*: Gluint
  uwrap, vwrap: TextureWrap
  minfilter, magfilter: TextureFilter
  target: Glenum
  size*: Vec2i
  mipmaps: bool
  ## Can be empty, optional
  path*: string

  ## for lazily loaded textures when the handle is 0 - this is *compressed* image data, not raw RGBA pixels!
  dataSource: string
type Texture* = ref TextureObj

type RawImage* = tuple[data: pointer, width: int, height: int]

proc `=destroy`*(texture: var TextureObj) =
  if texture.handle != 0 and glInitialized:
    glDeleteTexture(texture.handle)
    texture.handle = 0
  if texture.dataSource != "":
    `=destroy`(texture.dataSource)
  if texture.path != "":
    `=destroy`(texture.path)

proc toGlEnum*(filter: TextureFilter): GLenum {.inline.} =
  case filter
  of tfNearest: GlNearest
  of tfLinear: GlLinear
  of tfMipmap: GlLinearMipmapLinear

proc toGlEnum(wrap: TextureWrap): GLenum {.inline.} =
  case wrap
  of twClamp: GlClampToEdge
  of twRepeat: GlRepeat
  of twMirroredRepeat: GlMirroredRepeat

proc `$`*(texture: Texture): string = "{ID:" & $texture.handle & " " & $texture.size.x & "x" & $texture.size.y & "}"

proc loaded(texture: Texture): bool {.inline.} = texture.handle != 0.Gluint

proc width*(texture: Texture): int {.inline.} = texture.size.x
proc height*(texture: Texture): int {.inline.} = texture.size.y
proc widthf*(texture: Texture): float32 {.inline.} = texture.size.x.float32
proc heightf*(texture: Texture): float32 {.inline.} = texture.size.y.float32

proc loadRawImageMem*(buffer: openArray[byte] | openArray[char] | string, channels = 4): RawImage {.gcsafe.}
proc freeRawImage*(img: pointer)

#binds the texture
#TODO do not export, textures should not be used manually.
proc use*(texture: Texture, unit: int = 0) =
  if not texture.loaded and texture.dataSource != "":
    #load the texture the first time it's bound
    texture.handle = glGenTexture()
    glActiveTexture((GlTexture0.int + unit).GLenum)
    glBindTexture(texture.target, texture.handle)

    let (data, width, height) = loadRawImageMem(texture.dataSource)
    glTexImage2D(texture.target, 0, GlRGBA.Glint, width.GLsizei, height.GLsizei, 0, GlRGBA, GlUnsignedByte, data)
    freeRawImage(data)

    texture.size = vec2i(width, height)

    echo "Lazily loaded texture: ", texture.path, " ", texture.size

    if texture.mipmaps:
      glGenerateMipmap(texture.target)
    
    glTexParameteri(texture.target, GlTextureMinFilter, texture.minfilter.toGlEnum.GLint)
    glTexParameteri(texture.target, GlTextureMagFilter, if texture.magFilter == tfMipMap: GlLinear.GLint else: texture.magfilter.toGlEnum.GLint)
    glTexParameteri(texture.target, GlTextureWrapS, texture.uwrap.toGlEnum.GLint)
    glTexParameteri(texture.target, GlTextureWrapT, texture.vwrap.toGlEnum.GLint)
  else:
    glActiveTexture((GlTexture0.int + unit).GLenum)
    glBindTexture(texture.target, texture.handle)

proc `filterMin=`*(texture: Texture, filter: TextureFilter) =
  if texture.minfilter != filter:
    texture.minfilter = filter
    if texture.loaded:
      texture.use()
      glTexParameteri(texture.target, GlTextureMinFilter, texture.minfilter.toGlEnum.GLint)

proc `filterMag=`*(texture: Texture, filter: TextureFilter) =
  if texture.magfilter != filter:
    texture.magfilter = filter
    if texture.loaded:
      texture.use()
      glTexParameteri(texture.target, GlTextureMagFilter, texture.magfilter.toGlEnum.GLint)

#assigns min and mag filters
proc `filter=`*(texture: Texture, filter: TextureFilter) =
  texture.filterMin = filter
  texture.filterMag = filter

proc `wrapU=`*(texture: Texture, wrap: TextureWrap) =
  if texture.uwrap != wrap:
    texture.uwrap = wrap
    if texture.loaded:
      texture.use()
      glTexParameteri(texture.target, GlTextureWrapS, texture.uwrap.toGlEnum.GLint)

proc `wrapV=`*(texture: Texture, wrap: TextureWrap) =
  if texture.vwrap != wrap:
    texture.vwrap = wrap
    if texture.loaded:
      texture.use()
      glTexParameteri(texture.target, GlTextureWrapT, texture.vwrap.toGlEnum.GLint)

#assigns wrap modes for each axis
proc `wrap=`*(texture: Texture, wrap: TextureWrap) =
  texture.wrapU = wrap
  texture.wrapV = wrap

proc ratio*(texture: Texture): float32 = float32(texture.size.x / texture.size.y)

proc loadRawImageMem*(buffer: openArray[byte] | openArray[char] | string, channels = 4): RawImage {.gcsafe.} =
  var
    width: cint
    height: cint
    components: cint

  let data = stbi.stbi_load_from_memory(cast[ptr cuchar](buffer[0].addr), buffer.len.cint, width, height, components, channels.cint)

  if data == nil:
    raise newException(STBIException, stbi.failureReason())

  return (data.pointer, width.int, height.int)

proc loadRawImageFile*(filename: string, channels = 4): RawImage {.gcsafe.} =
  var
    width: cint
    height: cint
    components: cint

  let data = stbi.stbi_load(filename.cstring, width, height, components, channels.cint)

  if data == nil:
    raise newException(STBIException, stbi.failureReason())

  return (data.pointer, width.int, height.int)

proc loadRawImage*(path: static[string]): RawImage {.gcsafe.} =
  when staticAssets:
    loadRawImageMem(assetReadStatic(path))
  elif defined(Android): #android -> load asset
    loadRawImageMem(assetRead(path))
  else: #load from filesystem
    loadRawImageFile(path.assetFile)   

proc freeRawImage*(img: RawImage) =
  stbi.stbi_image_free(img.data)

proc freeRawImage*(img: pointer) =
  stbi.stbi_image_free(img)

#completely reloads texture data
proc load*(texture: Texture, size: Vec2i, pixels: pointer) =
  #bind texture
  texture.use()
  glTexImage2D(texture.target, 0, GlRGBA.Glint, size.x.GLsizei, size.y.GLsizei, 0, GlRGBA, GlUnsignedByte, pixels)
  if texture.mipmaps:
    glGenerateMipmap(texture.target)
  texture.size = size

#updates a portion of a texture with some pixels.
proc update*(texture: Texture, pos: Vec2i, size: Vec2i, pixels: pointer) =
  #bind texture
  texture.use()
  glTexSubImage2D(texture.target, 0, pos.x.GLint, pos.y.GLint, size.x.GLsizei, size.y.GLsizei, GlRGBA, GlUnsignedByte, pixels)

#creates a texture with no handle that will be loaded from the string once used
proc newLazyTexture*(size: Vec2i, data: string, filter = tfNearest, wrap = twClamp, mipmaps = false, path = ""): Texture = 
  Texture(uwrap: wrap, vwrap: wrap, minfilter: filter, magfilter: filter, target: GlTexture2D, size: size, mipmaps: mipmaps, dataSource: data, path: path)

#creates a base texture with no data uploaded
proc newTexture*(size: Vec2i = vec2i(1), filter = tfNearest, wrap = twClamp, mipmaps = false, path = ""): Texture = 
  result = Texture(handle: glGenTexture(), uwrap: wrap, vwrap: wrap, minfilter: filter, magfilter: filter, target: GlTexture2D, size: size, mipmaps: mipmaps, path: path)
  result.use()

  #set parameters
  glTexParameteri(result.target, GlTextureMinFilter, result.minfilter.toGlEnum.GLint)
  #mipmap can't be a magnification filter, but allow it for convenience
  glTexParameteri(result.target, GlTextureMagFilter, if result.magFilter == tfMipMap: GlLinear.GLint else: result.magfilter.toGlEnum.GLint)
  glTexParameteri(result.target, GlTextureWrapS, result.uwrap.toGlEnum.GLint)
  glTexParameteri(result.target, GlTextureWrapT, result.vwrap.toGlEnum.GLint)

#load texture from ptr to decoded PNG data
proc loadTexturePtr*(size: Vec2i, data: pointer, filter = tfNearest, wrap = twClamp, mipmaps = false, path = ""): Texture =
  result = newTexture(filter = filter, wrap = wrap, mipmaps = mipmaps, path = path)

  result.size = size
  result.load(size, data)

#load texture from bytes
proc loadTextureBytes*(bytes: string, filter = tfNearest, wrap = twClamp, mipmaps = false, path = ""): Texture =
  result = newTexture(filter = filter, wrap = wrap, mipmaps = mipmaps, path = path)

  let (data, width, height) = loadRawImageMem(bytes)

  result.load(vec2i(width, height), data)

  freeRawImage(data)

#load texture from path
proc loadTextureFile*(path: string, filter = tfNearest, wrap = twClamp, mipmaps = false): Texture = 
  result = newTexture(filter = filter, wrap = wrap, mipmaps = mipmaps, path = path)
  
  try:
    let (data, width, height) = loadRawImageFile(path)

    result.load(vec2i(width, height), data)

    freeRawImage(data)
  except STBIException:
    raise Exception.newException("Failed to load image '" & path & "': " & $getCurrentExceptionMsg())

proc loadTextureAsset*(path: string, filter = tfNearest, wrap = twClamp, mipmaps = false): Texture =
  loadTextureBytes(assetRead(path), filter, wrap, mipmaps, path = path)

proc loadTexture*(path: static[string], filter = tfNearest, wrap = twClamp, mipmaps = false): Texture =
  when staticAssets:
    loadTextureBytes(assetReadStatic(path), filter, wrap, mipmaps, path = path)
  elif defined(Android): #android -> load asset
    loadTextureBytes(assetRead(path), filter, wrap, mipmaps, path = path)
  else: #load from filesystem
    loadTextureFile(path.assetFile, filter, wrap, mipmaps)