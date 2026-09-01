import gl/[glproc, gltypes], fmath, texture, color

type
  ## Framebuffer format.
  Format* = object
    attachment: GLenum
    internalFormat: GLenum
    baseFormat: GLenum
    baseType: GLenum

  FramebufferObj* = object
    handle: Gluint
    size: Vec2i
    isDefault: bool
    filter: TextureFilter
    formats: seq[Format]
    ## If true, the depth/stencil attachments can be read from (are textures instead of renderbuffers)
    readableTextures: bool
    # renderbuffer handles; only populated for depth/stencil attachments when readableTextures is false.
    renderbuffers: seq[GLuint]
    # convenience handles for textures if specified; nil otherwise
    texture, depthTexture, stencilTexture: Texture
    # all readable texture formats, including the color one
    textureAttachments*: seq[Texture]
  Framebuffer* = ref FramebufferObj

const
  #color - standard
  fmColorRgba8* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba8, baseFormat: GlRgba, baseType: GlUnsignedByte)
  fmColorRgba4* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba4, baseFormat: GlRgba, baseType: GlUnsignedShort4444)
  fmColorRgb565* = Format(attachment: GlColorAttachment0, internalFormat: GlRgb565, baseFormat: GlRgb, baseType: GlUnsignedShort565)
  fmColorRgb5A1* = Format(attachment: GlColorAttachment0, internalFormat: GlRgb5A1, baseFormat: GlRgba, baseType: GlUnsignedShort5551)
  fmColorRgb10A2* = Format(attachment: GlColorAttachment0, internalFormat: GlRgb10A2, baseFormat: GlRgba, baseType: GlUnsignedInt2101010Rev)
  fmColorSrgb8Alpha8* = Format(attachment: GlColorAttachment0, internalFormat: GlSrgb8Alpha8, baseFormat: GlRgba, baseType: GlUnsignedByte)

  #color - HDR
  fmColorRgba16f* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba16f, baseFormat: GlRgba, baseType: GlHalfFloat)
  fmColorRgba32f* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba32f, baseFormat: GlRgba, baseType: GlFloatV)
  fmColorR11fG11fB10f* = Format(attachment: GlColorAttachment0, internalFormat: GlR11fG11fB10f, baseFormat: GlRgb, baseType: GlUnsignedInt10f11f11fRev)

  #color - single channel
  fmColorR8* = Format(attachment: GlColorAttachment0, internalFormat: GlR8, baseFormat: GlRed, baseType: GlUnsignedByte)
  fmColorR16f* = Format(attachment: GlColorAttachment0, internalFormat: GlR16f, baseFormat: GlRed, baseType: GlHalfFloat)
  fmColorR32f* = Format(attachment: GlColorAttachment0, internalFormat: GlR32f, baseFormat: GlRed, baseType: GlFloatV)

  #color - two channel
  fmColorRg8* = Format(attachment: GlColorAttachment0, internalFormat: GlRg8, baseFormat: GlRg, baseType: GlUnsignedByte)
  fmColorRg16f* = Format(attachment: GlColorAttachment0, internalFormat: GlRg16f, baseFormat: GlRg, baseType: GlHalfFloat)
  fmColorRg32f* = Format(attachment: GlColorAttachment0, internalFormat: GlRg32f, baseFormat: GlRg, baseType: GlFloatV)

  #color - integer RGBA
  fmColorRgba8i* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba8i, baseFormat: GlRgbaInteger, baseType: GlByteV)
  fmColorRgba8ui* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba8ui, baseFormat: GlRgbaInteger, baseType: GlUnsignedByte)
  fmColorRgba16i* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba16i, baseFormat: GlRgbaInteger, baseType: GlShortV)
  fmColorRgba16ui* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba16ui, baseFormat: GlRgbaInteger, baseType: GlUnsignedShort)
  fmColorRgba32i* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba32i, baseFormat: GlRgbaInteger, baseType: GlIntV)
  fmColorRgba32ui* = Format(attachment: GlColorAttachment0, internalFormat: GlRgba32ui, baseFormat: GlRgbaInteger, baseType: GlUnsignedInt)
  fmColorRgb10A2ui* = Format(attachment: GlColorAttachment0, internalFormat: GlRgb10A2ui, baseFormat: GlRgbaInteger, baseType: GlUnsignedInt2101010Rev)

  #color - integer RG
  fmColorRg8i* = Format(attachment: GlColorAttachment0, internalFormat: GlRg8i, baseFormat: GlRgInteger, baseType: GlByteV)
  fmColorRg8ui* = Format(attachment: GlColorAttachment0, internalFormat: GlRg8ui, baseFormat: GlRgInteger, baseType: GlUnsignedByte)
  fmColorRg16i* = Format(attachment: GlColorAttachment0, internalFormat: GlRg16i, baseFormat: GlRgInteger, baseType: GlShortV)
  fmColorRg16ui* = Format(attachment: GlColorAttachment0, internalFormat: GlRg16ui, baseFormat: GlRgInteger, baseType: GlUnsignedShort)
  fmColorRg32i* = Format(attachment: GlColorAttachment0, internalFormat: GlRg32i, baseFormat: GlRgInteger, baseType: GlIntV)
  fmColorRg32ui* = Format(attachment: GlColorAttachment0, internalFormat: GlRg32ui, baseFormat: GlRgInteger, baseType: GlUnsignedInt)

  #color - integer single channel
  fmColorR8i* = Format(attachment: GlColorAttachment0, internalFormat: GlR8i, baseFormat: GlRedInteger, baseType: GlByteV)
  fmColorR8ui* = Format(attachment: GlColorAttachment0, internalFormat: GlR8ui, baseFormat: GlRedInteger, baseType: GlUnsignedByte)
  fmColorR16i* = Format(attachment: GlColorAttachment0, internalFormat: GlR16i, baseFormat: GlRedInteger, baseType: GlShortV)
  fmColorR16ui* = Format(attachment: GlColorAttachment0, internalFormat: GlR16ui, baseFormat: GlRedInteger, baseType: GlUnsignedShort)
  fmColorR32i* = Format(attachment: GlColorAttachment0, internalFormat: GlR32i, baseFormat: GlRedInteger, baseType: GlIntV)
  fmColorR32ui* = Format(attachment: GlColorAttachment0, internalFormat: GlR32ui, baseFormat: GlRedInteger, baseType: GlUnsignedInt)

  #depth
  fmDepth16* = Format(attachment: GlDepthAttachment, internalFormat: GlDepthComponent16, baseFormat: GlDepthComponent, baseType: GlUnsignedShort)
  fmDepth24* = Format(attachment: GlDepthAttachment, internalFormat: GlDepthComponent24, baseFormat: GlDepthComponent, baseType: GlUnsignedInt)
  fmDepth32f* = Format(attachment: GlDepthAttachment, internalFormat: GlDepthComponent32f, baseFormat: GlDepthComponent, baseType: GlFloatV)

  #depth + stencil
  fmDepthStencil24* = Format(attachment: GlDepthStencilAttachment, internalFormat: GlDepth24Stencil8, baseFormat: GlDepthStencil, baseType: GlUnsignedInt248)
  fmDepthStencil32f* = Format(attachment: GlDepthStencilAttachment, internalFormat: GlDepth32fStencil8, baseFormat: GlDepthStencil, baseType: GlFloat32UnsignedInt248Rev)

  #stencil
  fmStencil8* = Format(attachment: GlStencilAttachment, internalFormat: GlStencilIndex8, baseFormat: GlStencilIndex, baseType: GlUnsignedByte)

  #default attachment sets for common framebuffer configurations
  defaultColorFormats* = @[fmColorRgba8]
  defaultColorDepthFormats* = @[fmColorRgba8, fmDepth24]
  defaultColorStencilFormats* = @[fmColorRgba8, fmDepthStencil24]

