import ../src/core, ../src/graphics, strformat, ../src/batch

const vertexShader = """
attribute vec4 a_position;
attribute vec2 a_texc;
varying vec2 v_texc;
void main(){
    v_texc = a_texc;
    gl_Position = a_position;
}
"""

const fragmentShader = """
uniform sampler2D u_texture;
varying vec2 v_texc;
void main(){
	gl_FragColor = texture2D(u_texture, v_texc);
}
"""

var shader: Shader
var mesh: Mesh
var texture: Texture
var cam: Cam
var draw: Batch

proc init() =
  shader = newShader(vertexShader, fragmentShader)

  var vertices = @[
    -1.0'f32, -1.0, 0.0, 1.0, 
    1.0, -1.0, 1.0, 1.0, 
    1.0, 1.0, 1.0, 0.0, 
    -1.0, 1.0, 0.0, 0.0
  ]
  mesh = newMesh(@[attribPos, attribTexCoords], primitiveType = GlTriangleFan)
  mesh.vertices = vertices

  cam = newCam()
  draw = newBatch()
  texture = loadTexture("/home/anuke/Projects/fuse/test/test.png")
  
proc update() = 
  if keyEscape.tapped: quitApp()

  clearScreen(rgba(0, 0, 0, 1))

  cam.resize(screenW.float32, screenH.float32)
  cam.update()

  #draw.mat = cam.mat

  #draw.draw(texture, 0, 0, 100, 100)

  #draw.flush()
  
  

initCore(init, update, windowTitle = "it works.")
