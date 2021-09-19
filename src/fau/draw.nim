import globals, batch, fmath, color, patch, mesh, shader, framebuffer, math, texture, lenientops, atlas, tables

## Drawing utilities based on global state.

proc blit*(buffer: Texture | Framebuffer, shader: Shader = fau.screenspace, params = meshParams()) =
  when buffer is Texture:
    let tex = buffer
  else:
    let tex = buffer.texture
  
  fau.quad.render(shader, params):
    texture = tex.sampler

template blit*(shader: Shader, params = meshParams(), body: untyped) =
  fau.quad.render(shader, params, body)

proc patch*(name: string): Patch {.inline.} = fau.atlas[name]

proc patch9*(name: string): Patch9 {.inline.} = fau.atlas.patches9.getOrDefault(name, fau.atlas.error9)

proc drawFlush*() =
  fau.batch.flush()

proc drawMat*(mat: Mat) =
  fau.batch.mat(mat)

proc drawBuffer*(buffer: Framebuffer) =
  fau.batch.buffer(buffer)

proc screenMat*() =
  drawMat(ortho(vec2(), fau.size))

#Activates a camera.
proc use*(cam: Cam) =
  cam.update()
  drawMat cam.mat

#Draws something custom at a specific Z layer
proc draw*(z: float32, value: proc(), blend = blendNormal, shader: Shader = nil) =
  fau.batch.draw(Req(kind: reqProc, draw: value, z: z, blend: blend, shader: shader))

#Custom handling of begin/end for a specific Z layer
proc drawLayer*(z: float32, layerBegin, layerEnd: proc(), spread: float32 = 1) =
  draw(z - spread, layerBegin)
  draw(z + spread, layerEnd)

proc draw*(region: Patch, pos: Vec2, size = region.size * fau.pixelScl,
  z = 0f,
  scl = vec2(1f),
  origin = size * 0.5f * scl, 
  rotation = 0f, align = daCenter,
  color = colorWhite, mixColor = colorClear, 
  blend = blendNormal, shader: Shader = nil) {.inline.} =

  let 
    alignH = (-((align and daLeft) != 0).int + ((align and daRight) != 0).int + 1) / 2
    alignV = (-((align and daBot) != 0).int + ((align and daTop) != 0).int + 1) / 2

  fau.batch.draw(Req(
    kind: reqRect,
    patch: region, 
    pos: pos - size * vec2(alignH, alignV) * scl, 
    z: z, size: size * scl, origin: origin,
    rotation: rotation, color: color, mixColor: mixColor,
    blend: blend, shader: shader
  ))

#draws a region with rotated bits
proc drawv*(region: Patch, pos: Vec2, corners: array[4, Vec2], z = 0f, size = region.size * fau.pixelScl,
  origin = size * 0.5f, rotation = 0f, align = daCenter,
  color = colorWhite, mixColor = colorClear,
  blend = blendNormal, shader: Shader = nil) =

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
    cor1 = corners[0] + vec2(x1, y1)
    cor2 = corners[1] + vec2(x2, y2)
    cor3 = corners[2] + vec2(x3, y3)
    cor4 = corners[3] + vec2(x4, y4)
    cf = color
    mf = mixColor

  fau.batch.draw(Req(
    kind: reqVert,
    tex: region.texture, 
    verts: [vert2(cor1.x, cor1.y, u, v, cf, mf), vert2(cor2.x, cor2.y, u, v2, cf, mf), vert2(cor3.x, cor3.y, u2, v2, cf, mf), vert2(cor4.x, cor4.y, u2, v, cf, mf)], 
    z: z,
    blend: blend, shader: shader
  ))

proc drawRect*(region: Patch, x, y, width, height: float32, originX = 0f, originY = 0f,
  rotation = 0f, color = colorWhite, mixColor = colorClear, z: float32 = 0.0,
  blend = blendNormal, shader: Shader = nil) {.inline.} =
  fau.batch.draw(Req(
    kind: reqRect,
    patch: region, pos: vec2(x, y), z: z, 
    size: vec2(width, height), 
    origin: vec2(originX, originY), 
    rotation: rotation, color: color, mixColor: mixColor,
    blend: blend, shader: shader
  ))

proc drawVert*(texture: Texture, vertices: array[4, Vert2], z: float32 = 0, blend = blendNormal, shader: Shader = nil) {.inline.} = 
  fau.batch.draw(Req(
    kind: reqVert,
    tex: texture, verts: vertices, z: z,
    blend: blend, shader: shader
  ))

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

proc fillQuad*(v1: Vec2, c1: Color, v2: Vec2, c2: Color, v3: Vec2, c3: Color, v4: Vec2, c4: Color, z: float32 = 0) =
  drawVert(fau.white.texture, [vert2(v1, fau.white.uv, c1), vert2(v2, fau.white.uv, c2),  vert2(v3, fau.white.uv, c3), vert2(v4, fau.white.uv, c4)], z)

