import common, math

const vertexSize = 6
const spriteSize = 4 * vertexSize

type Batch* = ref object of GenericBatch
  mesh: Mesh
  shader: Shader
  lastTexture: Texture
  index: int
  size: int

proc flush(batch: Batch) =
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

proc draw(batch: Batch, texture: Texture, vertices: array[spriteSize, Glfloat]) =
  batch.prepare(texture)

  let
    verts = addr batch.mesh.vertices
    idx = batch.index

  #copy over the vertices
  for i in 0..<spriteSize:
    verts[i + idx] = vertices[i]

  batch.index += spriteSize

proc draw(batch: Batch, region: Patch, x: float32, y: float32, width: float32, height: float32, originX: float32 = 0, originY: float32 = 0, rotation: float32 = 0, color: float32 = colorWhiteF, mixColor: float32 = colorClearF) =
  batch.prepare(region.texture)

  let
    #bottom left and top right corner points relative to origin
    worldOriginX = x + originX
    worldOriginY = y + originY
    fx = -originX
    fy = -originY
    fx2 = width - originX
    fy2 = height - originY
    #rotate
    cos = cos(rotation.degToRad)
    sin = sin(rotation.degToRad)
    x1 = cos * fx - sin * fy + worldOriginX
    y1 = sin * fx + cos * fy + worldOriginY
    x2 = cos * fx - sin * fy2 + worldOriginX
    y2 = sin * fx + cos * fy2 + worldOriginY
    x3 = cos * fx2 - sin * fy2 + worldOriginX
    y3 = sin * fx2 + cos * fy2 + worldOriginY
    x4 = x1 + (x3 - x2)
    y4 = y3 - (y2 - y1)
    u = region.u
    v = region.v2
    u2 = region.u2
    v2 = region.v
    idx = batch.index
    #using pointers seems to be faster.
    verts = addr batch.mesh.vertices


  verts[idx] = x1
  verts[idx + 1] = y1
  verts[idx + 2] = u
  verts[idx + 3] = v
  verts[idx + 4] = color
  verts[idx + 5] = mixColor

  verts[idx + 6] = x2
  verts[idx + 7] = y2
  verts[idx + 8] = u
  verts[idx + 9] = v2
  verts[idx + 10] = color
  verts[idx + 11] = mixColor

  verts[idx + 12] = x3
  verts[idx + 13] = y3
  verts[idx + 14] = u2
  verts[idx + 15] = v2
  verts[idx + 16] = color
  verts[idx + 17] = mixColor

  verts[idx + 18] = x4
  verts[idx + 19] = y4
  verts[idx + 20] = u2
  verts[idx + 21] = v
  verts[idx + 22] = color
  verts[idx + 23] = mixColor

  batch.index += spriteSize

proc newBatch*(size: int = 4092): Batch = 
  let batch = Batch(
    mesh: newMesh(
      @[attribPos, attribTexCoords, attribColor, attribMixColor],
      vertices = newSeq[Glfloat](size * spriteSize),
      indices = newSeq[Glushort](size * 6)
    ),
    size: size * spriteSize
  )

  #assign procs
  batch.flushProc = proc() = 
    batch.flush()
  batch.drawProc = proc(region: Patch, x, y, width, height: float32, originX = 0'f32, originY = 0'f32, rotation = 0'f32, color = colorWhiteF, mixColor = colorClearF) = 
    batch.draw(region, x, y, width, height, originX, originY, rotation, color, mixColor)
  batch.drawVertProc = proc(texture: Texture, vertices: array[spriteSize, Glfloat]) {.nosinks.} = 
    batch.draw(texture, vertices)

  #set up default indices
  let len = size * 6
  var j = 0
  var i = 0
  
  while i < len:
    batch.mesh.indices[i] = j.GLushort
    batch.mesh.indices[i + 1] = (j+1).GLushort
    batch.mesh.indices[i + 2] = (j+2).GLushort
    batch.mesh.indices[i + 3] = (j+2).GLushort
    batch.mesh.indices[i + 4] = (j+3).GLushort
    batch.mesh.indices[i + 5] = (j).GLushort
    i += 6
    j += 4
  
  #create default shader
  batch.shader = newShader(
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
    v_color.a = v_color.a * (255.0/254.0);
    v_mixcolor = a_mixcolor;
    v_mixcolor.a = v_mixcolor.a * (255.0/254.0);
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

  result = batch