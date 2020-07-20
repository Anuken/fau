import common, math

var quadv: array[24, GLfloat]

for v in quadv.mitems: v = 0.0

proc fillQuad*(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4: float32) = 
  quadv[0] = x1
  quadv[1] = y1
  quadv[4] = c1

  quadv[6] = x2
  quadv[7] = y2
  quadv[10] = c2

  quadv[12] = x3
  quadv[13] = y3
  quadv[16] = c3

  quadv[18] = x4
  quadv[19] = y4
  quadv[22] = c4

  drawVert(fuse.whiteTex, quadv)

proc fillQuad*(x1, y1, x2, y2, x3, y3, x4, y4, color: float32) = 
  fillQuad(x1, y1, color, x2, y2, color, x3, y3, color, x4, y4, color)

proc line*(p1, p2: Vec2, stroke: float32 = 1.0, color: float32 = colorWhiteF, square = true) = 
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
    color
  )

proc line*(p1x, p1y, p2x, p2y, stroke: float32 = 1.0, color: float32 = colorWhiteF, square = true) {.inline.} = 
  line(vec2(p1x, p1y), vec2(p2x, p2y), stroke, color, square)


proc poly*(x, y: float32, sides: int, radius: float32, angle = 0'f32, stroke = 1'f32, color: float32 = colorWhiteF) = 
  let 
    space = PI*2 / sides.float32
    hstep = stroke / 2.0 / cos(space / 2.0)
    r1 = radius - hstep
    r2 = radius + hstep
  
  for i in 0..<sides:
    let 
      a = space * i.float32 + angle
      cosf = cos(a)
      sinf = sin(a)
      cos2f = cos(a + space)
      sin2f = sin(a + space)

    fillQuad(
      x + r1*cosf, y + r1*sinf,
      x + r1*cos2f, y + r1*sin2f,
      x + r2*cos2f, y + r2*sin2f,
      x + r2*cosf, y + r2*sinf,
      color
    )

proc poly*(pos: Vec2, sides: int, radius: float32, angle = 0'f32, stroke = 1'f32, color: float32 = colorWhiteF) = 
  poly(pos.x, pos.y, sides, radius, angle, stroke, color)