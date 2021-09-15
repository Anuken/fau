#types of draw alignment for sprites
const
  daLeft* = 1
  daRight* = 2
  daTop* = 4
  daBot* = 8
  daTopLeft* = daTop or daLeft
  daTopRight* = daTop or daRight
  daBotLeft* = daBot or daLeft
  daBotRight* = daBot or daRight
  daCenter* = daLeft or daRight or daTop or daBot

proc flush(batch: Batch) =
  if batch.index == 0: return

  batch.lastTexture.use()
  fau.batchBlending.use()

  #use global shader if there is one set
  let shader = if fau.batchShader.isNil: batch.shader else: fau.batchShader

  shader.seti("u_texture", 0)
  shader.setmat4("u_proj", fau.batchMat)

  batch.mesh.updateVertices(0..<batch.index)
  batch.mesh.render(shader, 0, batch.index div 4 * 6)

  batch.index = 0

proc prepare(batch: Batch, texture: Texture) =
  if batch.lastTexture != texture or batch.index >= batch.size:
    batch.flush()
    batch.lastTexture = texture

proc drawRaw(batch: Batch, texture: Texture, vertices: array[4, Vert2], z: float32) =
  if fau.batchSort:
    batch.reqs.add(Req(kind: reqVert, tex: texture, verts: vertices, blend: fau.batchBlending, z: z))
  else:
    batch.prepare(texture)

    let
      verts = addr batch.mesh.vertices
      idx = batch.index

    #copy over the vertices
    for i in 0..<4:
      verts[i + idx] = vertices[i]

    batch.index += 4

proc drawRaw(batch: Batch, region: Patch, x, y, z, width, height, originX, originY, rotation: float32, color, mixColor: Color) =
  if fau.batchSort:
    batch.reqs.add(Req(kind: reqRect, patch: region, x: x, y: y, z: z, width: width, height: height, originX: originX, originY: originY, rotation: rotation, color: color, mixColor: mixColor, blend: fau.batchBlending))
  else:
    batch.prepare(region.texture)

    if rotation == 0.0f:
      let
        x2 = width + x
        y2 = height + y
        u = region.u
        v = region.v2
        u2 = region.u2
        v2 = region.v
        idx = batch.index
        verts = addr batch.mesh.vertices
        cf = color
        mf = mixColor

      verts.minsert(idx, [vert2(x, y, u, v, cf, mf), vert2(x, y2, u, v2, cf, mf), vert2(x2, y2, u2, v2, cf, mf), vert2(x2, y, u2, v, cf, mf)])
    else:
      let
        #bottom left and top right corner points relative to origin
        worldOriginX = x + originX
        worldOriginY = y + originY
        fx = -originX
        fy = -originY
        fx2 = width - originX
        fy2 = height - originY
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
        u = region.u
        v = region.v2
        u2 = region.u2
        v2 = region.v
        idx = batch.index
        verts = addr batch.mesh.vertices
        cf = color
        mf = mixColor

      verts.minsert(idx, [vert2(x1, y1, u, v, cf, mf), vert2(x2, y2, u, v2, cf, mf), vert2(x3, y3, u2, v2, cf, mf), vert2(x4, y4, u2, v, cf, mf)])

    batch.index += 4

