import gl, strutils, gltypes, tables, fmath, streams, macros, math, algorithm, sugar, futils
import stb_image/read as stbi

include ftypes

export fmath, futils

#GLOBALS

#Global instance of fau state.
var fau* = FauState()

const rootDir = if getProjectPath().endsWith("src"): getProjectPath()[0..^5] else: getProjectPath()

template staticReadString*(filename: string): string = 
  const realDir = rootDir & "/assets/" & filename
  const str = staticRead(realDir)
  str

template staticReadStream*(filename: string): StringStream =
  newStringStream(staticReadString(filename))

#RENDERING

proc width*(cam: Cam): float32 {.inline.} = cam.size.x
proc height*(cam: Cam): float32 {.inline.} = cam.size.y

proc update*(cam: Cam, size: Vec2 = cam.size) = 
  cam.size = size
  cam.mat = ortho(cam.pos - cam.size/2f, cam.size)
  cam.inv = cam.mat.inv()

proc newCam*(w: float32 = 1, h: float32 = 1): Cam = 
  result = Cam(pos: vec2(0.0, 0.0), size: vec2(w, h))
  result.update()

proc viewport*(cam: Cam): Rect {.inline.} = rect(cam.pos - cam.size/2f, cam.size)

#types of draw alignment
const
  daLeft* = 1
  daRight* = 2
  daTop* = 4
  daBot* = 8
  daTopLeft* = daTop or daLeft
  daTopRight* = daTop or daRight
  daBotLeft* = daBot or daLeft
  daBotRight* = daBot or daRight
  daCenter* = daLeft or daRight or daTop or daBot

const
  blendNormal* = Blending(src: GlSrcAlpha, dst: GlOneMinusSrcAlpha)
  blendAdditive* = Blending(src: GlSrcAlpha, dst: GlOne)
  blendDisabled* = Blending(src: GlZero, dst: GlZero)
  blendErase* = Blending(src: GlZero, dst: GlOneMinusSrcAlpha)

#UTILITIES

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

proc fireFauEvent*(ev: FauEvent) =
  for l in fau.listeners: l(ev)

proc addFauListener*(ev: FauListener) =
  fau.listeners.add ev

#Turns pixel units into world units
proc px*(val: float32): float32 {.inline.} = val * fau.pixelScl

proc unproject*(cam: Cam, vec: Vec2): Vec2 = 
  vec2((2 * vec.x) / fau.widthf - 1, (2 * vec.y) / fau.heightf - 1) * cam.inv

proc project*(cam: Cam, vec: Vec2): Vec2 = 
  let pro = vec * cam.mat
  return vec2(fau.widthf * 1 / 2 + pro.x, fau.heightf * 1 / 2 + pro.y)

proc mouseWorld*(fau: FauState): Vec2 = fau.cam.unproject(fau.mouse)
proc screen*(fau: FauState): Vec2 {.inline.} = vec2(fau.width.float32, fau.height.float32)

#region BACKEND & INITIALIZATION

when defined(Android):
  include backend/glfmcore
else:
  include backend/glfwcore

when not defined(noAudio):
  import audio
  export audio

import times, shapes, random, font
export shapes, font

var
  lastFrameTime: int64 = -1
  frameCounterStart: int64
  frames: int
  startTime: Time

  keysPressed: array[KeyCode, bool]
  keysJustDown: array[KeyCode, bool]
  keysJustUp: array[KeyCode, bool]

proc down*(key: KeyCode): bool {.inline.} = keysPressed[key]
proc tapped*(key: KeyCode): bool {.inline.} = keysJustDown[key]
proc released*(key: KeyCode): bool {.inline.} = keysJustUp[key]
proc axis*(left, right: KeyCode): int = right.down.int - left.down.int

when defined(debug):
  import recorder

#TODO all of these should be struct parameters!
proc initFau*(loopProc: proc(), initProc: proc() = (proc() = discard), windowWidth = 800, windowHeight = 600, windowTitle = "Unknown", maximize = true, 
  depth = false, clearColor = rgba(0, 0, 0, 0), atlasFile: static[string] = "atlas") =

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
      (fau.width, fau.height) = (e.w.int, e.h.int)
      glViewport(0.GLint, 0.GLint, e.w.GLsizei, e.h.GLsizei)
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

    (fau.widthf, fau.heightf) = (fau.width.float32, fau.height.float32)

    clearScreen(fau.clearColor)
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

    #add default framebuffer to state
    fau.bufferStack.add newDefaultFramebuffer()
    
    #set up default density
    if fau.screenDensity <= 0.0001f:
      fau.screenDensity = 1f
    
    #create and use batch
    fau.batch = newBatch()

    fau.pixelScl = 1.0f

    fau.maxDelta = 1f / 60f
      
    #enable sorting by default
    fau.batchSort = true
    
    #use standard blending
    fau.batchBlending = blendNormal

    #set matrix to ortho
    fau.batchMat = ortho(0, 0, fau.width.float32, fau.height.float32)

    #create default camera
    fau.cam = newCam(fau.width.float32, fau.height.float32)

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

#endregion