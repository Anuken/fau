import fcore, math

var quadv: array[24, GLfloat]

for v in quadv.mitems: v = 0.0

proc fillQuad*(x1, y1: float32, c1: Color, x2, y2: float32, c2: Color, x3, y3: float32, c3: Color, x4, y4: float32, c4: Color, z: float32 = 0) =
  quadv[0] = x1
  quadv[1] = y1
  quadv[2] = fau.white.u
  quadv[3] = fau.white.v
  quadv[4] = c1.f

  quadv[6] = x2
  quadv[7] = y2
  quadv[8] = fau.white.u
  quadv[9] = fau.white.v
  quadv[10] = c2.f

  quadv[12] = x3
  quadv[13] = y3
  quadv[14] = fau.white.u
  quadv[15] = fau.white.v
  quadv[16] = c3.f

  quadv[18] = x4
  quadv[19] = y4
  quadv[20] = fau.white.u
  quadv[21] = fau.white.v
  quadv[22] = c4.f

  drawVert(fau.white.texture, quadv, z)

proc fillQuad*(x1, y1, x2, y2, x3, y3, x4, y4: float32, color: Color, z: float32 = 0) =
  fillQuad(x1, y1, color, x2, y2, color, x3, y3, color, x4, y4, color, z)

proc fillRect*(x, y, w, h: float32, color = colorWhite, z: float32 = 0) =
  drawRect(fau.white, x, y, w, h, color = color, z = z)

proc fillTri*(x1, y1, x2, y2, x3, y3: float32, color: Color, z: float32 = 0) =
  fillQuad(x1, y1, color, x2, y2, color, x3, y3, color, x3, y3, color, z)

proc fillCircle*(x, y, rad: float32, color: Color = colorWhite, z: float32 = 0) =
  draw(fau.circle, x, y, width = rad*2.0, height = rad*2.0, color = color, z = z)

proc fillPoly*(x, y: float32, sides: int, radius: float32, rotation = 0f, color = colorWhite, z: float32 = 0) =
  let space = PI*2 / sides.float32

  for i in countup(0, sides-1, 2):
    fillQuad(
      x,
      y,
      x + cos(space * (i).float32 + rotation) * radius,
      y + sin(space * (i).float32 + rotation) * radius,
      x + cos(space * (i + 1).float32 + rotation) * radius,
      y + sin(space * (i + 1).float32 + rotation) * radius,
      x + cos(space * (i + 2).float32 + rotation) * radius,
      y + sin(space * (i + 2).float32 + rotation) * radius,
      color, z
    )
  
  let md = sides mod 2

  if md != 0 and sides >= 4:
    let i = sides - 2
    fillTri(
      x, y,
      x + cos(space * i.float32 + rotation) * radius,
      y + sin(space * i.float32 + rotation) * radius,
      x + cos(space * (i + 1).float32 + rotation) * radius,
      y + sin(space * (i + 1).float32 + rotation) * radius,
      color, z
    )

proc fillPoly*(pos: Vec2, sides: int, radius: float32, rotation = 0f, color = colorWhite, z: float32 = 0) =
  fillPoly(pos.x, pos.y, sides, radius, rotation, color, z)

proc fillLight*(x, y, radius: float32, sides = 20, centerColor = colorWhite, edgeColor = colorClear, z: float32 = 0) =
  let 
    sides = ceil(sides.float32 / 2.0).int * 2
    space = PI * 2.0 / sides.float32

  for i in countup(0, sides - 1, 2):
    fillQuad(
      x, y, centerColor,
      x + cos(space * i.float32) * radius,
      y + sin(space * i.float32) * radius,
      edgeColor,
      x + cos(space * (i + 1).float32) * radius,
      y + sin(space * (i + 1).float32) * radius,
      edgeColor,
      x + cos(space * (i + 2).float32) * radius,
      y + sin(space * (i + 2).float32) * radius,
      edgeColor,
      z
    )

proc fillLight*(pos: Vec2, radius: float32, sides = 20, centerColor = colorWhite, edgeColor = colorClear, z: float32 = 0) =
  fillLight(pos.x, pos.y, radius, sides, centerColor, edgeColor, z)

proc line*(p1, p2: Vec2, stroke: float32 = 1.px, color = colorWhite, square = true, z: float32 = 0) =
  let hstroke = stroke / 2.0
  let diff = (p2 - p1).nor * hstroke
  let side = vec2(-diff.y, diff.x)
  let 
    s1 = if square: p1 - diff else: p1
    s2 = if square: p2 + diff else: p2

  fillQuad(
    s1.x + side.x,
    s1.y + side.y,

    s2.x + side.x,
    s2.y + side.y,

    s2.x - side.x,
    s2.y - side.y,

    s1.x - side.x,
    s1.y - side.y,
    color, z
  )

proc line*(p1x, p1y, p2x, p2y, stroke: float32 = 1.px, color = colorWhite, square = true, z: float32 = 0) {.inline.} =
  line(vec2(p1x, p1y), vec2(p2x, p2y), stroke, color, square, z)

#TODO bad
proc lineRect*(x, y, w, h: float32, stroke: float32 = 1.px, color = colorWhite, z: float32 = 0, margin = 0f) =
  line(x + margin, y + margin, x + w - margin, y + margin, stroke, color, z = z)
  line(x + w - margin, y + margin, x + w - margin, y + h - margin, stroke, color, z = z)
  line(x + w - margin, y + h - margin, x + margin, y + h - margin, stroke, color, z = z)
  line(x + margin, y + h - margin, x + margin, y + margin, stroke, color, z = z)

proc lineSquare*(x, y, rad: float32, stroke: float32 = 1f, color = colorWhite, z = 0f) =
  lineRect(x - rad, y - rad, rad * 2f, rad * 2f, stroke, color, z)

proc poly*(x, y: float32, sides: int, radius: float32, rotation = 0f, stroke = 1f, color = colorWhite, z: float32 = 0) =
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
      x + r1*cosf, y + r1*sinf,
      x + r1*cos2f, y + r1*sin2f,
      x + r2*cos2f, y + r2*sin2f,
      x + r2*cosf, y + r2*sinf,
      color, z
    )

proc poly*(pos: Vec2, sides: int, radius: float32, rotation = 0f, stroke = 1f, color = colorWhite, z: float32 = 0) =
  poly(pos.x, pos.y, sides, radius, rotation, stroke, color, z = z)