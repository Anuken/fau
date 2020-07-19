import common, math

const vertexSize = 6
const spriteSize = 4 * vertexSize

type Batch* = ref object
  mesh: Mesh
  shader: Shader
  lastTexture: Texture
  index: int
  size: int
  
proc newBatch*(size: int = 4092): Batch = 
  result = Batch(
    mesh: newMesh(
      @[attribPos, attribTexCoords, attribColor, attribMixColor],
      vertices = newSeq[Glfloat](size * spriteSize),
      indices = newSeq[Glushort](size * 6)
    ),
    size: size * spriteSize
  )

  #set up default indices
  let len = size * 6
  var j = 0
  var i = 0
  
  while i < len:
    result.mesh.indices[i] = j.GLushort
    result.mesh.indices[i + 1] = (j+1).GLushort
    result.mesh.indices[i + 2] = (j+2).GLushort
    result.mesh.indices[i + 3] = (j+2).GLushort
    result.mesh.indices[i + 4] = (j+3).GLushort
    result.mesh.indices[i + 5] = (j).GLushort
    i += 6
    j += 4
  
  #create default shader
  result.shader = newShader(
  """
  attribute vec4 a_position;
  attribute vec4 a_color;
  attribute vec2 a_texc;
  attribute vec4 a_mixcolor;
  uniform mat4 u_proj;
  varying vec4 v_color;
  varying vec4 v_mixcolor;
  varying vec2 v_texc;
  void main(){
    v_color = a_color;
    v_mixcolor = a_mixcolor;
    v_texc = a_texc;
    gl_Position = u_proj * a_position;
  }
  """,

  """
  varying lowp vec4 v_color;
  varying lowp vec4 v_mixcolor;
  varying vec2 v_texc;
  uniform sampler2D u_texture;
  void main(){
    vec4 c = texture2D(u_texture, v_texc);
    gl_FragColor = v_color * mix(c, vec4(v_mixcolor.rgb, c.a), v_mixcolor.a);
  }
  """)

proc flush*(batch: Batch) =
  if batch.index == 0: return

  batch.lastTexture.use()
  fuse.batchBlending.use()

  #use global shader if there is one set
  let shader = if fuse.batchShader.isNil: batch.shader else: fuse.batchShader

  shader.seti("u_texture", 0)
  shader.setmat4("u_proj", fuse.batchMat)

  batch.mesh.updateVertices()
  batch.mesh.render(batch.shader, batch.index div spriteSize * 6)
  
  batch.index = 0

proc prepare(batch: Batch, texture: Texture) =
  if batch.lastTexture != texture or batch.index >= batch.size:
    batch.flush()
    batch.lastTexture = texture

proc draw(batch: Batch, region: Patch, x: float32, y: float32, width: float32, height: float32, originX: float32 = 0, originY: float32 = 0, rotation: float32 = 0, color: uint32 = colorWhiteInt, mixColor: uint32 = colorClearInt) =
  batch.prepare(region.texture)

  #bottom left and top right corner points relative to origin
  let worldOriginX = x + originX
  let worldOriginY = y + originY
  let fx = -originX
  let fy = -originY
  let fx2 = width - originX
  let fy2 = height - originY

  #rotate
  let cos = cos(rotation.degToRad)
  let sin = sin(rotation.degToRad)

  let x1 = cos * fx - sin * fy + worldOriginX
  let y1 = sin * fx + cos * fy + worldOriginY
  let x2 = cos * fx - sin * fy2 + worldOriginX
  let y2 = sin * fx + cos * fy2 + worldOriginY
  let x3 = cos * fx2 - sin * fy2 + worldOriginX
  let y3 = sin * fx2 + cos * fy2 + worldOriginY
  let x4 = x1 + (x3 - x2)
  let y4 = y3 - (y2 - y1)

  let u = region.u
  let v = region.v2
  let u2 = region.u2
  let v2 = region.v

  let cc = cast[float32](color)
  let mc = cast[float32](mixColor)
  let idx = batch.index
  
  #using pointers seems to be faster.
  let verts = addr batch.mesh.vertices

  verts[idx] = x1
  verts[idx + 1] = y1
  verts[idx + 2] = u
  verts[idx + 3] = v
  verts[idx + 4] = cc
  verts[idx + 5] = mc

  verts[idx + 6] = x2
  verts[idx + 7] = y2
  verts[idx + 8] = u
  verts[idx + 9] = v2
  verts[idx + 10] = cc
  verts[idx + 11] = mc

  verts[idx + 12] = x3
  verts[idx + 13] = y3
  verts[idx + 14] = u2
  verts[idx + 15] = v2
  verts[idx + 16] = cc
  verts[idx + 17] = mc

  verts[idx + 18] = x4
  verts[idx + 19] = y4
  verts[idx + 20] = u2
  verts[idx + 21] = v
  verts[idx + 22] = cc
  verts[idx + 23] = mc

  batch.index += spriteSize

proc use*(batch: Batch) =
  fuse.batchFlush = proc() = batch.flush()
  fuse.batchDraw = proc(region: Patch, x: float32, y: float32, width: float32, height: float32, originX: float32 = 0, originY: float32 = 0, rotation: float32 = 0, color: uint32 = colorWhiteInt, mixColor: uint32 = colorClearInt) = 
    batch.draw(region, x, y, width, height, originX, originY, rotation)