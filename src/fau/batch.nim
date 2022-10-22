import color, mesh, texture, framebuffer, patch, shader, fmath, math, util/util, sugar, algorithm, screenbuffer

## "Low-level" sprite batcher.

type
  ReqKind* = enum
    reqVert,
    reqRect,
    reqProc
  Req* = object
    blend*: Blending
    shader*: Shader
    z*: float32
    case kind*: ReqKind:
    of reqVert:
      verts*: array[4, Vert2]
      tex*: Texture
    of reqRect:
      patch*: Patch
      pos*, origin*, size*: Vec2
      rotation*: float32
      color*, mixColor*: Color
    of reqProc:
      draw*: proc()

type Batch* = ref object
  mesh: Mesh2
  defaultShader: Shader
  lastShader: Shader
  lastTexture: Texture
  lastBlend: Blending
  buffer: Framebuffer
  clip: Rect
  index: int
  size: int
  req: seq[Req]
  #The projection matrix being used by the batch; requires flush
  mat: Mat
  matInv: Mat
  #Whether sorting is enabled for the batch
  sort: bool

type AlignSide* = enum
  asLeft, asRight, asTop, asBot

type Align* = set[AlignSide]

#types of draw alignment for sprites
const
  daLeft* = {asLeft}
  daRight* = {asRight}
  daTop* = {asTop}
  daBot* = {asBot}
  daTopLeft* = {asTop, asLeft}
  daTopRight* = {asTop, asRight}
  daBotLeft* = {asBot, asLeft}
  daBotRight* = {asBot, asRight}
  daCenter* = {asLeft, asRight, asTop, asBot}

proc flushInternal(batch: Batch) =
  if batch.index == 0: return

  #use global shader if there is one set
  let shader = if batch.lastShader.isNil: batch.defaultShader else: batch.lastShader

  batch.mesh.updateVertices(0..<batch.index)
  
  batch.mesh.render(shader, meshParams(batch.buffer, 0, batch.index div 4 * 6, blend = batch.lastBlend, clip = batch.clip)):
    texture = batch.lastTexture.sampler
    proj = batch.mat

  batch.index = 0

proc prepare(batch: Batch, texture: Texture) =
  if batch.lastTexture != texture or batch.index >= batch.size:
    batch.flushInternal()
    batch.lastTexture = texture

proc draw*(batch: Batch, req: Req) =
  if batch.sort:
    batch.req.add req
  else:
    if batch.lastShader != req.shader or batch.lastBlend != req.blend:
      batch.flushInternal()
      batch.lastShader = req.shader
      batch.lastBlend = req.blend

    case req.kind
    of reqVert:
      batch.prepare(req.tex)

      let
        verts = addr batch.mesh.vertices
        idx = batch.index

      #copy over the vertices
      for i in 0..<4:
        verts[i + idx] = req.verts[i]

      batch.index += 4
    of reqRect:
      batch.prepare(req.patch.texture)
      if req.rotation == 0.0f:
        let
          x2 = req.size.x + req.pos.x
          y2 = req.size.y + req.pos.y
          u = req.patch.u
          v = req.patch.v2
          u2 = req.patch.u2
          v2 = req.patch.v
          idx = batch.index
          verts = addr batch.mesh.vertices
          cf = req.color
          mf = req.mixColor

        verts.minsert(idx, [vert2(req.pos.x, req.pos.y, u, v, cf, mf), vert2(req.pos.x, y2, u, v2, cf, mf), vert2(x2, y2, u2, v2, cf, mf), vert2(x2, req.pos.y, u2, v, cf, mf)])
      else:
        let
          #bottom left and top right corner points relative to origin
          worldOriginX = req.pos.x + req.origin.x
          worldOriginY = req.pos.y + req.origin.y
          fx = -req.origin.x
          fy = -req.origin.y
          fx2 = req.size.x - req.origin.x
          fy2 = req.size.y - req.origin.y
          #rotate
          cos = cos(req.rotation)
          sin = sin(req.rotation)
          x1 = cos * fx - sin * fy + worldOriginX
          y1 = sin * fx + cos * fy + worldOriginY
          x2 = cos * fx - sin * fy2 + worldOriginX
          y2 = sin * fx + cos * fy2 + worldOriginY
          x3 = cos * fx2 - sin * fy2 + worldOriginX
          y3 = sin * fx2 + cos * fy2 + worldOriginY
          x4 = x1 + (x3 - x2)
          y4 = y3 - (y2 - y1)
          u = req.patch.u
          v = req.patch.v2
          u2 = req.patch.u2
          v2 = req.patch.v
          idx = batch.index
          verts = addr batch.mesh.vertices
          cf = req.color
          mf = req.mixColor

        verts.minsert(idx, [vert2(x1, y1, u, v, cf, mf), vert2(x2, y2, u, v2, cf, mf), vert2(x3, y3, u2, v2, cf, mf), vert2(x4, y4, u2, v, cf, mf)])

      batch.index += 4
    of reqProc:
      req.draw()

proc newBatch*(size: int = 4092): Batch = 
  let batch = Batch(
    mesh: newMesh(
      vertices = newSeq[Vert2](size * 4),
      indices = newSeq[Index](size * 6)
    ),
    buffer: screen,
    size: size * 4,
    sort: true
  )

  #set up default indices
  let len = size * 6
  let indices = addr batch.mesh.indices
  var j = 0
  var i = 0
  
  while i < len:
    indices.minsert(i, [j.GLushort, (j+1).GLushort, (j+2).GLushort, (j+2).GLushort, (j+3).GLushort, (j).GLushort])
    i += 6
    j += 4
  
  #create default shader
  batch.defaultShader = newShader(
  """
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
  """,

  """
  varying lowp vec4 v_color;
  varying lowp vec4 v_mixcolor;
  varying vec2 v_uv;
  uniform sampler2D u_texture;
  void main(){
    vec4 c = texture2D(u_texture, v_uv);
    gl_FragColor = mix(v_color * c, vec4(v_mixcolor.rgb, c.a), v_mixcolor.a);
  }
  """)

  result = batch

#Flush the batched items.
proc flush*(batch: Batch) =
  if batch.sort:
    #sort requests by their Z value
    batch.req.sort((a, b) => a.z.cmp b.z)
    #disable it so following reqs are not sorted again
    batch.sort = false

    for req in batch.req:
      batch.draw(req)
    
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

#Sets the framebuffer used for rendering. This flushes the batch.
proc buffer*(batch: Batch, buffer: Framebuffer) = 
  batch.flush()
  batch.buffer = buffer

proc buffer*(batch: Batch): Framebuffer = batch.buffer

#TODO set dest buffer