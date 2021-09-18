import fau/[fmath, globals, color, framebuffer, mesh, patch, shader, texture, batch, atlas, draw, screenbuffer, input]
import times, random

when defined(Android):
  include fau/backend/glfmcore
else:
  include fau/backend/glfwcore

when not defined(noAudio):
  import fau/audio
  export audio

when defined(debug):
  import fau/util/recorder

export fmath, globals, color, framebuffer, mesh, patch, shader, texture, batch, atlas, draw, screenbuffer, input

#global state for input/time
var
  lastFrameTime: int64 = -1
  frameCounterStart: int64
  frames: int
  startTime: Time

#TODO all of these should be struct parameters!
proc initFau*(loopProc: proc(), initProc: proc() = (proc() = discard), windowWidth = 800, windowHeight = 600, windowTitle = "Unknown", maximize = true, 
  depth = false, clearColor = colorClear, atlasFile: static[string] = "atlas") =

  fau.clearColor = clearColor

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
  )

  initCore(
  (proc() =
    let time = (times.getTime() - startTime).inNanoseconds
    if lastFrameTime == -1: lastFrameTime = time

    fau.delta = min(float(time - lastFrameTime) / 1000000000.0, fau.maxDelta)
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

    when defined(debug):
      record()

    inc fau.frameId

    #clean up input
    for x in keysJustDown.mitems: x = false
    for x in keysJustUp.mitems: x = false
    fau.scroll = vec2()
  ), 
  (proc() =

    #randomize so it doesn't have to be done somewhere else
    randomize()

    #initialize audio
    when not defined(noAudio):
      initAudio()
      #load the necessary audio files (macro generated)
      loadAudio()
    
    #set up default density
    if fau.screenDensity <= 0.0001f:
      fau.screenDensity = 1f

    screen = newDefaultFramebuffer()
    
    #create and use batch
    fau.batch = newBatch()

    fau.pixelScl = 1.0f

    fau.maxDelta = 1f / 60f

    #set matrix to ortho
    screenMat()

    #create default camera
    fau.cam = newCam(fau.size)

    #load sprites
    fau.atlas = loadAtlasStatic(atlasFile)

    fau.quad = newScreenMesh()
    fau.screenspace = newShader("""
    attribute vec4 a_pos;
    attribute vec2 a_uv;
    varying vec2 v_uv;

    void main(){
        v_uv = a_uv;
        gl_Position = a_pos;
    }
    """,

    """
    uniform sampler2D u_texture;
    varying vec2 v_uv;

    void main(){
      gl_FragColor = texture2D(u_texture, v_uv);
    }
    """)

    #load special regions
    fau.white = fau.atlas["white"]
    fau.circle = fau.atlas["circle"]

    #center the UVs to prevent artifacts
    let avg = ((fau.white.u + fau.white.u2) / 2.0, (fau.white.v + fau.white.v2) / 2.0)
    (fau.white.u, fau.white.v, fau.white.u2, fau.white.v2) = (avg[0], avg[1], avg[0], avg[1])
    
    initProc()
  ), windowWidth = windowWidth, windowHeight = windowHeight, windowTitle = windowTitle, maximize = maximize, depth = depth)