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

  draw.draw(texture, 0, 0, 100, 100)

  draw.flush()
  
  

initCore(init, update, windowTitle = "it works.")
