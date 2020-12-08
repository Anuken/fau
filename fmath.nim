import math

#utility functions

func lerp*(a, b, progress: float32): float32 = a + (b - a) * progress

func dst*(x1, y1, z1, x2, y2, z2: float32): float32 {.inline.}  =
  let 
    a = x1 - x2
    b = y1 - y2
    c = z1 - z2
  return sqrt(a*a + b*b + c*c)

func dst*(x1, y1, x2, y2: float32): float32 {.inline.}  =
  let 
    a = x1 - x2
    b = y1 - y2
  return sqrt(a*a + b*b)

#these are probably not great style but I'm sick of casting everything manually

#converter convertf32*(i: int): float32 {.inline.} = i.float32

type Vec2* = object
  x*, y*: float32

func vec2*(x, y: float32): Vec2 {.inline.} = Vec2(x: x, y: y)

#vector-vector operations

func `-`*(vec: Vec2, other: Vec2): Vec2 {.inline.} = vec2(vec.x - other.x, vec.y - other.y)
func `-`*(vec: Vec2): Vec2 {.inline.} = vec2(-vec.x, -vec.y)
func `+`*(vec: Vec2, other: Vec2): Vec2 {.inline.} = vec2(vec.x + other.x, vec.y + other.y)
func `/`*(vec: Vec2, other: Vec2): Vec2 {.inline.} = vec2(vec.x / other.x, vec.y / other.y)
func `*`*(vec: Vec2, other: Vec2): Vec2 {.inline.} = vec2(vec.x * other.x, vec.y * other.y)

func `-=`*(vec: var Vec2, other: Vec2) {.inline.} = vec = vec2(vec.x - other.x, vec.y - other.y)
func `-=`*(vec: var Vec2, other: float32) {.inline.} = vec = vec2(vec.x - other, vec.y - other)
func `+=`*(vec: var Vec2, other: Vec2) {.inline.} = vec = vec2(vec.x + other.x, vec.y + other.y)
func `+=`*(vec: var Vec2, other: float32) {.inline.} = vec = vec2(vec.x + other, vec.y + other)
func `/=`*(vec: var Vec2, other: Vec2) {.inline.} = vec = vec2(vec.x / other.x, vec.y / other.y)
func `/=`*(vec: var Vec2, other: float32) {.inline.} = vec = vec2(vec.x / other, vec.y / other)
func `*=`*(vec: var Vec2, other: Vec2) {.inline.} = vec = vec2(vec.x * other.x, vec.y * other.y)
func `*=`*(vec: var Vec2, other: float32) {.inline.} = vec = vec2(vec.x * other, vec.y * other)

#vector-number operations

func `-`*(vec: Vec2, other: float32): Vec2 {.inline.} = vec2(vec.x - other, vec.y - other)
func `+`*(vec: Vec2, other: float32): Vec2 {.inline.} = vec2(vec.x + other, vec.y + other)
func `*`*(vec: Vec2, other: float32): Vec2 {.inline.} = vec2(vec.x * other, vec.y * other)
func `/`*(vec: Vec2, other: float32): Vec2 {.inline.} = vec2(vec.x / other, vec.y / other)

#utility methods

#all angles are in radians
func angle*(vec: Vec2): float32 {.inline.} = arctan2(vec.y, vec.x)
func angle*(vec: Vec2, other: Vec2): float32 {.inline.} = arctan2(other.y - vec.y, other.x - vec.x)

func rotate*(vec: Vec2, rads: float32): Vec2 = 
  let co = cos(rads)
  let si = sin(rads)
  return vec2(vec.x * co - vec.y * si, vec.x * si + vec.y * co)

func len*(vec: Vec2): float32 {.inline.} = sqrt(vec.x * vec.x + vec.y * vec.y)
func len2*(vec: Vec2): float32 {.inline.} = vec.x * vec.x + vec.y * vec.y
func `len=`*(vec: var Vec2, b: float32) = vec *= b / vec.len

func nor*(vec: Vec2): Vec2 {.inline.} = vec / vec.len

func lim*(vec: Vec2, limit: float32): Vec2 = 
  let l2 = vec.len2
  let limit2 = limit*limit
  return if l2 > limit2: vec * sqrt(limit2 / l2) else: vec

func dst2*(vec: Vec2, other: Vec2): float32 {.inline.} = 
  let dx = vec.x - other.x
  let dy = vec.y - other.y
  return dx * dx + dy * dy

func dst*(vec: Vec2, other: Vec2): float32 {.inline.} = sqrt(vec.dst2(other))

