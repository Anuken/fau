import math, random

#this should be avoided in most cases, but manually turning ints into float32s can be very annoying
converter toFloat32*(i: int): float32 {.inline.} = i.float32

#TODO angle type, distinct float32
#TODO make all angle functions use this
#type Radians = distinct float32
#template deg*(v: float32) = (v * PI / 180.0).Radians
#template rad*(v: float32) = v.Radians
#converter toFloat(r: Radians): float32 {.inline.} = r.float32

## any type that has a time and lifetime
type Timeable* = concept t
  t.time is float32
  t.lifetime is float32

type AnyVec2* = concept t
  t.x is float32
  t.y is float32

iterator d4*(): tuple[x, y: int] =
  yield (1, 0)
  yield (0, 1)
  yield (-1, 0)
  yield (0, -1)

iterator d4i*(): tuple[x, y, i: int] =
  yield (1, 0, 0)
  yield (0, 1, 1)
  yield (-1, 0, 2)
  yield (0, -1, 3)

iterator signs*(): float32 =
  yield 1f
  yield -1f

## fade in from 0 to 1
func fin*(t: Timeable): float32 {.inline.} = t.time / t.lifetime

## any type that can fade in linearly
type Scaleable* = concept s
  s.fin() is float32

## fade in from 1 to 0
func fout*(t: Scaleable): float32 {.inline.} = 1.0f - t.fin

## fade in from 0 to 1 to 0
func fouts*(t: Scaleable): float32 {.inline.} = 2.0 * abs(t.fin - 0.5)

## fade in from 1 to 0 to 1
func fins*(t: Scaleable): float32 {.inline.} = 1.0 - t.fouts

func powout*(a, power: float32): float32 {.inline.} = pow(a - 1, power) * (if power mod 2 == 0: -1 else: 1) + 1

#utility functions

func zero*(val: float32, margin: float32 = 0.0001f): bool {.inline.} = abs(val) <= margin
func clamp*(val: float32): float32 {.inline.} = clamp(val, 0f, 1f)

func lerp*(a, b, progress: float32): float32 {.inline.} = a + (b - a) * progress
func lerpc*(a, b, progress: float32): float32 {.inline.} = a + (b - a) * clamp(progress)

func inv*(f: float32): float32 {.inline.} = 1f / f

## euclid mod functions (equivalent versions are coming in a future Nim release)
func emod*(a, b: float32): float32 {.inline.} =
  result = a mod b
  if result >= 0: discard
  elif b > 0: result += b
  else: result -= b

func emod*(a, b: int): int {.inline.} =
  result = a mod b
  if result >= 0: discard
  elif b > 0: result += b
  else: result -= b

{.push checks: off.}

## hashes an integer to a random positive integer
func hashInt*(value: int): int {.inline.} =
  var x = value.uint64
  x = x xor (x shr 33)
  x *= 0xff51afd7ed558ccd'u64
  x = x xor (x shr 33)
  x *= 0xc4ceb9fe1a85ec53'u64
  x = x xor (x shr 33)
  return x.int.abs

proc chance*(c: float): bool = rand(0.0..1.0) < c

{.pop.}

#angle/degree functions; all are in radians

const pi2* = PI * 2.0

func rad*(val: float32): float32 {.inline.} = val * PI / 180.0
func deg*(val: float32): float32 {.inline.} = val / (PI / 180.0)

## angle lerp
func alerp*(fromDegrees, toDegrees, progress: float32): float32 = ((fromDegrees + (((toDegrees - fromDegrees + 360.rad + 180.rad) mod 360.rad) - 180.rad)) * progress + 360.0.rad) mod 360.rad

## angle dist
func adist*(a, b: float32): float32 {.inline.} = min(if a - b < 0: a - b + 360.0.rad else: a - b, if b - a < 0: b - a + 360.0.rad else: b - a)

## angle within other angle
func awithin*(a, b: float32, tolerance = 0.01f): bool {.inline.} = adist(a, b) <= tolerance

## angle approach
func aapproach*(a, b, amount: float32): float32 =
  let 
    forw = abs(a - b)
    back = 360.0.rad - forw
    diff = adist(a, b)
  
  return if diff <= amount: b
  elif (a > b) == (back > forw): (a - amount).emod 360.rad
  else: (a + amount).emod 360.rad

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
func signi*(x: bool): int {.inline.} = 
  if x: 1 else: -1

