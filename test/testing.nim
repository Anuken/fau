import ../src/core, ../src/graphics, ../src/batch, polymorph, math, random

registerComponents(defaultComponentOptions):
  type
    Pos = object
      x, y: float32
    Bouncer = object
      vel: Vec2
    Render = object

const hsize = 70.0

var texture: Texture
var cam: Cam
var draw: Batch
var patch: Patch

makeSystem("bounce", [Pos, Bouncer]):
  all: 
    item.pos.x += item.bouncer.vel.x
    item.pos.y += item.bouncer.vel.y
    if item.pos.x > screenW/2.0 - hsize/2.0 or item.pos.x < -screenW/2.0 + hsize/2.0: item.bouncer.vel *= vec2(-1.0, 1.0)
    if item.pos.y > screenH/2.0 - hsize/2.0 or item.pos.y < -screenH/2.0 + hsize/2.0: item.bouncer.vel *= vec2(1.0, -1.0)

makeSystem("render", [Pos, Render]):

  init:

    cam = newCam()
    draw = newBatch()
    texture = loadTextureBytes(staticReadString("/home/anuke/Projects/fuse/test/test.png"))
    patch = texture

    randomize()

    for i in 0..1000:
      discard newEntityWith(Render(), Pos(x: rand(-500..500).float32, y: rand(-500..500).float32), Bouncer(vel: vec2(rand(-10..10).float32, rand(-10..10).float32)))

  start:
    if keyEscape.tapped: quitApp()

    clearScreen(rgba(0, 0, 0, 1))

    cam.resize(screenW, screenH)
    cam.update()

    draw.mat = cam.mat
  
  all: 
    draw.draw(patch, item.pos.x - hsize/2.0, item.pos.y - hsize/2.0, hsize, hsize)
  
  finish:
    draw.flush()

makeEcs()
commitSystems("run")
initCore(run, windowTitle = "fuse")