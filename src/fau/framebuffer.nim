
import gl/[glproc, gltypes], fmath, texture, color

#OpenGL Framebuffer wrapper.
#TODO no depth buffer support!
type FramebufferObj* = object
  handle*: Gluint
  size: Vec2i
  texture: Texture
  isDefault: bool
type Framebuffer* = ref FramebufferObj

proc `=destroy`*(buffer: var FramebufferObj) =
  if buffer.handle != 0 and glInitialized:
    glDeleteFramebuffer(buffer.handle)
    buffer.handle = 0

#accessors; read-only
proc size*(buffer: Framebuffer): Vec2i {.inline.} = buffer.size
proc texture*(buffer: Framebuffer): Texture {.inline.} = buffer.texture

#TODO rendering should keep track of this, don't call manually? or do

proc resize*(buffer: Framebuffer, size: Vec2i) =
  #default buffers can't be resized
  if buffer.isDefault:
    buffer.size = size
    return

  let 
    width = max(size.x, 2)
    height = max(size.y, 2)
  
  #don't resize unnecessarily
  if width == buffer.size.x and height == buffer.size.y: return
  
  #delete old buffer handle.
  if buffer.handle != 0: 
    glDeleteFramebuffer(buffer.handle)
    buffer.handle = 0
  
  buffer.size = vec2i(width, height)

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
proc newFramebuffer*(size = vec2i(2)): Framebuffer = 
  result = Framebuffer()
  
  if size.x != 2 or size.y != 2: result.resize(size)

#Returns a new default framebuffer object. Internal use only.
proc newDefaultFramebuffer*(): Framebuffer = Framebuffer(handle: glGetIntegerv(GlFramebufferBinding).GLuint, isDefault: true)

#Binds the framebuffer. Internal use only!
proc use*(buffer: Framebuffer) =
  glBindFramebuffer(GlFramebuffer, buffer.handle)
  glViewport(0, 0, buffer.size.x.Glsizei, buffer.size.y.Glsizei)

#TODO bad impl
proc clear*(buffer: Framebuffer, color = colorClear) =
  buffer.use()
  ## Clears the color buffer.
  glClearColor(color.r, color.g, color.b, color.a)

  #TODO only clear these if the buffer has the right attachments.

  #Enables writing to the depth buffer for clearing. TODO may be inefficient?
  #glDepthMask(true)
  #TODO does GlDepthBufferBit incur additional perf penalties when there is no depth buffer?
  glClear(GlColorBufferBit) # or GlDepthBufferBit

#TODO wrap pixels in a object with a destructor?
proc read*(buffer: Framebuffer, pos: Vec2i, size: Vec2i): pointer =
  ## Reads pixels from the screen and returns a pointer to RGBA data.
  ## The result MUST be deallocated after use!
  buffer.use()
  var pixels = alloc(size.x * size.y * 4)
  glPixelStorei(GlPackAlignment, 1.Glint)
  glReadPixels(pos.x.GLint, pos.y.GLint, size.x.GLint, size.y.GLint, GlRgba, GlUnsignedByte, pixels)
  return pixels