import math

#utility functions

func lerp*(a, b, progress: float32): float32 {.inline.} = a + (b - a) * progress

#euclid mod functions (equivalent versions are coming in a future Nim release)
proc emod*(a, b: float32): float32 {.inline.} =
  result = a mod b
  if result >= 0: discard
  elif b > 0: result += b
  else: result -= b

proc emod*(a, b: int): int {.inline.} =
  result = a mod b
  if result >= 0: discard
  elif b > 0: result += b
  else: result -= b

{.push checks: off.}

#hashes an integer to a random positive integer
proc hashInt*(value: int): int {.inline.} =
  var x = value.uint64
  x = x xor (x shr 33)
  x *= 0xff51afd7ed558ccd'u64
  x = x xor (x shr 33)
  x *= 0xc4ceb9fe1a85ec53'u64
  x = x xor (x shr 33)
  return x.int.abs

{.pop.}

#angle/degree functions

#angle lerp
func alerp*(fromDegrees, toDegrees, progress: float32): float32 = ((fromDegrees + (((toDegrees - fromDegrees + 360 + 180) mod 360) - 180)) * progress + 360.0) mod 360

#angle dist
func adist*(a, b: float32): float32 {.inline.} = min(if a - b < 0: a - b + 360.0 else: a - b, if b - a < 0: b - a + 360.0 else: b - a)

#angle approach
func aapproach*(a, b, amount: float32): float32 =
  let 
    forw = abs(a - b)
    back = 360.0 - forw
    diff = adist(a, b)
  
  return if diff <= amount: b
  elif (a > b) == (back > forw): (a - amount).emod 360
  else: (a + amount).emod 360

func dst*(x1, y1, z1, x2, y2, z2: float32): float32 {.inline.} =
  let 
    a = x1 - x2
    b = y1 - y2
    c = z1 - z2
  return sqrt(a*a + b*b + c*c)

func dst*(x1, y1, x2, y2: float32): float32 {.inline.} =
  let 
    a = x1 - x2
    b = y1 - y2
  return sqrt(a*a + b*b)

func len*(x, y: float32): float32 {.inline.} = sqrt(x*x + y*y)
func len2*(x, y: float32): float32 {.inline.} = x*x + y*y

func sign*(x: float32): float32 {.inline.} = 
  if x < 0: -1 else: 1
func sign*(x: bool): float32 {.inline.} = 
  if x: 1 else: -1

func sin*(x, scl, mag: float32): float32 {.inline} = sin(x / scl) * mag
func cos*(x, scl, mag: float32): float32 {.inline} = cos(x / scl) * mag

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

func `lerp`*(vec: var Vec2, other: Vec2, alpha: float32) {.inline.} = 
  let invAlpha = 1.0f - alpha
  vec = vec2((vec.x * invAlpha) + (other.x * alpha), (vec.y * invAlpha) + (other.y * alpha))

func `lerp`*(vec: Vec2, other: Vec2, alpha: float32): Vec2 {.inline.} = 
  let invAlpha = 1.0f - alpha
  return vec2((vec.x * invAlpha) + (other.x * alpha), (vec.y * invAlpha) + (other.y * alpha))

#all angles are in radians
func angle*(vec: Vec2): float32 {.inline.} = 
  let res = arctan2(vec.y, vec.x)
  return if res < 0: res + PI*2.0 else: res

func angle*(vec: Vec2, other: Vec2): float32 {.inline.} = 
  let res = arctan2(other.y - vec.y, other.x - vec.x)
  return if res < 0: res + PI*2.0 else: res

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

#rectangle utility class

type Rect* = object
  x*, y*, w*, h*: float32

proc rect*(x, y, w, h: float32): Rect = Rect(x: x, y: y, w: w, h: h)
#collision stuff

proc overlaps*(a, b: Rect): bool = a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y

proc overlapDelta*(a, b: Rect): Vec2 =
  var penetration = 0f
  let 
    ax = a.x + a.w / 2
    bx = b.x + b.w / 2
    ay = a.y + a.h / 2
    by = b.y + b.h / 2
    nx = ax - bx
    ny = ay - by
    aex = a.w / 2
    bex = b.w / 2
    xoverlap = aex + bex - abs(nx)

  if abs(xoverlap) > 0:
    let 
      aey = a.h / 2
      bey = b.h / 2
      yoverlap = aey + bey - abs(ny)

    if abs(yoverlap) > 0:
      if abs(xoverlap) < abs(yoverlap):
        result.x = if nx < 0: 1 else: -1
        result.y = 0
        penetration = xoverlap
      else:
        result.x = 0
        result.y = if ny < 0: 1 else: -1
        penetration = yoverlap
      
  let 
    percent = 1.0
    slop = 0.0
    m = max(penetration - slop, 0.0)
    cx = m * result.x * percent
    cy = m * result.y * percent

  result.x = -cx
  result.y = -cy

#moves a hitbox; may be removed later
proc moveDelta*(x, y, hitW, hitH, dx, dy: float32, isx: bool, hitScan: static[int], solidity: proc(x, y: int): bool): Vec2 = 
  let
    hx = x - hitW/2
    hy = y - hitH/2
    tx = (x + 0.5).int
    ty = (y + 0.5).int
  
  var hitbox = rect(hx + dx, hy + dy, hitW, hitH)
  
  for dx in -hitScan..hitScan:
    for dy in -hitScan..hitScan:
      if solidity(dx + tx, dy + ty):
        let tilehit = rect((dx + tx).float32 - 0.5'f32, (dy + ty).float32 - 0.5'f32, 1, 1)
        if hitbox.overlaps(tilehit):
          let vec = hitbox.overlapDelta(tilehit)
          hitbox.x += vec.x
          hitbox.y += vec.y
  
  vec2(hitbox.x - hx, hitbox.y - hy)

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