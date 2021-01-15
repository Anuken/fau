import fcore, math

var quadv: array[24, GLfloat]

for v in quadv.mitems: v = 0.0

proc fillQuad*(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4: float32, z: float32 = 0) = 
  quadv[0] = x1
  quadv[1] = y1
  quadv[2] = fau.white.u
  quadv[3] = fau.white.v
  quadv[4] = c1

  quadv[6] = x2
  quadv[7] = y2
  quadv[8] = fau.white.u
  quadv[9] = fau.white.v
  quadv[10] = c2

  quadv[12] = x3
  quadv[13] = y3
  quadv[14] = fau.white.u
  quadv[15] = fau.white.v
  quadv[16] = c3

  quadv[18] = x4
  quadv[19] = y4
  quadv[20] = fau.white.u
  quadv[21] = fau.white.v
  quadv[22] = c4

  drawVert(fau.white.texture, quadv, z)

proc fillQuad*(x1, y1, x2, y2, x3, y3, x4, y4, color: float32, z: float32 = 0) = 
  fillQuad(x1, y1, color, x2, y2, color, x3, y3, color, x4, y4, color, z)

proc fillRect*(x, y, w, h: float32, color = colorWhiteF, z: float32 = 0) =
  drawRect(fau.white, x, y, w, h, color = color)

proc fillTri*(x1, y1, x2, y2, x3, y3, color: float32, z: float32 = 0) = 
  fillQuad(x1, y1, color, x2, y2, color, x3, y3, color, x3, y3, color, z)

proc fillPoly*(x, y: float32, sides: int, radius: float32, rotation = 0'f32, color: float32 = colorWhiteF, z: float32 = 0) =
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

proc fillPoly*(pos: Vec2, sides: int, radius: float32, rotation = 0'f32, color: float32 = colorWhiteF, z: float32 = 0) =
  fillPoly(pos.x, pos.y, sides, radius, rotation, color, z)

proc fillLight*(x, y, radius: float32, sides = 20, centerColor = colorWhiteF, edgeColor = colorClearF, z: float32 = 0) = 
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

proc fillLight*(pos: Vec2, radius: float32, sides = 20, centerColor = colorWhiteF, edgeColor = colorClearF, z: float32 = 0) = 
  fillLight(pos.x, pos.y, radius, sides, centerColor, edgeColor, z)

proc line*(p1, p2: Vec2, stroke: float32 = 1.0, color: float32 = colorWhiteF, square = true, z: float32 = 0) = 
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

proc line*(p1x, p1y, p2x, p2y, stroke: float32 = 1.0, color = colorWhiteF, square = true, z: float32 = 0) {.inline.} = 
  line(vec2(p1x, p1y), vec2(p2x, p2y), stroke, color, square, z)

#TODO bad
proc lineRect*(x, y, w, h: float32, stroke: float32 = 1.0, color = colorWhiteF, z: float32 = 0) =
  line(x, y, x + w, y, stroke, color, z = z)
  line(x + w, y, x + w, y + h, stroke, color, z = z)
  line(x + w, y + h, x, y + h, stroke, color, z = z)
  line(x, y + h, x, y, stroke, color, z = z)

proc poly*(x, y: float32, sides: int, radius: float32, rotation = 0'f32, stroke = 1'f32, color: float32 = colorWhiteF, z: float32 = 0) = 
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

proc poly*(pos: Vec2, sides: int, radius: float32, rotation = 0'f32, stroke = 1'f32, color: float32 = colorWhiteF, z: float32 = 0) = 
  poly(pos.x, pos.y, sides, radius, rotation, stroke, color, z = z)