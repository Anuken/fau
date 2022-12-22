import globals, batch, fmath, color, patch, mesh, shader, framebuffer, math, texture, lenientops, atlas, tables, screenbuffer
export batch #for aligns

## Drawing utilities based on global state.

#renders the fullscreen mesh with u_texture set to the specified buffer
proc blit*(buffer: Texture | Framebuffer, shader: Shader = fau.screenspace, params = meshParams()) =
  fau.quad.render(shader, params):
    texture = buffer.sampler

#renders the fullscreen mesh
template blit*(shader: Shader, params = meshParams(), body: untyped) =
  fau.quad.render(shader, params, body)

proc patch*(name: string): Patch {.inline.} = fau.atlas[name]

proc patch*(name: string, notFound: string): Patch {.inline.} = fau.atlas.patches.getOrDefault(name, fau.atlas[notFound])

proc patch9*(name: string): Patch9 {.inline.} = fau.atlas.patches9.getOrDefault(name, fau.atlas.error9)

template patchConst*(name: string): Patch =
  #NIM BUG: Patch vars can't be {.global.}, they are not stored! this seems like a new bug, as https://github.com/nim-lang/Nim/issues/17552 has different conditions
  #related to putting code in start: block maybe???
  var arr {.global.}: array[4, float32]
  once:
    let res = name.patch
    arr = [res.u, res.v, res.u2, res.v2]
  Patch(u: arr[0], v: arr[1], u2: arr[2], v2: arr[3], texture: fau.atlas.texture)

proc drawFlush*() =
  fau.batch.flush()

proc drawSort*(sort: bool) =
  fau.batch.sort(sort)

proc drawMat*(mat: Mat) =
  fau.batch.mat(mat)

proc drawClip*(clipped = rect()) =
  if clipped.w.int > 0 and clipped.h.int > 0:
    #transform clipped rectangle from world into screen space
    let
      topRight = project(fau.batch.mat, clipped.topRight)
      botLeft = project(fau.batch.mat, clipped.botLeft)

    fau.batch.clip(rect(botLeft, topRight - botLeft))
  else:
    fau.batch.clip(rect())

proc drawBuffer*(buffer: Framebuffer) =
  fau.batch.buffer(buffer)

proc drawBufferScreen*() =
  fau.batch.buffer(screen)

proc screenMat*() =
  drawMat(ortho(vec2(), fau.size))

#Activates a camera.
proc use*(cam: Cam, size = cam.size, pos = cam.pos) =
  cam.update(size, pos)
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
    alignH = (-(asLeft in align).float32 + (asRight in align).float32 + 1f) / 2f
    alignV = (-(asBot in align).float32 + (asTop in align).float32 + 1f) / 2f

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
    alignH = (-(asLeft in align).float32 + (asRight in align).float32 + 1f) / 2f
    alignV = (-(asBot in align).float32 + (asTop in align).float32 + 1f) / 2f
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

proc draw*(p: Patch9, pos: Vec2, size: Vec2, z: float32 = 0f, color = colorWhite, mixColor = colorClear, scale = 1f, blend = blendNormal) =
  let
    x = pos.x
    y = pos.y
    width = size.x
    height = size.y

  #bot left
  drawRect(p.patches[0], x, y, p.left * scale, p.bot * scale, z = z, color = color, mixColor = mixColor, blend = blend)
  #bot
  drawRect(p.patches[1], x + p.left * scale, y, width - (p.right + p.left) * scale, p.bot * scale, z = z, color = color, mixColor = mixColor, blend = blend)
  #bot right
  drawRect(p.patches[2], x + p.left * scale + width - (p.right + p.left) * scale, y, p.right * scale, p.bot * scale, z = z, color = color, mixColor = mixColor, blend = blend)

  #mid left
  drawRect(p.patches[3], x, y + p.bot * scale, p.left * scale, height - (p.top + p.bot) * scale, z = z, color = color, mixColor = mixColor, blend = blend)
  #mid
  drawRect(p.patches[4], x + p.left * scale, y + p.bot * scale, width - (p.right + p.left) * scale, height - (p.top + p.bot) * scale, z = z, color = color, mixColor = mixColor, blend = blend)
  #mid right
  drawRect(p.patches[5], x + p.left * scale + width - (p.right + p.left) * scale, y + p.bot * scale, p.right * scale, height - (p.top + p.bot) * scale, z = z, color = color, mixColor = mixColor, blend = blend)

  #top left
  drawRect(p.patches[6], x, y + p.bot * scale + height - (p.top + p.bot) * scale, p.left * scale, p.top * scale, z = z, color = color, mixColor = mixColor, blend = blend)
  #top
  drawRect(p.patches[7], x + p.left * scale, y + p.bot * scale + height - (p.top + p.bot) * scale, width - (p.right + p.left) * scale, p.top * scale, z = z, color = color, mixColor = mixColor, blend = blend)
  #top right
  drawRect(p.patches[8], x + p.left * scale + width - (p.right + p.left) * scale, y + p.bot * scale + height - (p.top + p.bot) * scale, p.right * scale, p.top * scale, z = z, color = color, mixColor = mixColor, blend = blend)