proc fillQuad*(v1, v2, v3, v4: Vec2, color: Color, z: float32 = 0) =
  fillQuad(v1, color, v2, color, v3, color, v4, color, z)

proc fillRect*(x, y, w, h: float32, color = colorWhite, z: float32 = 0) =
  drawRect(fau.white, x, y, w, h, color = color, z = z)

proc fillTri*(v1, v2, v3: Vec2, color: Color, z: float32 = 0) =
  fillQuad(v1, color, v2, color, v3, color, v3, color, z)

proc fillCircle*(pos: Vec2, rad: float32, color: Color = colorWhite, z: float32 = 0) =
  draw(fau.circle, pos, size = vec2(rad*2f), color = color, z = z)

proc fillPoly*(pos: Vec2, sides: int, radius: float32, rotation = 0f, color = colorWhite, z: float32 = 0) =
  let space = PI*2 / sides.float32

  for i in countup(0, sides-1, 2):
    fillQuad(
      pos,
      pos + vec2(cos(space * (i).float32 + rotation), sin(space * (i).float32 + rotation)) * radius,
      pos + vec2(cos(space * (i + 1).float32 + rotation), sin(space * (i + 1).float32 + rotation)) * radius,
      pos + vec2(cos(space * (i + 2).float32 + rotation), sin(space * (i + 2).float32 + rotation)) * radius,
      color, z
    )
  
  let md = sides mod 2

  if md != 0 and sides >= 4:
    let i = sides - 2
    fillTri(
      pos,
      pos + vec2(cos(space * i.float32 + rotation), sin(space * i.float32 + rotation)) * radius,
      pos + vec2(cos(space * (i + 1).float32 + rotation), sin(space * (i + 1).float32 + rotation)) * radius,
      color, z
    )

proc fillLight*(pos: Vec2, radius: float32, sides = 20, centerColor = colorWhite, edgeColor = colorClear, z: float32 = 0) =
  let 
    sides = ceil(sides.float32 / 2.0).int * 2
    space = PI * 2.0 / sides.float32

  for i in countup(0, sides - 1, 2):
    fillQuad(
      pos, centerColor,
      pos + vec2(cos(space * i.float32), sin(space * i.float32)) * radius,
      edgeColor,
      pos + vec2(cos(space * (i + 1).float32), sin(space * (i + 1).float32)) * radius,
      edgeColor,
      pos + vec2(cos(space * (i + 2).float32), sin(space * (i + 2).float32)) * radius,
      edgeColor,
      z
    )

proc line*(p1, p2: Vec2, stroke: float32 = 1.px, color = colorWhite, square = true, z: float32 = 0) =
  let hstroke = stroke / 2.0
  let diff = (p2 - p1).nor * hstroke
  let side = vec2(-diff.y, diff.x)
  let 
    s1 = if square: p1 - diff else: p1
    s2 = if square: p2 + diff else: p2

  fillQuad(
    s1 + side,
    s2 + side,
    s2 - side,
    s1 - side,
    color, z
  )

#TODO bad
proc lineRect*(pos: Vec2, size: Vec2, stroke: float32 = 1.px, color = colorWhite, z: float32 = 0, margin = 0f) =
  line(pos + margin, pos + vec2(size.x - margin, margin), stroke, color, z = z)
  line(pos + vec2(size.x - margin, margin), pos + size - margin, stroke, color, z = z)
  line(pos + size - margin, pos + vec2(margin, size.y - margin), stroke, color, z = z)
  line(pos + vec2(margin, size.y - margin), pos + margin, stroke, color, z = z)

proc lineRect*(rect: Rect, stroke: float32 = 1.px, color = colorWhite, z: float32 = 0, margin = 0f) =
  lineRect(rect.pos, rect.size, stroke, color, z, margin)

proc lineSquare*(pos: Vec2, rad: float32, stroke: float32 = 1f, color = colorWhite, z = 0f) =
  lineRect(pos - rad, vec2(rad * 2f), stroke, color, z)

proc poly*(pos: Vec2, sides: int, radius: float32, rotation = 0f, stroke = 1f, color = colorWhite, z: float32 = 0) =
  let 
    space = PI*2 / sides.float32
    hstep = stroke / 2.0 / cos(space / 2.0)
    r1 = radius - hstep
    r2 = radius + hstep
  
  for i in 0..<sides:
    let 
      a = space * i.float32 + rotation
      cosf = cos(a)
      sinf = sin(a)
      cos2f = cos(a + space)
      sin2f = sin(a + space)

    fillQuad(
      pos + vec2(cosf, sinf) * r1,
      pos + vec2(cos2f, sin2f) * r1,
      pos + vec2(cos2f, sin2f) * r2,
      pos + vec2(cosf, sinf) * r2,
      color, z
    )