import fau/[fmath, globals, color, framebuffer, mesh, patch, shader, texture, batch, atlas, draw, screenbuffer, input]
import os, times, random

const isDebug* = defined(debug)

when isMobile:
  include fau/backend/glfmcore
else:
  include fau/backend/glfwcore

when not defined(noAudio):
  import fau/audio
  export audio

when isDebug:
  import fau/util/recorder

export fmath, globals, color, framebuffer, mesh, patch, shader, texture, batch, atlas, draw, screenbuffer, input

#global state for input/time
var
  lastFrameTime: int64 = -1
  frameCounterStart: int64
  frames: int
  startTime: Time

#TODO all of these should be struct parameters!
proc initFau*(loopProc: proc(), initProc: proc() = (proc() = discard), params = initParams()) =

  fau.clearColor = params.clearColor

  #handle & update input based on events
  addFauListener(proc(e: FauEvent) =
    case e.kind:
    of feKey:
      if e.keyDown:
        keysJustDown[e.key] = true
        keysPressed[e.key] = true
      else:
        keysJustUp[e.key] = true
        keysPressed[e.key] = false
    of feScroll:
      fau.scroll = e.scroll
    of feResize:
      fau.sizei = e.size
      fau.size = e.size.vec2
    of feTouch:
      if e.touchDown:
        keysJustDown[e.touchButton] = true
        keysPressed[e.touchButton] = true
      else:
        keysJustUp[e.touchButton] = true
        keysPressed[e.touchButton] = false
      
      #update pointer data for mobile
      if e.touchId < fau.touches.len:
        template t: Touch = fau.touches[e.touchId]
        t.pos = e.touchPos
        t.down = e.touchDown
        if e.touchDown:
          t.last = t.pos
          t.delta = vec2(0f, 0f)
    of feDrag:
      #mouse position is always at the latest drag
      fau.mouse = e.dragPos
      if e.dragId < fau.touches.len:
        template t: Touch = fau.touches[e.dragId]
        t.pos = e.dragPos
    of feVisible:
      fau.shown = e.shown
    else: discard
  )

  initCore(
  (proc() =
    var time = (times.getTime() - startTime).inNanoseconds
    #at the start of the game, delta is assumed to be 1/60
    if lastFrameTime == -1: lastFrameTime = time - 16666666

    if fau.targetFps != 0:
      #expected ns between frames
      let targetDelay = 1f / fau.targetFps * 1000000000.0
      #actual time between frames
      let actualDelay = float(time - lastFrameTime)
      #time to sleep
      if targetDelay > actualDelay:
        #sleep and update time
        sleep(((targetDelay - actualDelay) * 1e-6).int)

        time = (times.getTime() - startTime).inNanoseconds

    fau.rawDelta = float(time - lastFrameTime) / 1000000000.0
    fau.delta = min(fau.rawDelta, fau.maxDelta)
    fau.time += fau.delta
    lastFrameTime = time

    if time - frameCounterStart >= 1000000000:
      fau.fps = frames
      frames = 0
      frameCounterStart = time
    
    for t in fau.touches.mitems:
      t.delta = t.pos - t.last
      t.last = t.pos
      
    inc frames

    fau.size = fau.sizei.vec2

    screen.resize(fau.sizei)
    screen.clear(fau.clearColor)
    loopProc()

    #flush any pending draw operations
    drawFlush()

    when isDebug:
      record()

    inc fau.frameId

    #clean up input
    for x in keysJustDown.mitems: x = false
    for x in keysJustUp.mitems: x = false
    fau.scroll = vec2()
  ), 
  (proc() =

    #standard random init does not work on Android, use time - I don't care about security
    let now = times.getTime()
    randomize(now.toUnix * 1_000_000_000 + now.nanosecond)

    #initialize audio
    when not defined(noAudio):
      initAudio()
      #load the necessary audio files (macro generated)
      loadAudio()
    
    #set up default density
    if fau.screenDensity <= 0.0001f:
      fau.screenDensity = 1f

    #assume window starts out shown
    fau.shown = true

    screen = newDefaultFramebuffer(params.depth)
    
    #create and use batch
    fau.batch = newBatch()

    fau.pixelScl = 1.0f

    fau.maxDelta = 1f / 60f

    #TODO is this necessary on emscripten? or at all?
    #when not defined(emscripten):
    #  fau.targetFps = 60

    #set matrix to ortho
    screenMat()

    #create default camera
    fau.cam = newCam(fau.size)

    #load sprites - always atlas.dat
    fau.atlas = loadAtlas("atlas")

    fau.quad = newScreenMesh()
    fau.screenspace = newShader(screenspaceVertex, screenspaceFragment)

    #load special regions
    fau.white = fau.atlas["white"]
    fau.circle = fau.atlas["circle"]

    #center the UVs to prevent artifacts
    let avg = ((fau.white.u + fau.white.u2) / 2.0, (fau.white.v + fau.white.v2) / 2.0)
    (fau.white.u, fau.white.v, fau.white.u2, fau.white.v2) = (avg[0], avg[1], avg[0], avg[1])
    
    if initProc != nil:
      initProc()
  ), params)