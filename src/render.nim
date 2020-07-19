import graphics, gl, batch

#Hold all the graphics state.
type GraphicsState = object
  #Reference to proc that flushes the batch.
  batchFlush: proc()
  #Reference to a proc that draws a patch at specified coordinates
  batchDraw: proc(region: Patch, x: float32, y: float32, width: float32, height: float32, originX: float32 = 0, originY: float32 = 0, rotation: float32 = 0, color: float32 = 0)
  #The currently-used batch shader.
  batchShader: Shader
  #The matrix being used by the batch
  batchMat: Mat
  #Currently bound framebuffer.
  bufferStack: seq[Framebuffer]

#Global instance of graphics state.
var state = GraphicsState()

#Flush the batched items.
proc drawFlush*() {.inline.} = state.batchFlush()

#Set a shader to be used for rendering. This flushes the batch.
proc drawShader*(shader: Shader) {.inline.} = 
  drawFlush()
  state.batchShader = shader

#Sets the matrix used for rendering. This flushes the batch.
proc drawMat*(mat: Mat) {.inline.} = 
  drawFlush()
  state.batchMat = mat

#TODO ???
proc use*(batch: Batch) =
  state.batchFlush = proc() = batch.flush()

#Must be called at the start of the program after GL is initialized by the backend.
proc initGraphics*() =
  #add default framebuffer to state
  state.bufferStack.add newDefaultFramebuffer()

  #set up procs that raise an error when called to catch lack of initialization
  state.batchFlush = proc() = 
    raise Exception.newException("Graphics state is not initialized.")
  state.batchDraw = proc(region: Patch, x: float32, y: float32, width: float32, height: float32, originX: float32 = 0, originY: float32 = 0, rotation: float32 = 0, color: float32 = 0) = 
    raise Exception.newException("Graphics state is not initialized.")

#returns the current framebuffer
proc currentBuffer*(): Framebuffer {.inline.} = state.bufferStack[^1]

#Begin rendering to the buffer
proc start*(buffer: Framebuffer) = 
  if buffer == currentBuffer(): raise GLerror.newException("Can't begin framebuffer twice")

  drawFlush()

  #add buffer to stack
  state.bufferStack.add buffer

  buffer.use()

#Begin rendering to the buffer, but clear it as well
proc start*(buffer: Framebuffer, clearColor: Color) =
  buffer.start()
  clearScreen(clearColor)

#End rendering to the buffer
proc stop*(buffer: Framebuffer) =
  #pop current buffer from the stack, make sure it's correct
  if buffer != state.bufferStack.pop(): raise GLerror.newException("Framebuffer was not begun, can't end")
  #use previous buffer
  currentBuffer().use()