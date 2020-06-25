import ../src/core, ../src/graphics, strformat, ../src/batch

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
