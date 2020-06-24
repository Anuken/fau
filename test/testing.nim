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
  echo "compiled shader successfully."

  texture = loadTexture("/home/anuke/Projects/fuse/test/test.png")

  echo &"loaded texture: {texture.width}x{texture.height}"
  
proc update() = 
  if tapped(keyEscape):
    quitApp()

  glClearColor(0.0, 0.0, 0.4, 1.0)
  glClear(GlColorBufferBit)
  glViewport(0.GLint, 0.GLint, screenW.GLsizei, screenH.GLsizei)

  var vertices = @[
    -1.0'f32, -1.0, 0.0, 1.0, 
    1.0, -1.0, 1.0, 1.0, 
    1.0, 1.0, 1.0, 0.0, 
    -1.0, 1.0, 0.0, 0.0
  ]
  mesh = newMesh(@[attribPos, attribTexCoords], primitiveType = GlTriangleFan)
  mesh.vertices = vertices
  
  #[]#
  shader.use()
  texture.use()
  shader.seti("u_texture", 0)
  mesh.render(shader)
  #echo "frame = " & $frameId & " delta = " & $deltaTime & " fps = " & $fps

#TODO remove, this is just for testing
initCore(init, update, windowTitle = "it works?")