proc draw*(p: Patch9, bounds: Rect, z: float32 = 0f, color = colorWhite, mixColor = colorClear, scale = 1f, blend = blendNormal) =
  draw(p, bounds.pos, bounds.size, z, color, mixColor, scale, blend = blend)

proc drawBlit*(buffer: Framebuffer, color = colorWhite, blend = blendNormal) =
  draw(buffer.texture, fau.cam.pos, fau.cam.size * vec2(1f, -1f), color = color, blend = blend)

#TODO does not support mid != 0
#TODO divs could just be a single float value, arrays unnecessary
proc drawBend*(p: Patch, pos: Vec2, divs: openArray[float32], mid = 0, rotation = 0f, z: float32 = 0f, size = p.size * fau.pixelScl, scl = vec2(1f, 1f), color = colorWhite, mixColor = colorClear) = 
  let 
    outs = size * scl
    v = p.v
    v2 = p.v2
    segSpace = outs.x / divs.len.float32

  var 
    cur = rotation
    cpos = pos

  template drawAt(i: int, sign: float32) =
    let
      mid1 = cpos
      top1 = vec2l(cur + 90f.rad, outs.y / 2f)
      top2 = vec2l(cur + 90f.rad + divs[i] * sign, outs.y / 2f)
      progress = i / (divs.len).float32 - (1f / divs.len) * -(sign < 0).float32
      u = lerp(p.u, p.u2, progress)
      u2 = lerp(p.u, p.u2, progress + 1f / divs.len * sign)
      
    cpos += vec2l(cur, segSpace) * sign

    let 
      mid2 = cpos
      p1 = mid1 + top1
      p2 = mid2 + top2
      p3 = mid2 - top2
      p4 = mid1 - top1
    
    drawVert(p.texture, [
      vert2(p1, vec2(u, v), color, mixColor),
      vert2(p2, vec2(u2, v), color, mixColor),
      vert2(p3, vec2(u2, v2), color, mixColor),
      vert2(p4, vec2(u, v2), color, mixColor)
    ], z = z)

    cur += divs[i] * sign

  for i in mid..<divs.len:
    drawAt(i, 1f)
  
  cur = rotation
  cpos = pos

  for i in countdown(mid - 1, 0):
    drawAt(i, -1f)

proc fillQuad*(v1: Vec2, c1: Color, v2: Vec2, c2: Color, v3: Vec2, c3: Color, v4: Vec2, c4: Color, z: float32 = 0) =
  drawVert(fau.white.texture, [vert2(v1, fau.white.uv, c1), vert2(v2, fau.white.uv, c2),  vert2(v3, fau.white.uv, c3), vert2(v4, fau.white.uv, c4)], z)

proc fillQuad*(v1, v2, v3, v4: Vec2, color: Color, z = 0f) =
  fillQuad(v1, color, v2, color, v3, color, v4, color, z)

proc fillRect*(x, y, w, h: float32, color = colorWhite, z = 0f) =
  drawRect(fau.white, x, y, w, h, color = color, z = z)

proc fillRect*(rect: Rect, color = colorWhite, z = 0f) =
  fillRect(rect.x, rect.y, rect.w, rect.h, color, z)

proc fillTri*(v1, v2, v3: Vec2, color: Color, z: float32 = 0) =
  fillQuad(v1, color, v2, color, v3, color, v3, color, z)

proc fillTri*(v1, v2, v3: Vec2, c1, c2, c3: Color, z: float32 = 0) =
  fillQuad(v1, c1, v2, c2, v3, c3, v3, c3, z)

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

proc lineAngle*(p: Vec2, angle, len: float32, stroke: float32 = 1.px, color = colorWhite, square = true, z = 0f) =
  line(p, p + vec2l(angle, len), stroke, color, square, z)

proc lineAngleCenter*(p: Vec2, angle, len: float32, stroke: float32 = 1.px, color = colorWhite, square = true, z = 0f) =
  let v = vec2l(angle, len)
  line(p - v/2f, p + v/2f, stroke, color, square, z)

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

proc spikes*(pos: Vec2, sides: int, radius: float32, len: float32, stroke = 1f, rotation = 0f, color = colorWhite, z = 0f) =
  for i in 0..<sides:
    let ang = i / sides * 360f.rad + rotation
    lineAngle(pos + vec2l(ang, radius), ang, len, stroke, color, z = z)

proc poly*(pos: Vec2, sides: int, radius: float32, rotation = 0f, stroke = 1f, color = colorWhite, z = 0f) =
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