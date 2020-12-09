
when defined(Android):
  include backend/glfmcore
else:
  include backend/glfwcore

import common, times, audio, shapes, font
export common, audio, shapes, font

var lastFrameTime: int64 = -1
var frameCounterStart: int64
var frames: int
var startTime: Time

proc initFuse*(loopProc: proc(), initProc: proc() = (proc() = discard), windowWidth = 800, windowHeight = 600, windowTitle = "Unknown", maximize = true, 
  depthBits = 0, stencilBits = 0, clearColor = rgba(0, 0, 0, 0), atlasFile: static[string] = "assets/atlas", visualizer = false) =

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

    #initialize audio
    initAudio(visualizer)

    #add default framebuffer to state
    fuse.bufferStack.add newDefaultFramebuffer()
    
    #create and use batch
    fuse.batch = newBatch()
      
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

    #load white region
    fuse.white = fuse.atlas["white"]

    #center the UVs to prevent artifacts
    let avg = ((fuse.white.u + fuse.white.u2) / 2.0, (fuse.white.v + fuse.white.v2) / 2.0)
    (fuse.white.u, fuse.white.v, fuse.white.u2, fuse.white.v2) = (avg[0], avg[1], avg[0], avg[1])
    
    initProc()
  ), windowWidth = windowWidth, windowHeight = windowHeight, windowTitle = windowTitle, maximize = maximize, clearColor = clearColor)