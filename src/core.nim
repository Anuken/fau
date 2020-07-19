include backend/glfwcore

import common, batch, times
export common

var lastFrameTime: int64 = -1
var frameCounterStart: int64
var frames: int
var startTime: Time

proc initFuse*(loopProc: proc(), initProc: proc() = (proc() = discard), windowWidth = 800, windowHeight = 600, windowTitle = "Unknown", maximize = true, depthBits = 0, stencilBits = 0, clearColor = rgba(0, 0, 0, 0)) =
  initCore(
  (proc() =
    let time = (times.getTime() - startTime).inNanoseconds
    if lastFrameTime == -1: lastFrameTime = time

    fuse.delta = float(time - lastFrameTime) / 1000000000.0 * 60.0
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
    #add default framebuffer to state
    fuse.bufferStack.add newDefaultFramebuffer()
    
    #create default batch
    let batch = newBatch()
    batch.use()
    
    #use standard blending
    fuse.batchBlending = blendNormal

    #set matrix to ortho
    fuse.batchMat = ortho(0, 0, fuse.width.float32, fuse.height.float32)

    #create default camera
    fuse.cam = newCam(fuse.width.float32, fuse.height.float32)
    
    initProc()
  ), windowWidth = windowWidth, windowHeight = windowHeight, windowTitle = windowTitle, maximize = maximize, clearColor = clearColor)