func sin*(x, scl, mag: float32): float32 {.inline} = sin(x / scl) * mag
func cos*(x, scl, mag: float32): float32 {.inline} = cos(x / scl) * mag

func absin*(x, scl, mag: float32): float32 {.inline} = (sin(x / scl) * mag).abs
func abcos*(x, scl, mag: float32): float32 {.inline} = (cos(x / scl) * mag).abs

type Vec2i* = object
  x*, y*: int

type Vec2* = object
  x*, y*: float32

func vec2*(x, y: float32): Vec2 {.inline.} = Vec2(x: x, y: y)
func vec2*(xy: float32): Vec2 {.inline} = Vec2(x: xy, y: xy)
proc vec2*(pos: AnyVec2): Vec2 {.inline.} = Vec2(x: pos.x, y: pos.y)
func vec2l*(angle, mag: float32): Vec2 {.inline.} = vec2(mag * cos(angle), mag * sin(angle))

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

#vec2i stuff

func vec2i*(x, y: int): Vec2i {.inline.} = Vec2i(x: x, y: y)
func vec2*(v: Vec2i): Vec2 {.inline.} = vec2(v.x.float32, v.y.float32)

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

func angle*(x, y: float32): float32 {.inline.} =
  let res = arctan2(y, x)
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

proc inside*(x, y, w, h: int): bool {.inline.} = x >= 0 and y >= 0 and x < w and y < h
proc inside*(p: Vec2i, w, h: int): bool {.inline.} = p.x >= 0 and p.y >= 0 and p.x < w and p.y < h

#Implementation of bresenham's line algorithm; iterates through a line connecting the two points.
iterator line*(p1, p2: Vec2i): Vec2i =
  let 
    dx = abs(p2.x - p1.x)
    dy = abs(p2.y - p1.y)
    sx = if p1.x < p2.x: 1 else: -1
    sy = if p1.y < p2.y: 1 else: -1

  var
    startX = p1.x
    startY = p1.y

    err = dx - dy
    e2 = 0
  
  while true:
    yield vec2i(startX, startY)
    if startX == p2.x and startY == p2.y: break
    e2 = 2 * err
    if e2 > -dy:
      err -= dy
      startX += sx
    
    if e2 < dx:
      err += dx
      startY += sy
      
#rectangle utility class

type Rect* = object
  x*, y*, w*, h*: float32

proc rect*(x, y, w, h: float32): Rect {.inline.} = Rect(x: x, y: y, w: w, h: h)
proc rectCenter*(x, y, w, h: float32): Rect {.inline.} = Rect(x: x - w/2.0, y: y - h/2.0, w: w, h: h)
proc rectCenter*(x, y, s: float32): Rect {.inline.} = Rect(x: x - s/2.0, y: y - s/2.0, w: s, h: s)

proc top*(r: Rect): float32 {.inline.} = r.y + r.h
proc right*(r: Rect): float32 {.inline.} = r.x + r.w

proc centerX*(r: Rect): float32 {.inline.} = r.x + r.w/2.0
proc centerY*(r: Rect): float32 {.inline.} = r.y + r.h/2.0
proc center*(r: Rect): Vec2 {.inline.} = vec2(r.x + r.w/2.0, r.y + r.h/2.0)

proc merge*(r: Rect, other: Rect): Rect =
  result.x = min(r.x, other.x)
  result.y = min(r.y, other.y)
  result.w = max(r.right, other.right) - result.x
  result.h = max(r.top, other.top) - result.h

#collision stuff

proc contains*(r: Rect, x, y: float32): bool {.inline.} = r.x <= x and r.x + r.w >= x and r.y <= y and r.y + r.h >= y
proc contains*(r: Rect, pos: Vec2): bool {.inline.} = r.contains(pos.x, pos.y)

proc overlaps*(a, b: Rect): bool = a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y

