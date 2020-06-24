import ../src/core, ../src/graphics, strformat

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

  texture = loadTexture("/home/anuke/Projects/fuse/test/test.png")
  
proc update() = 
  if keyEscape.tapped: quitApp()

  clearScreen(rgba(0, 0, 0, 1))
  
  texture.use()
  mesh.render(shader)

initCore(init, update, windowTitle = "it works.")