const isGlES = defined(android) or defined(ios) or defined(emscripten)

proc isColor*(format: Format): bool {.inline.} = format.attachment == GlColorAttachment0
proc isDepth*(format: Format): bool {.inline.} = format.attachment == GlDepthAttachment or format.attachment == GlDepthStencilAttachment
proc isStencil*(format: Format): bool {.inline.} = format.attachment == GlStencilAttachment or format.attachment == GlDepthStencilAttachment
proc isIntegerFormat*(format: Format): bool {.inline.} = format.baseFormat == GlRgbaInteger or format.baseFormat == GlRgInteger or format.baseFormat == GlRedInteger

var supportsFloatLinearExtVal: bool
proc supportsFloatLinearExt: bool =
  once:
    supportsFloatLinearExtVal = extensionSupported("OES_texture_float_linear")
  supportsFloatLinearExtVal

## Whether this format may use linear (as opposed to nearest) texture filtering.
proc isLinearFilterable*(format: Format): bool =
  format.isColor and not format.isIntegerFormat and (not isGlES or format.baseType != GlFloatV or supportsFloatLinearExt())

proc `=destroy`*(buffer: var FramebufferObj) =
  for tex in buffer.textureAttachments:
    if tex != nil:
      `=destroy`(tex)

  for rb in buffer.renderbuffers:
    if rb != 0 and glInitialized:
      glDeleteRenderbuffer(rb)

  if buffer.handle != 0 and glInitialized:
    glDeleteFramebuffer(buffer.handle)
    buffer.handle = 0