proc overlaps(r1: Rect, v1: Vec2, r2: Rect, v2: Vec2, hitPos: var Vec2): bool =
  let vel = v1 - v2

  var invEntry, invExit: Vec2

  if vel.x > 0.0:
    invEntry.x = r2.x - (r1.x + r1.w)
    invExit.x = (r2.x + r2.w) - r1.x
  else:
    invEntry.x = (r2.x + r2.w) - r1.x
    invExit.x = r2.x - (r1.x + r1.w)

  if vel.y > 0.0:
    invEntry.y = r2.y - (r1.y + r1.h)
    invExit.y = (r2.y + r2.h) - r1.y
  else:
    invEntry.y = (r2.y + r2.h) - r1.y
    invExit.y = r2.y - (r1.y + r1.h)

  let 
    entry = invEntry / vel
    exit = invExit / vel
    entryTime = max(entry.x, entry.y)
    exitTime = min(exit.x, exit.y)

  if entryTime > exitTime or exit.x < 0.0 or exit.y < 0.0 or entry.x > 1.0 or entry.y > 1.0:
    return false
  else:
    hitPos = vec2(r1.x + r1.w / 2f + v1.x * entryTime, r1.y + r1.h / 2f + v1.y * entryTime)
    return true

proc penetrationX*(a, b: Rect): float32 {.inline.} =
  let nx = a.centerX - b.centerX
  result = a.w / 2 + b.w / 2 - abs(nx) + 0.000001
  if nx < 0: result = -result

proc penetrationY*(a, b: Rect): float32 {.inline.} =
  let ny = a.centerY - b.centerY
  result = a.h / 2 + b.h / 2 - abs(ny) + 0.000001
  if ny < 0: result = -result

proc penetration*(a, b: Rect): Vec2 = vec2(penetrationX(a, b), penetrationY(a, b))

#moves a hitbox; may be removed later
proc moveDelta*(box: Rect, vx, vy: float32, solidity: proc(x, y: int): bool): Vec2 = 
  let
    left = (box.x + 0.5).int - 1
    bottom = (box.y + 0.5).int - 1
    right = (box.x + 0.5 + box.w).int + 1
    top = (box.y + 0.5 + box.h).int + 1
  
  var hitbox = box
  
  hitbox.x += vx

  for dx in left..right:
    for dy in bottom..top:
      if solidity(dx, dy):
        let tile = rect((dx).float32 - 0.5f, (dy).float32 - 0.5f, 1, 1)
        if hitbox.overlaps(tile):
          hitbox.x -= tile.penetrationX(hitbox)
  
  hitbox.y += vy

  for dx in left..right:
    for dy in bottom..top:
      if solidity(dx, dy):
        let tile = rect((dx).float32 - 0.5f, (dy).float32 - 0.5f, 1, 1)
        if hitbox.overlaps(tile):
          hitbox.y -= tile.penetrationY(hitbox)
  
  return vec2(hitbox.x - box.x, hitbox.y - box.y)

#returns true if the hitbox hits any tiles
proc collidesTiles*(box: Rect, solidity: proc(x, y: int): bool): bool = 
  let
    left = (box.x + 0.5).int - 1
    bottom = (box.y + 0.5).int - 1
    right = (box.x + 0.5 + box.w).int + 1
    top = (box.y + 0.5 + box.h).int + 1

  for dx in left..right:
    for dy in bottom..top:
      if solidity(dx, dy):
        let tile = rect((dx).float32 - 0.5f, (dy).float32 - 0.5f, 1, 1)
        if box.overlaps(tile):
          return true
  
  return false


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
proc idt*(): Mat = newMat [1f, 0, 0, 0, 1, 0, 0, 0, 1]

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

#PARTICLES

## Stateless particles based on RNG. x/y are injected into template body.
template particles*(seed: int, amount: int, cx, cy, rad: float32, body: untyped) =
  var r = initRand(seed)
  for i in 0..amount:
    let 
      v = vec2l(r.rand(360.0).float32, r.rand(1.0).float32 * rad)
      x {.inject.} = cx + v.x
      y {.inject.} = cy + v.y
    body

template circle*(amount: int, body: untyped) =
  for i in 0..<amount:
    let angle {.inject.} = (i.float32 / amount.float32 * 360f).degToRad
    body

template circlev*(amount: int, len: float32, body: untyped) =
  for i in 0..<amount:
    let
      angle {.inject.} = (i.float32 / amount.float32 * 360f).degToRad
      v = vec2l(angle, len)
      x {.inject.} = v.x
      y {.inject.} = v.y
    body

template shotgun*(amount: int, spacing: float32, body: untyped) =
  for i in 0..<amount:
    let angle {.inject.} = ((i - (amount div 2).float32) * spacing).degToRad
    body