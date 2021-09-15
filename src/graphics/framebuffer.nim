
proc `=destroy`*(buffer: var FramebufferObj) =
  if buffer.handle != 0 and glInitialized:
    glDeleteFramebuffer(buffer.handle)
    buffer.handle = 0

#accessors; read-only
proc width*(buffer: Framebuffer): int {.inline.} = buffer.width
proc height*(buffer: Framebuffer): int {.inline.} = buffer.height
proc size*(buffer: Framebuffer): Vec2 {.inline.} = vec2(buffer.width.float32, buffer.height.float32)
proc texture*(buffer: Framebuffer): Texture {.inline.} = buffer.texture

#TODO rendering should keep track of this, don't call manually.
proc resize*(buffer: Framebuffer, fwidth, fheight: int) =
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

#TODO should be private
#Returns a new default framebuffer object.
proc newDefaultFramebuffer*(): Framebuffer = Framebuffer(handle: glGetIntegerv(GlFramebufferBinding).GLuint, isDefault: true)

#TODO do not use?
#Binds the framebuffer. Internal use only.
proc use(buffer: Framebuffer) =
  #assign size if it is default
  if buffer.isDefault: (buffer.width, buffer.height) = (fau.width, fau.height)

  glBindFramebuffer(GlFramebuffer, buffer.handle)
  glViewport(0, 0, buffer.width.Glsizei, buffer.height.Glsizei)


#TODO bad utils?

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

#Draw something inside a framebuffer; does not clear!
template inside*(buffer: Framebuffer, body: untyped) =
  buffer.push()
  body
  buffer.pop()

#Draw something inside a framebuffer; clears automatically
template inside*(buffer: Framebuffer, clearColor: Color, body: untyped) =
  buffer.push(clearColor)
  body
  buffer.pop()

#TODO bad impl
proc clear*(buffer: Framebuffer, color = colorClear) =
  buffer.push(color)
  buffer.pop()

#Blits a framebuffer as a sorted rect.
proc blit*(buffer: Framebuffer, z: float32 = 0, color: Color = colorWhite) =
  draw(buffer.texture, fau.cam.pos, z = z, color = color, size = fau.cam.size * vec2(1, -1))

#Blits a framebuffer immediately as a fullscreen quad. Does not use batch.
proc blitQuad*(buffer: Framebuffer, shader = fau.screenspace, unit = 0) =
  drawFlush()
  buffer.texture.use(unit)
  fau.quad.render(shader)

#TODO both of the procs below need to be bound to framebuffers.

proc clearScreen*(col: Color = colorClear) =
  ## Clears the color buffer.
  glClearColor(col.r, col.g, col.b, col.a)
  #Enables writing to the depth buffer for clearing. TODO may be inefficient?
  glDepthMask(true)
  #TODO does GlDepthBufferBit incur additional perf penalties when there is no depth buffer?
  glClear(GlColorBufferBit or GlDepthBufferBit)

proc readPixels*(x, y, w, h: int): pointer =
  ## Reads pixels from the screen and returns a pointer to RGBA data.
  ## The result MUST be deallocated after use!
  var pixels = alloc(w * h * 4)
  glPixelStorei(GlPackAlignment, 1.Glint)
  glReadPixels(x.GLint, y.GLint, w.GLint, h.GLint, GlRgba, GlUnsignedByte, pixels)
  return pixels