#accessors; read-only
proc size*(buffer: Framebuffer): Vec2i {.inline.} = buffer.size
#the first color attachment's texture; nil only if no color format was specified.
proc texture*(buffer: Framebuffer): Texture {.inline.} = buffer.texture
#the depth attachment's texture; nil unless readableTextures is true and a depth format was specified.
proc depthTexture*(buffer: Framebuffer): Texture {.inline.} = buffer.depthTexture
#the stencil attachment's texture; nil unless readableTextures is true and a stencil format was specified.
proc stencilTexture*(buffer: Framebuffer): Texture {.inline.} = buffer.stencilTexture
proc formats*(buffer: Framebuffer): seq[Format] {.inline.} = buffer.formats
proc readableTextures*(buffer: Framebuffer): bool {.inline.} = buffer.readableTextures

#whether any attachment format is a depth (or depth+stencil) format
proc hasDepth*(buffer: Framebuffer): bool =
  for format in buffer.formats:
    if format.isDepth: return true

#disposes all current texture/renderbuffer attachments, without touching the framebuffer handle itself
proc disposeAttachments(buffer: Framebuffer) =
  buffer.textureAttachments.setLen(0)
  buffer.texture = nil
  buffer.depthTexture = nil
  buffer.stencilTexture = nil

  for rb in buffer.renderbuffers:
    if rb != 0 and glInitialized:
      glDeleteRenderbuffer(rb)
  buffer.renderbuffers.setLen(0)

