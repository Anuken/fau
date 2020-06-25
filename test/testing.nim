import ../src/core, ../src/graphics, strformat, ../src/batch, polymorph, math

# Uses typedefs passed as components
registerComponents(defaultComponentOptions):
  type
    Pos = object
      pos: Vec2
    Spinner = object
    Bouncer = object
      vel: Vec2
    Render = object

# Create systems to act on the components

const hsize = 100.0
var texture: Texture
var cam: Cam
var draw: Batch

makeSystem("render", [Pos, Render]):
  all: 
    draw.draw(texture, item.pos.pos.x - hsize/2.0, item.pos.pos.y - hsize/2.0, hsize, hsize)

makeSystem("bounce", [Pos, Bouncer]):
  all: 
    item.pos.pos += item.velocity.vel

makeSystem("spin", [Pos, Spinner]):
  all: 
    item.pos.pos += vec2(sin(item.pos.pos.x / 20.0), sin(item.pos.pos.y / 20.0)) * 10.0

# Seal and generate ECS
makeEcs()
commitSystems("run")

let
  newEntityWith(Render(), Pos(pos: vec2(100.0, 100.0), Spinner()))
  newEntityWith(Render(), Pos(pos: vec2(600.0, 400.0), Bouncer(velocity: vec2(1.0, 1.0))))

proc init() =
  cam = newCam()
  draw = newBatch()
  texture = loadTexture("/home/anuke/Projects/fuse/test/test.png")

proc update() = 
  if keyEscape.tapped: quitApp()

  clearScreen(rgba(0, 0, 0, 1))

  cam.resize(screenW.float32, screenH.float32)
  cam.update()

  draw.mat = cam.mat

  run()

  draw.flush()

initCore(init, update, windowTitle = "it works.")

#[
var texture: Texture
var cam: Cam
var draw: Batch

proc init() =
  cam = newCam()
  draw = newBatch()
  texture = loadTexture("/home/anuke/Projects/fuse/test/test.png")
  
proc update() = 
  if keyEscape.tapped: quitApp()

  clearScreen(rgba(0, 0, 0, 1))

  cam.resize(screenW.float32, screenH.float32)
  cam.update()

  draw.mat = cam.mat

  for i in 0..5:
    const space = 50.0
    draw.color = rgba(i.float / 5.0, 1, 1, 1)
    draw.draw(texture, i.float32*space, i.float32*space, 100, 100, rotation = frameId.float32)

  draw.flush()
  
initCore(init, update, windowTitle = "it works.")
]#