func within*(vec: Vec2, other: Vec2, distance: float32): bool {.inline.} = vec.dst2(other) <= distance*distance

proc `$`*(vec: Vec2): string = $vec.x & ", " & $vec.y

#3x3 matrix for 2D transformations
const 
  M00 = 0
  M01 = 3
  M02 = 6
  M10 = 1
  M11 = 4
  M12 = 7
  M20 = 2
  M21 = 5
  M22 = 8

type Mat* = object
  val*: array[9, float32]

proc newMat*(values: array[9, float32]): Mat {.inline.} = Mat(val: values)

#converts a 2D orthographics 3x3 matrix to a 4x4 matrix for shaders
proc toMat4*(matrix: Mat): array[16, float32] =
  result[4] = matrix.val[M01]
  result[1] = matrix.val[M10]

  result[0] = matrix.val[M00]
  result[5] = matrix.val[M11]
  result[10] = matrix.val[M22]
  result[12] = matrix.val[M02]
  result[13] = matrix.val[M12]
  result[15] = 1

#creates an identity matrix
proc idt*(): Mat = newMat [1'f32, 0, 0, 0, 1, 0, 0, 0, 1]

#orthographic projection matrix
proc ortho*(x, y, width, height: float32): Mat =
  let right = x + width
  let top = y + height
  let xOrth = 2 / (right - x);
  let yOrth = 2 / (top - y);
  let tx = -(right + x) / (right - x);
  let ty = -(top + y) / (top - y);

  return Mat(val: [xOrth, 0, 0, 0, yOrth, 0, tx, ty, 1])

proc `*`*(self: Mat, m: Mat): Mat =
  return newMat [
    self.val[M00] * m.val[M00] + self.val[M01] * m.val[M10] + self.val[M02] * m.val[M20], 
    self.val[M00] * m.val[M01] + self.val[M01] * m.val[M11] + self.val[M02] * m.val[M21],
    self.val[M00] * m.val[M02] + self.val[M01] * m.val[M12] + self.val[M02] * m.val[M22],

    self.val[M10] * m.val[M00] + self.val[M11] * m.val[M10] + self.val[M12] * m.val[M20],
    self.val[M10] * m.val[M01] + self.val[M11] * m.val[M11] + self.val[M12] * m.val[M21],
    self.val[M10] * m.val[M02] + self.val[M11] * m.val[M12] + self.val[M12] * m.val[M22],

    self.val[M20] * m.val[M00] + self.val[M21] * m.val[M10] + self.val[M22] * m.val[M20],
    self.val[M20] * m.val[M01] + self.val[M21] * m.val[M11] + self.val[M22] * m.val[M21],
    self.val[M20] * m.val[M02] + self.val[M21] * m.val[M12] + self.val[M22] * m.val[M22]
  ]

proc det*(self: Mat): float32 =
  return self.val[M00] * self.val[M11] * self.val[M22] + self.val[M01] * self.val[M12] * self.val[M20] + self.val[M02] * self.val[M10] * self.val[M21] -
    self.val[M00] * self.val[M12] * self.val[M21] - self.val[M01] * self.val[M10] * self.val[M22] - self.val[M02] * self.val[M11] * self.val[M20]

proc inv*(self: Mat): Mat =
  let invd = 1 / self.det()

  if invd == 0.0: raise newException(Exception, "Can't invert a singular matrix")

  return newMat [
    (self.val[M11] * self.val[M22] - self.val[M21] * self.val[M12]) * invd,
    (self.val[M20] * self.val[M12] - self.val[M10] * self.val[M22]) * invd,
    (self.val[M10] * self.val[M21] - self.val[M20] * self.val[M11]) * invd,
    (self.val[M21] * self.val[M02] - self.val[M01] * self.val[M22]) * invd,
    (self.val[M00] * self.val[M22] - self.val[M20] * self.val[M02]) * invd,
    (self.val[M20] * self.val[M01] - self.val[M00] * self.val[M21]) * invd,
    (self.val[M01] * self.val[M12] - self.val[M11] * self.val[M02]) * invd,
    (self.val[M10] * self.val[M02] - self.val[M00] * self.val[M12]) * invd,
    (self.val[M00] * self.val[M11] - self.val[M10] * self.val[M01]) * invd
  ]

proc `*`*(self: Vec2, mat: Mat): Vec2 = vec2(self.x * mat.val[0] + self.y * mat.val[3] + mat.val[6], self.x * mat.val[1] + self.y * mat.val[4] + mat.val[7])