proc resize*(buffer: Framebuffer, size: Vec2i): bool {.discardable.} =
  #default buffers can't be resized
  if buffer.isDefault:
    buffer.size = size
    return false

  let
    width = max(size.x, 2)
    height = max(size.y, 2)

  #don't resize unnecessarily
  if width == buffer.size.x and height == buffer.size.y: return false
  
  result = true

  #dispose old attachments and buffer handle.
  disposeAttachments(buffer)

  if buffer.handle != 0:
    glDeleteFramebuffer(buffer.handle)
    buffer.handle = 0

  buffer.size = vec2i(width, height)

  buffer.handle = glGenFramebuffer()
  glBindFramebuffer(GlFramebuffer, buffer.handle)

  var colorTextureCounter = 0

  for format in buffer.formats:
    #color attachments are assigned sequential attachment point
    let point =
      if format.isColor: (GlColorAttachment0.int + colorTextureCounter).GLenum
      else: format.attachment

    #color attachments are always sampleable textures

    if format.isColor or buffer.readableTextures:
      let tex = newTexture(vec2i(width, height), filter = (if format.isLinearFilterable: buffer.filter else: tfNearest))

      glBindTexture(GlTexture2D, tex.handle)
      #for webGL 1.0 or GL < 3, the internal format must be a non-sized format (usually rgba)
      glTexImage2D(GlTexture2D, 0, if glVersionMajor < 3 or defined(emscripten): format.baseFormat.GLint else: format.internalFormat.GLint, width.GLsizei, height.GLsizei, 0, format.baseFormat, format.baseType, nil)

      if format.isColor: buffer.texture = tex
      if format.isDepth: buffer.depthTexture = tex
      if format.isStencil: buffer.stencilTexture = tex

      buffer.textureAttachments.add tex

      glFramebufferTexture2D(GlFramebuffer, point, GlTexture2D, tex.handle, 0)
    else:
      #renderbuffers are cheaper than textures, but cannot be sampled from
      let rb = glGenRenderbuffer()
      glBindRenderbuffer(GlRenderbuffer, rb)
      glRenderbufferStorage(GlRenderbuffer, format.internalFormat, width.GLsizei, height.GLsizei)
      glFramebufferRenderbuffer(GlFramebuffer, point, GlRenderbuffer, rb)

      buffer.renderbuffers.add rb

    if format.isColor: colorTextureCounter.inc

  if colorTextureCounter > 1: doAssert false, "MRT is not supported!"

  let status = glCheckFramebufferStatus(GlFramebuffer)

  #check for errors
  if status != GlFramebufferComplete:
    let message = case status:
      of GlFramebufferIncompleteAttachment: "Framebuffer error: incomplete attachment"
      of GlFramebufferIncompleteDimensions: "Framebuffer error: incomplete dimensions"
      of GlFramebufferIncompleteMissingAttachment: "Framebuffer error: missing attachment"
      of GlFramebufferUnsupported: "Framebuffer error: unsupported combination of formats"
      else: "Framebuffer: Error code " & $status

    raise GlError.newException(message)

proc resize*(buffer: Framebuffer, size: Vec2): bool {.discardable.} = buffer.resize(size.vec2i)

#If no size arguments are provided, this buffer cannot be used until it is resized.
#Formats defaults to a single standard RGBA8 color attachment.
#If readableTextures is true, the depth/stencil textures can be read from.
proc newFramebuffer*(size = vec2i(2), formats: seq[Format] = @[fmColorRgba8], readableTextures = false, filter = tfNearest): Framebuffer =
  result = Framebuffer(formats: formats, readableTextures: readableTextures, filter: filter)

  if size.x != 2 or size.y != 2: result.resize(size)

#Returns a new default framebuffer object. Internal use only.
proc newDefaultFramebuffer*(windowDepth: bool): Framebuffer = Framebuffer(handle: glGetIntegerv(GlFramebufferBinding).GLuint, isDefault: true, formats: (if windowDepth: @[fmDepth24] else: @[]))

#Binds the framebuffer. Internal use only!
proc use*(buffer: Framebuffer, viewPos = vec2i(), viewSize = buffer.size) =
  glBindFramebuffer(GlFramebuffer, buffer.handle)
  glViewport(viewPos.x.Glsizei, viewPos.y.Glsizei, viewSize.x.Glsizei, viewSize.y.Glsizei)

proc clear*(buffer: Framebuffer, color = colorClear) =
  ## Clears the color & depth buffers.
  buffer.use()

  glDisable(GlScissorTest)
  glClearColor(color.r, color.g, color.b, color.a)

  if buffer.hasDepth:
    #Enables writing to the depth buffer for clearing. TODO may be inefficient?
    glDepthMask(true)
    glClear(GlColorBufferBit or GlDepthBufferBit)
  else:
    glClear(GlColorBufferBit)

#TODO wrap pixels in a object with a destructor?
proc read*(buffer: Framebuffer, pos: Vec2i = vec2i(), size: Vec2i = buffer.size): pointer =
  ## Reads pixels from the screen and returns a pointer to RGBA data.
  ## The result MUST be deallocated after use!
  buffer.use()
  var pixels = alloc(size.x * size.y * 4)
  glPixelStorei(GlPackAlignment, 1.Glint)
  glReadPixels(pos.x.GLint, pos.y.GLint, size.x.GLint, size.y.GLint, GlRgba, GlUnsignedByte, pixels)
  return pixels