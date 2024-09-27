import color, mesh, texture, framebuffer, patch, shader, fmath, math, util/misc, sugar, algorithm, screenbuffer

## "Low-level" sprite batcher.

type
  Req = object
    z: float32

    case hasProc: bool:
    of true:
      callback: proc()
    of false:
      tex: Texture
      blend: Blending
      shader: Shader
      offset, len: int32

type CacheMesh = object
  mesh: Mesh2
  texture: Texture
  shader: Shader
  clip: Rect
  blend: Blending

type SpriteCache* = object
  meshes: seq[CacheMesh]

type Batch* = ref object
  mesh: Mesh2
  defaultShader: Shader
  lastShader: Shader
  lastTexture: Texture
  lastBlend: Blending
  buffer: Framebuffer
  clip, viewport: Rect
  index: int
  size: int
  requestVertices: seq[Vert2]
  req: seq[Req]
  #The projection matrix being used by the batch; requires flush
  mat: Mat
  matInv: Mat
  #Whether sorting is enabled for the batch
  sort: bool

  #caching-specific state
  caching: bool
  caches: seq[CacheMesh]

const defaultVertShader* = """
attribute vec4 a_pos;
attribute vec4 a_color;
attribute vec2 a_uv;
attribute vec4 a_mixcolor;
uniform mat4 u_proj;
varying vec4 v_color;
varying vec4 v_mixcolor;
varying vec2 v_uv;
void main(){
  v_color = a_color;
  v_mixcolor = a_mixcolor;
  v_uv = a_uv;
  gl_Position = u_proj * a_pos;
}
"""

const defaultFragShader* = """
varying lowp vec4 v_color;
varying lowp vec4 v_mixcolor;
varying vec2 v_uv;
uniform sampler2D u_texture;
void main(){
  vec4 c = texture2D(u_texture, v_uv);
  gl_FragColor = mix(v_color * c, vec4(v_mixcolor.rgb, c.a * v_color.a), v_mixcolor.a);
}
"""

proc flushInternal(batch: Batch) =
  if batch.index == 0: return

  #use global shader if there is one set
  let shader = if batch.lastShader.isNil: batch.defaultShader else: batch.lastShader

  if batch.caching:
    #add a new mesh to the cache
    batch.caches.add(CacheMesh(
      mesh: newMesh(
        vertices = batch.mesh.vertices[0..<batch.index],
        indices = batch.mesh.indices[0..<(batch.index div 4 * 6)],
        isStatic = true
      ),
      blend: batch.lastBlend,
      clip: batch.clip,
      shader: shader,
      texture: batch.lastTexture
    ))

  else:
    batch.mesh.updateVertices(0..<batch.index)
    
    batch.mesh.render(shader, meshParams(batch.buffer, 0, batch.index div 4 * 6, blend = batch.lastBlend, clip = batch.clip, viewport = batch.viewport)):
      texture = batch.lastTexture.sampler
      proj = batch.mat

  batch.index = 0

proc prepare(batch: Batch, texture: Texture, blend: Blending, shader: Shader) =
  if batch.lastTexture != texture or batch.lastBlend != blend or batch.lastShader != shader or batch.index >= batch.size:
    batch.flushInternal()
    batch.lastShader = shader
    batch.lastBlend = blend
    batch.lastTexture = texture

proc draw*(batch: Batch, z: float32, callback: proc()) =
  if batch.sort:
    batch.req.add Req(hasProc: true, z: z, callback: callback)
  else:
    callback()

proc drawVertPtr(batch: Batch, src: pointer, len: int, texture: Texture, blend: Blending, shader: Shader) {.inline.} =
  batch.prepare(texture, blend, shader)

  var 
    total = len
    point = src

  while total > 0:
    let copied = min(total, (batch.mesh.vertices.len - batch.index))

    copyMem(addr batch.mesh.vertices[batch.index], point, sizeof(Vert2) * copied)

    total -= copied
    batch.index += copied
    point = cast[pointer](cast[uint](point) + uint(copied * sizeof(Vert2)))

    if batch.index >= batch.size:
      batch.flushInternal()

proc draw*(batch: Batch, z: float32, texture: Texture, vertices: openArray[Vert2], blend: Blending, shader: Shader) =
  if texture == nil: return

  if batch.sort:
    let idx = batch.requestVertices.len
    batch.requestVertices.setLen(idx + vertices.len)
    copyMem(addr batch.requestVertices[idx], addr vertices[0], sizeof(Vert2) * vertices.len)

    if batch.req.len > 0:
      let last = batch.req[^1]
      if not last.hasProc and last.z == z and last.tex == texture and last.blend == blend and last.shader == shader:
        
        #merge last request, don't add a new one to sort.
        batch.req[^1].len += vertices.len.int32
        return
      
    batch.req.add Req(hasProc: false, z: z, tex: texture, offset: (batch.requestVertices.len - vertices.len).int32, len: vertices.len.int32, blend: blend, shader: shader)
  else:
    batch.drawVertPtr(addr vertices[0], vertices.len, texture, blend, shader)

