import backend/glfwcore, graphics, times

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

    loopProc()

    inc fuse.frameId
  ), 
  (proc() =
    initProc()
  ), windowWidth = windowWidth, windowHeight = windowHeight, windowTitle = windowTitle, maximize = maximize, clearColor = clearColor)