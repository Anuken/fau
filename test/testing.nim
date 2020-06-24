import ../src/core, ../src/graphics, strformat

const vertexShader = """
attribute vec4 a_position;
attribute vec2 a_tex;

varying vec2 v_tex;

void main(){
    v_tex = a_tex;
    gl_Position = a_position;
}

"""

const fragmentShader = """
uniform sampler2D u_texture;

varying vec2 v_tex;

void main(){
	gl_FragColor = texture2D(u_texture, v_tex);
}
"""

var shader: Shader
var mesh: Mesh
var texture: Texture

proc init() =
  shader = newShader(vertexShader, fragmentShader)
  echo "compiled shader successfully."

  var vertices: seq[GLfloat] = @[
    -1.0'f32, -1.0, 0.0, 0.0, 1.0, -1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, -1.0, 1.0, 0.0, 1.0
  ]
  mesh = newMesh(@[attribPos, attribTexCoords], primitiveType = GlTriangleFan)
  mesh.vertices = vertices

  texture = loadTexture("test.png")

  echo &"loaded texture: {texture.width}x{texture.height}"
  
proc update() = 
  if tapped(keyEscape):
    quitApp()

  glClearColor(0.0, 0.0, 0.4, 1.0)
  glClear(GlColorBufferBit)
  glViewport(0.GLint, 0.GLint, screenW.GLsizei, screenH.GLsizei)
  
  #[]#
  shader.use()
  texture.use()
  shader.seti("u_texture", 0)
  mesh.render(shader)
  #echo "frame = " & $frameId & " delta = " & $deltaTime & " fps = " & $fps

#TODO remove, this is just for testing
initCore(init, update, windowTitle = "it works?")