proc draw*(batch: Batch, z: float32, patch: Patch, pos, size, origin: Vec2, rotation: float32, color, mixColor: Color, blend: Blending, shader: Shader) =
  if patch.texture == nil: return

  let vertices = if rotation == 0.0f:
    let
      x2 = size.x + pos.x
      y2 = size.y + pos.y
      u = patch.u
      v = patch.v2
      u2 = patch.u2
      v2 = patch.v
      cf = color
      mf = mixColor

    [vert2(pos.x, pos.y, u, v, cf, mf), vert2(pos.x, y2, u, v2, cf, mf), vert2(x2, y2, u2, v2, cf, mf), vert2(x2, pos.y, u2, v, cf, mf)]
  else:
    let
      #bottom left and top right corner points relative to origin
      worldOriginX = pos.x + origin.x
      worldOriginY = pos.y + origin.y
      fx = -origin.x
      fy = -origin.y
      fx2 = size.x - origin.x
      fy2 = size.y - origin.y
      #rotate
      cos = cos(rotation)
      sin = sin(rotation)
      x1 = cos * fx - sin * fy + worldOriginX
      y1 = sin * fx + cos * fy + worldOriginY
      x2 = cos * fx - sin * fy2 + worldOriginX
      y2 = sin * fx + cos * fy2 + worldOriginY
      x3 = cos * fx2 - sin * fy2 + worldOriginX
      y3 = sin * fx2 + cos * fy2 + worldOriginY
      x4 = x1 + (x3 - x2)
      y4 = y3 - (y2 - y1)
      u = patch.u
      v = patch.v2
      u2 = patch.u2
      v2 = patch.v
      
      cf = color
      mf = mixColor
    
    [vert2(x1, y1, u, v, cf, mf), vert2(x2, y2, u, v2, cf, mf), vert2(x3, y3, u2, v2, cf, mf), vert2(x4, y4, u2, v, cf, mf)]

  batch.draw(z, patch.texture, vertices, blend, shader)

proc newBatch*(size: int = 16380): Batch = 
  let batch = Batch(
    mesh: newMesh(
      vertices = newSeq[Vert2](size * 4),
      indices = newSeq[Index](size * 6),
      update = false #do not upload the vertices on the first draw call, it's redundant
    ),
    buffer: screen,
    size: size * 4,
    sort: true,
    requestVertices: newSeqOfCap[Vert2](10000)
  )

  #set up default indices
  let len = size * 6
  let indices = addr batch.mesh.indices
  var j = 0
  var i = 0
  
  while i < len:
    indices.minsert(i, [j.Index, (j+1).Index, (j+2).Index, (j+2).Index, (j+3).Index, (j).Index])
    i += 6
    j += 4
  
  batch.mesh.updateIndices()
  #create default shader
  batch.defaultShader = newShader(defaultVertShader, defaultFragShader)

  result = batch

#Flush the batched items.
proc flush*(batch: Batch) =
  if batch.sort:
    #sort requests by their Z value
    batch.req.sort((a, b) => a.z.cmp b.z)
    #disable it so following reqs are not sorted again
    batch.sort = false

    for req in batch.req:
      if req.hasProc:
        req.callback()
      else:
        batch.drawVertPtr(addr batch.requestVertices[req.offset], req.len, req.tex, req.blend, req.shader)
    
    batch.requestVertices.setLen(0)
    batch.req.setLen(0)
    batch.sort = true

  #flush the base batch
  batch.flushInternal()

proc sort*(batch: Batch, val: bool) =
  if batch.sort != val:
    batch.flush()
    batch.sort = val

proc mat*(batch: Batch): Mat {.inline.} = batch.mat
proc matInv*(batch: Batch): Mat {.inline.} = batch.matInv

#Sets the matrix used for rendering. This flushes the batch.
proc mat*(batch: Batch, mat: Mat) = 
  batch.flush()
  batch.mat = mat
  batch.matInv = mat.inv

proc clip*(batch: Batch, rect: Rect) =
  batch.flush()
  batch.clip = rect

proc viewport*(batch: Batch, rect: Rect) =
  batch.flush()
  batch.viewport = rect

#Sets the framebuffer used for rendering. This flushes the batch.
proc buffer*(batch: Batch, buffer: Framebuffer) = 
  batch.flush()
  batch.buffer = buffer

proc buffer*(batch: Batch): Framebuffer = batch.buffer

#draw a pre-cached mesh
proc draw*(batch: Batch, cache: SpriteCache) =
  if cache.meshes.len > 0:
    batch.flush()

    for mesh in cache.meshes:
      mesh.mesh.render(mesh.shader, meshParams(batch.buffer, 0, mesh.mesh.indices.len, blend = mesh.blend, clip = mesh.clip)):
        texture = mesh.texture.sampler
        proj = batch.mat

proc beginCache*(batch: Batch) =
  if not batch.caching:
    batch.flush()
    batch.caching = true

proc endCache*(batch: Batch): SpriteCache =
  batch.flush()
  batch.caching = false
  result = SpriteCache(meshes: batch.caches)
  batch.caches = @[]

#for debugging
proc len*(cache: SpriteCache): int = cache.meshes.len