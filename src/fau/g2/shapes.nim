import math

var quadv: array[4, Vert2]

proc fillQuad*(v1: Vec2, c1: Color, v2: Vec2, c2: Color, v3: Vec2, c3: Color, v4: Vec2, c4: Color, z: float32 = 0) =
  quadv[0] = vert2(v1, fau.white.uv, c1)
  quadv[1] = vert2(v2, fau.white.uv, c2)
  quadv[2] = vert2(v3, fau.white.uv, c3)
  quadv[3] = vert2(v4, fau.white.uv, c4)

  drawVert(fau.white.texture, quadv, z)

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