proc newBatch*(size: int = 4092): Batch = 
  let batch = Batch(
    mesh: newMesh(
      vertices = newSeq[Vert2](size * 4),
      indices = newSeq[Index](size * 6)
    ),
    size: size * 4
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
  batch.shader = newShader(
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
    v_color.a = v_color.a * (255.0/254.0);
    v_mixcolor = a_mixcolor;
    v_mixcolor.a = v_mixcolor.a * (255.0/254.0);
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
    gl_FragColor = v_color * mix(c, vec4(v_mixcolor.rgb, c.a), v_mixcolor.a);
  }
  """)

  result = batch

#Flush the batched items.
proc drawFlush*() =
  if fau.batchSort:
    #sort requests by their Z value
    fau.batch.reqs.sort((a, b) => a.z.cmp b.z)
    #disable it so following reqs are not sorted again
    fau.batchSort = false

    let last = fau.batchBlending
    
    for req in fau.batch.reqs:
      if fau.batchBlending != req.blend:
        fau.batch.flush()
        req.blend.use()
        fau.batchBlending = req.blend
      
      case req.kind:
      of reqVert:
        fau.batch.drawRaw(req.tex, req.verts, 0)
      of reqRect:
        fau.batch.drawRaw(req.patch, req.x, req.y, 0.0, req.width, req.height, req.originX, req.originY, req.rotation, req.color, req.mixColor)
      of reqProc:
        req.draw()
    
    fau.batch.reqs.setLen(0)
    fau.batchSort = true
    fau.batchBlending = last

  #flush the base batch
  fau.batch.flush()

#Set a shader to be used for rendering. This flushes the batch.
proc drawShader*(shader: Shader) = 
  drawFlush()
  fau.batchShader = shader

template withShader*(shader: Shader, body: untyped) =
  shader.drawShader()
  body
  drawShader(nil)

#Sets the matrix used for rendering. This flushes the batch.
proc drawMat*(mat: Mat) = 
  drawFlush()
  fau.batchMat = mat

proc screenMat*() =
  drawMat(ortho(0f, 0f, fau.widthf, fau.heightf))

#Draws something custom at a specific Z layer
proc draw*(z: float32, value: proc()) =
  if fau.batchSort:
    fau.batch.reqs.add(Req(kind: reqProc, draw: value, z: z, blend: fau.batchBlending))
  else:
    value()

#Custom handling of begin/end for a specific Z layer
proc drawLayer*(z: float32, layerBegin, layerEnd: proc(), spread: float32 = 1) =
  draw(z - spread, layerBegin)
  draw(z + spread, layerEnd)

proc draw*(region: Patch, pos: Vec2, size = region.size * fau.pixelScl,
  z = 0f,
  scl = vec2(1f),
  origin = size * 0.5f * scl, 
  rotation = 0f, align = daCenter,
  color = colorWhite, mixColor = colorClear) {.inline.} =

  let 
    alignH = (-((align and daLeft) != 0).int + ((align and daRight) != 0).int + 1) / 2
    alignV = (-((align and daBot) != 0).int + ((align and daTop) != 0).int + 1) / 2

  fau.batch.drawRaw(region, pos.x - size.x * alignH * scl.x, pos.y - size.y * alignV * scl.y, z, size.x * scl.x, size.y * scl.y, origin.x, origin.y, rotation, color, mixColor)

#draws a region with rotated bits
proc drawv*(region: Patch, pos: Vec2, mutator: proc(pos: Vec2, idx: int): Vec2, size: Vec2 = region.size * fau.pixelScl,
  z = 0f,
  origin = size * 0.5f, rotation = 0f, align = daCenter,
  color = colorWhite, mixColor = colorClear) =
  
  let
    alignH = (-((align and daLeft) != 0).int + ((align and daRight) != 0).int + 1) / 2
    alignV = (-((align and daBot) != 0).int + ((align and daTop) != 0).int + 1) / 2
    worldOriginX: float32 = pos.x + origin.x - size.x * alignH
    worldOriginY: float32 = pos.y + origin.y - size.y * alignV
    fx: float32 = -origin.x
    fy: float32 = -origin.y
    fx2: float32 = size.x - origin.x
    fy2: float32 = size.y - origin.y
    cos: float32 = cos(rotation.degToRad)
    sin: float32 = sin(rotation.degToRad)
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
    cor1 = mutator(vec2(x1, y1), 0)
    cor2 = mutator(vec2(x2, y2), 1)
    cor3 = mutator(vec2(x3, y3), 2)
    cor4 = mutator(vec2(x4, y4), 3)
    cf = color
    mf = mixColor

  fau.batch.drawRaw(region.texture, [vert2(cor1.x, cor1.y, u, v, cf, mf), vert2(cor2.x, cor2.y, u, v2, cf, mf), vert2(cor3.x, cor3.y, u2, v2, cf, mf), vert2(cor4.x, cor4.y, u2, v, cf, mf)], z)

#draws a region with rotated bits
proc drawv*(region: Patch, pos: Vec2, c1 = vec2(0, 0), c2 = vec2(0, 0), c3 = vec2(0, 0), c4 = vec2(0, 0), z = 0f, size = region.size * fau.pixelScl,
  origin = size * 0.5f, rotation = 0f, align = daCenter,
  color = colorWhite, mixColor = colorClear) =

  let
    alignH = (-((align and daLeft) != 0).int + ((align and daRight) != 0).int + 1) / 2
    alignV = (-((align and daBot) != 0).int + ((align and daTop) != 0).int + 1) / 2
    worldOriginX: float32 = pos.x + origin.x - size.x * alignH
    worldOriginY: float32 = pos.y + origin.y - size.y * alignV
    fx: float32 = -origin.x
    fy: float32 = -origin.y
    fx2: float32 = size.x - origin.x
    fy2: float32 = size.y - origin.y
    cos: float32 = cos(rotation.degToRad)
    sin: float32 = sin(rotation.degToRad)
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
    cor1 = c1 + vec2(x1, y1)
    cor2 = c2 + vec2(x2, y2)
    cor3 = c3 + vec2(x3, y3)
    cor4 = c4 + vec2(x4, y4)
    cf = color
    mf = mixColor

  fau.batch.drawRaw(region.texture, [vert2(cor1.x, cor1.y, u, v, cf, mf), vert2(cor2.x, cor2.y, u, v2, cf, mf), vert2(cor3.x, cor3.y, u2, v2, cf, mf), vert2(cor4.x, cor4.y, u2, v, cf, mf)], z)

proc drawRect*(region: Patch, x, y, width, height: float32, originX = 0f, originY = 0f,
  rotation = 0f, color = colorWhite, mixColor = colorClear, z: float32 = 0.0) {.inline.} =
  fau.batch.drawRaw(region, x, y, z, width, height, originX, originY, rotation, color, mixColor)

proc drawVert*(texture: Texture, vertices: array[4, Vert2], z: float32 = 0) {.inline.} = 
  fau.batch.drawRaw(texture, vertices, z)

proc draw*(p: Patch9, pos: Vec2, size: Vec2, z: float32 = 0f, color = colorWhite, mixColor = colorClear, scale = 1f) =
  let
    midx = p.width - p.left - p.right
    midy = p.height - p.top - p.bot
    x = pos.x
    y = pos.y
    width = size.x
    height = size.y

  #bot left
  drawRect(p.patches[0], x, y, p.left * scale, p.bot * scale, z = z, color = color, mixColor = mixColor)
  #bot
  drawRect(p.patches[1], x + p.left * scale, y, width - (p.right + p.left) * scale, p.bot * scale, z = z, color = color, mixColor = mixColor)
  #bot right
  drawRect(p.patches[2], x + p.left * scale + width - (p.right + p.left) * scale, y, p.right * scale, p.bot * scale, z = z, color = color, mixColor = mixColor)

  #mid left
  drawRect(p.patches[3], x, y + p.bot * scale, p.left * scale, height - (p.top + p.bot) * scale, z = z, color = color, mixColor = mixColor)
  #mid
  drawRect(p.patches[4], x + p.left * scale, y + p.bot * scale, width - (p.right + p.left) * scale, height - (p.top + p.bot) * scale, z = z, color = color, mixColor = mixColor)
  #mid right
  drawRect(p.patches[5], x + p.left * scale + width - (p.right + p.left) * scale, y + p.bot * scale, p.right * scale, height - (p.top + p.bot) * scale, z = z, color = color, mixColor = mixColor)

  #top left
  drawRect(p.patches[6], x, y + p.bot * scale + height - (p.top + p.bot) * scale, p.left * scale, p.top * scale, z = z, color = color, mixColor = mixColor)
  #top
  drawRect(p.patches[7], x + p.left * scale, y + p.bot * scale + height - (p.top + p.bot) * scale, width - (p.right + p.left) * scale, p.top * scale, z = z, color = color, mixColor = mixColor)
  #top right
  drawRect(p.patches[8], x + p.left * scale + width - (p.right + p.left) * scale, y + p.bot * scale + height - (p.top + p.bot) * scale, p.right * scale, p.top * scale, z = z, color = color, mixColor = mixColor)

proc draw*(p: Patch9, bounds: Rect, z: float32 = 0f, color = colorWhite, mixColor = colorClear, scale = 1f) =
  draw(p, bounds.pos, bounds.size, z, color, mixColor, scale)

#Activates a camera.
proc use*(cam: Cam) =
  cam.update()
  drawMat cam.mat
