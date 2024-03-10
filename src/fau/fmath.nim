import math, random

#this should be avoided in most cases, but manually turning ints into float32s can be very annoying
converter toFloat32*(i: int): float32 {.inline.} = i.float32

#TODO angle type, distinct float32
#TODO make all angle functions use this
#type Radians = distinct float32
#template deg*(v: float32) = (v * PI / 180.0).Radians
#template rad*(v: float32) = v.Radians
#converter toFloat(r: Radians): float32 {.inline.} = r.float32

type AlignSide* = enum
  asLeft, asRight, asTop, asBot

type Align* = set[AlignSide]

#types of draw alignment for sprites
const
  daLeft* = {asLeft}
  daRight* = {asRight}
  daTop* = {asTop}
  daBot* = {asBot}
  daTopLeft* = {asTop, asLeft}
  daTopRight* = {asTop, asRight}
  daBotLeft* = {asBot, asLeft}
  daBotRight* = {asBot, asRight}
  daCenter* = {asLeft, asRight, asTop, asBot}

## any type that has a time and lifetime
type Timeable* = concept t
  t.time is float32
  t.lifetime is float32

type AnyVec2* = concept t
  t.x is float32
  t.y is float32

type AnyVec2i* = concept t
  t.x is int
  t.y is int

## any type that can fade in linearly
type Scaleable* = concept s
  s.fin() is float32

type Vec2i* = object
  x*, y*: int

type Vec2* = object
  x*, y*: float32

#doesn't really belong here, but I need it for shaders.
type Vec3* = object
  x*, y*, z*: float32

#used for dynamically updating springy things
type Spring* = object
  value*, target*, velocity*: float32
  damping*, frequency*: float32

#TODO xywh can be vec2s, maybe?
type Rect* = object
  x*, y*, w*, h*: float32

#3x3 matrix for 2D transformations
type Mat* = array[9, float32]

#basic camera
type Cam* = ref object
  #world position
  pos*: Vec2
  #viewport size
  size*: Vec2
  #target bounds for screen, used for mouse projection
  screenBounds*: Rect
  #projection and inverse projection matrix
  mat*, inv*: Mat

iterator signs*(): float32 =
  yield 1f
  yield -1f

iterator signsi*(): int =
  yield 1
  yield -1

## fade in from 0 to 1
func fin*(t: Timeable): float32 {.inline.} = t.time / t.lifetime

## fade in from 1 to 0
func fout*(t: Scaleable): float32 {.inline.} = 1.0f - t.fin

## fade in from 0 to 1 to 0
func fouts*(t: Scaleable): float32 {.inline.} = 2.0 * abs(t.fin - 0.5)

## fade in from 1 to 0 to 1
func fins*(t: Scaleable): float32 {.inline.} = 1.0 - t.fouts

func powout*(a, power: float32): float32 {.inline.} = 
  result = -pow(abs(a - 1), power) + 1
  if isNan(result): result = 0f

func elasticDouble*(alpha: float32, value = 2f, power = 10f, scale = 1f, bounceCount = 7): float32 =
  var a = alpha
  let bounces = bounceCount * PI * (if bounceCount mod 2 == 0: 1f else: -1f)

  if a <= 0.5f:
    a *= 2
    return pow(value, power * (a - 1f)) * sin(a * bounces.float32) * scale / 2;
  
  a = 1f - a
  a *= 2f;
  return 1f - pow(value, power * (a - 1f)) * sin((a) * bounces.float32) * scale / 2;

func elasticIn*(alpha: float32, value = 2f, power = 10f, scale = 1f, bounceCount = 6): float32 =
  let bounces = bounceCount * PI * (if bounceCount mod 2 == 0: 1f else: -1f)

  if alpha >= 0.99f: return 1f
  return pow(value, power * (alpha - 1)) * sin(alpha * bounces.float32) * scale;

func elasticOut*(alpha: float32, value = 2f, power = 10f, scale = 1f, bounceCount = 7): float32 =
  var a = alpha
  let bounces = bounceCount * PI * (if bounceCount mod 2 == 0: 1f else: -1f)
  if a == 0f: return 0f
  a = 1f - a
  return (1f - pow(value, power * (a - 1f)) * sin(a * bounces.float32) * scale);

#spring

func spring*(damping = 0.1f, frequency = 4f, value = 0f, target = 0f): Spring = 
  Spring(damping: damping, frequency: frequency, value: value, target: target)

proc update*(spring: var Spring, delta: float32) =
  ## update spring state

  var angularFrequency = spring.frequency
  angularFrequency *= PI * 2f

  var f = 1.0f + 2.0f * delta * spring.damping * angularFrequency
  var oo = angularFrequency * angularFrequency
  var hoo = delta * oo
  var hhoo = delta * hoo
  var detInv = 1.0f / (f + hhoo)
  var detX = f * spring.value + delta * spring.velocity + hhoo * spring.target
  var detV = spring.velocity + hoo * (spring.target - spring.value)
  spring.value = detX * detInv
  spring.velocity = detV * detInv

#utility functions

func zero*(val: float32, margin: float32 = 0.0001f): bool {.inline.} = abs(val) <= margin
func clamp*(val: float32): float32 {.inline.} = clamp(val, 0f, 1f)

func lerp*(a, b, progress: float32): float32 {.inline.} = a + (b - a) * progress
func approach*(a, b, progress: float32): float32 {.inline.} = a + (b - a).clamp(-progress, progress)

func lerp*(a: var float32; b, progress: float32) {.inline.} = a += (b - a) * progress
func approach*(a: var float32; b, progress: float32) {.inline.} = a += (b - a).clamp(-progress, progress)

func slope*(value: float32): float32 = 1f - abs(value - 0.5f) * 2f

func inv*(f: float32): float32 {.inline.} = 1f / f

func rev*(f: float32): float32 {.inline.} = 1f - f

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

func map*(value, min, max, resmin, resmax: float32): float32 = ((value - min) / (max - min)) * (resmax - resmin) + resmin

#assumes value is [0-1]
func map*(value, resmin, resmax: float32): float32 = resmin + (resmax - resmin) * value

func mapClamp*(value, min, max, resmin, resmax: float32): float32 = clamp(((value - min) / (max - min)) * (resmax - resmin) + resmin, resmin, resmax)

{.push checks: off.}

func round*(value, space: float32): float32 {.inline.} = round(value / space) * space

func floor*(value, space: float32): float32 {.inline.} = floor(value / space) * space

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
proc randRange*[T](value: T): T = rand((-value)..value)
proc randSign*(): int = 
  if rand(0f..1f) < 0.5f: 1 else: -1 #rand(bool) doesn't work
proc randAngle*(): float32 = rand(0f..(PI * 2f).float32)
proc range*[T](r: var Rand, value: T): T = r.rand((-value)..value)

{.pop.}

#angle/degree functions; all are in radians

const 
  pi2* = PI * 2.0
  pi* = PI

func rad*(val: float32): float32 {.inline.} = val * PI / 180.0
func deg*(val: float32): float32 {.inline.} = val / (PI / 180.0)

## angle lerp
func alerp*(fromDegrees, toDegrees, progress: float32): float32 = ((fromDegrees + (((toDegrees - fromDegrees + pi2 + pi) mod pi2) - pi) * progress + pi2)) mod pi2

## angle dist
func adist*(angleA, angleB: float32): float32 {.inline.} = 
  let
    a = angleA.emod(pi2)
    b = angleB.emod(pi2)
  min(if a - b < 0: a - b + 360.0.rad else: a - b, if b - a < 0: b - a + 360.0.rad else: b - a)

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

## angle sign diff
func asign*(a, b: float32): int =
  let 
    forw = abs(a - b)
    back = 360.0.rad - forw
  
  return if (a > b) == (back > forw): -1
  else: 1

## angle clamp
func aclamp*(angle, dest, dst: float32): float32 =
  let diff = adist(angle, dest)
  if diff <= dst: angle
  else: angle.aapproach(dest, diff - dst)

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
func sign*(x: int): int {.inline} =
  if x < 0: -1 else: 1
func signi*(x: float32): int {.inline} =
  if x < 0f: -1 else: 1
func signodd*(x: int): float32 {.inline.} = 
  if x mod 2 == 0: 1 else: -1

func sin*(x, scl, mag: float32): float32 {.inline} = sin(x / scl) * mag
func cos*(x, scl, mag: float32): float32 {.inline} = cos(x / scl) * mag

func absin*(x, scl, mag: float32): float32 {.inline} = ((sin(x / scl) + 1f) / 2f) * mag
func abcos*(x, scl, mag: float32): float32 {.inline} = ((cos(x / scl) + 1f) / 2f) * mag

func absin*(x: float32): float32 {.inline} = ((sin(x) + 1f) / 2f)
func abcos*(x: float32): float32 {.inline} = ((cos(x) + 1f) / 2f)

func triangle*(x: float32, phase = 1f, mag = 1f): float32 =
  (abs((x mod phase * 2) - phase) / phase - 0.5f) * 2f * mag

func abtriangle*(x: float32, phase = 1f, mag = 1f): float32 =
  (abs((x mod phase * 2) - phase) / phase) * mag

template vec2*(cx, cy: float32): Vec2 = Vec2(x: cx, y: cy)
template vec2*(cx, cy: int): Vec2 = Vec2(x: cx.float32, y: cy.float32)
proc vec2*(xy: float32): Vec2 {.inline.} = Vec2(x: xy, y: xy)
proc vec2*(pos: AnyVec2): Vec2 {.inline.} = Vec2(x: pos.x, y: pos.y)
template vec2*(): Vec2 = Vec2()
func vec2l*(angle, mag: float32): Vec2 {.inline.} = vec2(mag * cos(angle), mag * sin(angle))
proc randVec*(len: float32): Vec2 {.inline.} = vec2l(rand(0f..(PI.float32 * 2f)), rand(0f..len))
proc randRangeVec*(r: float32): Vec2 {.inline.} = vec2(rand(-r..r), rand(-r..r))
proc randRangeVec*(r: Vec2): Vec2 {.inline.} = vec2(rand(-r.x..r.x), rand(-r.y..r.y))

#vec2i stuff

func vec2i*(x, y: int): Vec2i {.inline.} = Vec2i(x: x, y: y)
func vec2i*(xy: int): Vec2i {.inline.} = Vec2i(x: xy, y: xy)
func vec2i*(): Vec2i {.inline.} = Vec2i()
func vec2*(v: Vec2i): Vec2 {.inline.} = vec2(v.x.float32, v.y.float32)
func vec2i*(v: Vec2): Vec2i {.inline.} = vec2i(v.x.int, v.y.int)
proc vec2i*(pos: AnyVec2i): Vec2i {.inline.} = Vec2i(x: pos.x, y: pos.y)

#vector-vector operations

template opFunc(td: typedesc, op: untyped): untyped =
  func op*(vec: td, other: td): td {.inline.} = vec2(vec.x.op other.x, vec.y.op other.y)

template op(td: typedesc, comp: typedesc, cons: typed, op1, op2: untyped): untyped =
  func op1*(vec: td, other: td): td {.inline.} = cons(op1(vec.x, other.x), op1(vec.y, other.y))
  func op1*(vec: td, other: comp): td {.inline.} = cons(op1(vec.x, other), op1(vec.y, other))
  func op2*(vec: var td, other: td) {.inline.} = vec = cons(op1(vec.x, other.x), op1(vec.y, other.y))
  func op2*(vec: var td, other: comp) {.inline.} = vec = cons(op1(vec.x, other), op1(vec.y, other))

op(Vec2, float32, vec2, `+`, `+=`)
op(Vec2, float32, vec2, `-`, `-=`)
op(Vec2, float32, vec2, `*`, `*=`)
op(Vec2, float32, vec2, `/`, `/=`)

func `*`*(f: float32, vec: Vec2): Vec2 {.inline.} = vec2(f * vec.x, f * vec.y)
func `/`*(f: float32, vec: Vec2): Vec2 {.inline.} = vec2(f / vec.x, f / vec.y)
func `-`*(vec: Vec2): Vec2 {.inline.} = vec2(-vec.x, -vec.y)

opFunc(Vec2, `mod`)
opFunc(Vec2, emod)
opFunc(Vec2, max)
opFunc(Vec2, min)

op(Vec2i, int, vec2i, `+`, `+=`)
op(Vec2i, int, vec2i, `-`, `-=`)
op(Vec2i, int, vec2i, `*`, `*=`)
op(Vec2i, int, vec2i, `div`, `div=`)

func `/`*(vec: Vec2i, value: float32): Vec2 {.inline.} = vec2(vec.x / value, vec.y / value)
func `-`*(vec: Vec2i): Vec2i {.inline.} = vec2i(-vec.x, -vec.y)

#utility methods

func clamp*(vec: Vec2, min, max: Vec2): Vec2 = vec2(clamp(vec.x, min.x, max.x), clamp(vec.y, min.y, max.y))

func clamp*(vec: var Vec2, min, max: Vec2) =
  vec.x = clamp(vec.x, min.x, max.x)
  vec.y = clamp(vec.y, min.y, max.y)

func clamp*(vec: var Vec2i, min, max: Vec2i) =
  vec.x = clamp(vec.x, min.x, max.x)
  vec.y = clamp(vec.y, min.y, max.y)

func dot*(vec, other: Vec2): float32 {.inline.} = vec.x * other.x + vec.y * other.y

func floor*(vec: Vec2): Vec2 {.inline.} = vec2(vec.x.floor, vec.y.floor)
func round*(vec: Vec2, scale = 1f): Vec2 {.inline.} = vec2(vec.x.round(scale), vec.y.round(scale))
func roundi*(vec: Vec2): Vec2i {.inline.} = vec2i(vec.x.round.int, vec.y.round.int)

func abs*(vec: Vec2): Vec2 {.inline.} = vec2(vec.x.abs, vec.y.abs)

func xyratio*(vec: Vec2): float32 {.inline.} = vec.x / vec.y
func yxratio*(vec: Vec2): float32 {.inline.} = vec.y / vec.x

func zero*(vec: Vec2): bool {.inline.} = vec.x == 0f and vec.y == 0f
func zero*(vec: Vec2, margin: float32): bool {.inline.} = abs(vec.x) <= margin and abs(vec.y) <= margin

func scaleFit*(source, target: Vec2): Vec2 =
  ## Scales the source to fit the target while keeping the same aspect ratio. This may cause the source to be smaller than the target in one direction.
  let scale = if target.yxratio > source.yxratio: target.x / source.x else: target.y / source.y
  return source * scale

func scaleFill*(source, target: Vec2): Vec2 =
  ## Scales the source to fill the target while keeping the same aspect ratio. This may cause the source to be larger than the target in one direction.
  let scale = if target.yxratio < source.yxratio: target.x / source.x else: target.y / source.y
  return source * scale

#all angles are in radians

func angle*(vec: Vec2): float32 {.inline.} = 
  let res = arctan2(vec.y, vec.x)
  return if res < 0: res + PI*2.0 else: res

func angle*(vec: Vec2i): float32 {.inline.} =
  if vec.x == 0 and vec.y == 0: return 0f
  vec.vec2.angle

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

func rotate*(vec: Vec2i, steps: int): Vec2i =
  ## Rotates in 90 degree increments.
  let amount = steps.emod 4
  result = vec
  for i in 0..<amount:
    let x = result.x
    result.x = -result.y
    result.y = x

func len*(vec: Vec2): float32 {.inline.} = sqrt(vec.x * vec.x + vec.y * vec.y)
func len2*(vec: Vec2): float32 {.inline.} = vec.x * vec.x + vec.y * vec.y
func `len=`*(vec: var Vec2, b: float32) = 
  let l = vec.len
  if l != 0f:
    vec *= b / l

func `angle=`*(vec: var Vec2, angle: float32) =
  vec = vec2l(angle, vec.len)

func angled*(vec: Vec2, angle: float32): Vec2 {.inline.} =
  vec2l(angle, vec.len)

func nor*(vec: Vec2): Vec2 {.inline.} = 
  let len = vec.len
  return if len == 0f: vec else: vec / len

func setLen*(vec: Vec2, b: float32): Vec2 = vec.nor * b

func lim*(vec: Vec2, limit: float32): Vec2 = 
  let l2 = vec.len2
  let limit2 = limit*limit
  return if l2 > limit2: vec * sqrt(limit2 / l2) else: vec

func lim*(vec: var Vec2, limit: float32) =
  let l2 = vec.len2
  let limit2 = limit*limit
  vec = if l2 > limit2: vec * sqrt(limit2 / l2) else: vec

func dst2*(vec: Vec2, other: Vec2): float32 {.inline.} = 
  let dx = vec.x - other.x
  let dy = vec.y - other.y
  return dx * dx + dy * dy

func dst*(vec: Vec2, other: Vec2): float32 {.inline.} = sqrt(vec.dst2(other))

func within*(vec: Vec2, other: Vec2, distance: float32): bool {.inline.} = vec.dst2(other) <= distance*distance

proc `$`*(vec: Vec2): string = $vec.x & ", " & $vec.y
proc `$`*(vec: Vec2i): string = $vec.x & ", " & $vec.y

func `lerp`*(vec: var Vec2, other: Vec2, alpha: float32) {.inline.} = 
  let invAlpha = 1.0f - alpha
  vec = vec2((vec.x * invAlpha) + (other.x * alpha), (vec.y * invAlpha) + (other.y * alpha))

func `lerp`*(vec: Vec2, other: Vec2, alpha: float32): Vec2 {.inline.} = 
  let invAlpha = 1.0f - alpha
  return vec2((vec.x * invAlpha) + (other.x * alpha), (vec.y * invAlpha) + (other.y * alpha))

func approach*(vec: var Vec2, other: Vec2, alpha: float32) {.inline.} = 
  let 
    d = vec - other
    alpha2 = alpha*alpha
    len2 = d.len2

  if len2 > alpha2:
    vec -= d * sqrt(alpha2 / len2)
  else:
    vec = other

func bezier*(p0, p1, p2: Vec2, t: float32): Vec2 =
  let dt = 1f - t
  return p0 * dt * dt + p1 * 2 * dt * t + p2 * t * t

func bezier*(p0, p1, p2, p3: Vec2, t: float32): Vec2 =
  let
    dt = 1f - t
    dt2 = dt * dt
    t2 = t * t
  return dt2 * dt * p0 + 3 * dt2 * t * p1 + 3 * dt * t2 * p2 + t2 * t * p3

#TODO better impl
const
  d4i* = [vec2i(1, 0), vec2i(0, 1), vec2i(-1, 0), vec2i(0, -1)]
  d4iedge* = [vec2i(1, 1), vec2i(-1, 1), vec2i(-1, -1), vec2i(1, -1)]
  d8i* = [vec2i(1, 0), vec2i(1, 1), vec2i(0, 1), vec2i(-1, 1), vec2i(-1, 0), vec2i(-1, -1), vec2i(0, -1), vec2i(1, -1)]
  d4f* = [vec2(1, 0), vec2(0, 1), vec2(-1, 0), vec2(0, -1)]
  d4fedge* = [vec2(1, 1), vec2(-1, 1), vec2(-1, -1), vec2(1, -1)]

iterator d4*(): Vec2i =
  yield vec2i(1, 0)
  yield vec2i(0, 1)
  yield vec2i(-1, 0)
  yield vec2i(0, -1)

iterator d4mid*(): Vec2i =
  yield vec2i(0, 0)
  yield vec2i(1, 0)
  yield vec2i(0, 1)
  yield vec2i(-1, 0)
  yield vec2i(0, -1)

iterator d4edge*(): Vec2i =
  yield vec2i(1, 1)
  yield vec2i(-1, 1)
  yield vec2i(-1, -1)
  yield vec2i(1, -1)

iterator d8*(): Vec2i =
  yield vec2i(1, 0)
  yield vec2i(1, 1)
  yield vec2i(0, 1)
  yield vec2i(-1, 1)
  yield vec2i(-1, 0)
  yield vec2i(-1, -1)
  yield vec2i(0, -1)
  yield vec2i(1, -1)

iterator d8mid*(): Vec2i =
  yield vec2i(0, 0)
  yield vec2i(1, 0)
  yield vec2i(1, 1)
  yield vec2i(0, 1)
  yield vec2i(-1, 1)
  yield vec2i(-1, 0)
  yield vec2i(-1, -1)
  yield vec2i(0, -1)
  yield vec2i(1, -1)

proc inside*(x, y, w, h: int): bool {.inline.} = x >= 0 and y >= 0 and x < w and y < h
proc inside*(p: Vec2i, w, h: int): bool {.inline.} = p.x >= 0 and p.y >= 0 and p.x < w and p.y < h
proc inside*(p: Vec2i, size: Vec2i): bool {.inline.} = p.x >= 0 and p.y >= 0 and p.x < size.x and p.y < size.y

proc raycast*(a, b: Vec2i, checker: proc(pos: Vec2i): bool): tuple[hit: bool, pos: Vec2i] =
  var
    x = a.x
    y = a.y
    dx = abs(b.x - a.x)
    dy = abs(b.y - a.y)
    sx = if a.x < b.x: 1 else: -1
    sy = if a.y < b.y: 1 else: -1
    e2 = 0
    err = dx - dy
  
  while true:
    if checker(vec2i(x, y)): return (true, vec2i(x, y))
    if x == b.x and y == b.y: return (false, vec2i())
    e2 = 2 * err

    if e2 > -dy:
      err -= dy
      x += sx
    
    if e2 < dx:
      err += dx
      y += sy

  return (false, vec2i())


iterator line*(p1, p2: Vec2i): Vec2i =
  ## Implementation of bresenham's line algorithm; iterates through a line connecting the two points.

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

iterator lineNoDiagonal*(p1, p2: Vec2i): Vec2i =
  ## Implementation of bresenham's line algorithm; iterates through a line connecting the two points. Non-diagonal version.
  
  let 
    dx = abs(p2.x - p1.x)
    dy = -abs(p2.y - p1.y)
    sx = if p1.x < p2.x: 1 else: -1
    sy = if p1.y < p2.y: 1 else: -1

  var
    startX = p1.x
    startY = p1.y

    err = dx + dy
    e2 = 0
  
  yield vec2i(startX, startY)
  
  while startX != p2.x or startY != p2.y:
    e2 = 2 * err
    
    if e2 - dy > dx - e2:
      err += dy
      startX += sx
    else:
      err += dx
      startY += sy

    yield vec2i(startX, startY)

proc rect*(): Rect {.inline.} = Rect()
proc rect*(x, y, w, h: float32): Rect {.inline.} = Rect(x: x, y: y, w: w, h: h)
proc rect*(size: Vec2): Rect {.inline.} = Rect(w: size.x, h: size.y)
proc rect*(x, y: float32, size: Vec2): Rect {.inline.} = Rect(x: x, y: y, w: size.x, h: size.y)
proc rect*(xy: Vec2, w, h: float32): Rect {.inline.} = Rect(x: xy.x, y: xy.y, w: w, h: h)
proc rect*(xy: Vec2, size: Vec2): Rect {.inline.} = Rect(x: xy.x, y: xy.y, w: size.x, h: size.y)
proc rectCenter*(x, y, w, h: float32): Rect {.inline.} = Rect(x: x - w/2.0, y: y - h/2.0, w: w, h: h)
proc rectCenter*(x, y, s: float32): Rect {.inline.} = Rect(x: x - s/2.0, y: y - s/2.0, w: s, h: s)
proc rectCenter*(xy: Vec2, w, h: float32): Rect {.inline.} = Rect(x: xy.x - w/2f, y: xy.y - h/2f, w: w, h: h)
proc rectCenter*(xy: Vec2, wh: Vec2): Rect {.inline.} = rectCenter(xy, wh.x, wh.y)

proc xy*(r: Rect): Vec2 {.inline.} = vec2(r.x, r.y)
proc `xy=`*(r: var Rect, pos: Vec2) {.inline.} =
  r.x = pos.x
  r.y = pos.y
proc pos*(r: Rect): Vec2 {.inline.} = vec2(r.x, r.y)
proc size*(r: Rect): Vec2 {.inline.} = vec2(r.w, r.h)
proc wh*(r: Rect): Vec2 {.inline.} = vec2(r.w, r.h)

proc botLeft*(r: Rect): Vec2 {.inline.} = vec2(r.x, r.y)
proc topLeft*(r: Rect): Vec2 {.inline.} = vec2(r.x, r.y + r.h)
proc topRight*(r: Rect): Vec2 {.inline.} = vec2(r.x + r.w, r.y + r.h)
proc botRight*(r: Rect): Vec2 {.inline.} = vec2(r.x + r.w, r.y)

proc top*(r: Rect): float32 {.inline.} = r.y + r.h
proc right*(r: Rect): float32 {.inline.} = r.x + r.w

proc x2*(r: Rect): float32 {.inline.} = r.y + r.h
proc y2*(r: Rect): float32 {.inline.} = r.x + r.w

proc grow*(r: var Rect, amount: float32) = r = rect(r.x - amount/2f, r.y - amount/2f, r.w + amount, r.h + amount)
proc grow*(r: Rect, amount: float32): Rect = rect(r.x - amount/2f, r.y - amount/2f, r.w + amount, r.h + amount)
proc grow*(r: Rect, amount: Vec2): Rect = rect(r.x - amount.x/2f, r.y - amount.y/2f, r.w + amount.x, r.h + amount.y)

proc wrap*(r: Rect, vec: Vec2, margin = 0f): Vec2 =
  let grown = r.grow(margin)
  (vec - grown.xy).emod(grown.size) + grown.xy

proc centerX*(r: Rect): float32 {.inline.} = r.x + r.w/2.0
proc centerY*(r: Rect): float32 {.inline.} = r.y + r.h/2.0
proc center*(r: Rect): Vec2 {.inline.} = vec2(r.x + r.w/2.0, r.y + r.h/2.0)

proc `-`*(r: Rect, other: Rect): Rect {.inline.} = rect(r.xy - other.xy, r.wh - other.wh)
proc `+`*(r: Rect, other: Rect): Rect {.inline.} = rect(r.xy + other.xy, r.wh + other.wh)

proc `-`*(r: Rect, pos: Vec2): Rect {.inline.} = rect(r.xy - pos, r.wh)
proc `+`*(r: Rect, pos: Vec2): Rect {.inline.} = rect(r.xy + pos, r.wh)

proc merge*(r: Rect, other: Rect): Rect =
  result.x = min(r.x, other.x)
  result.y = min(r.y, other.y)
  result.w = max(r.right, other.right) - result.x
  result.h = max(r.top, other.top) - result.y

proc snap*(r: Rect): Rect =
  ## Snaps a rectangle to integer coordinates. x,y are floored; w,h are ceil-ed.
  result.x = r.x.int
  result.y = r.y.int
  result.w = r.w.ceil
  result.h = r.h.ceil

proc align*(bounds: Vec2, target: Vec2, align: Align, margin = 0f): Rect =
  let 
    alignH = (-(asLeft in align).float32 + (asRight in align).float32) / 2f
    alignV = (-(asBot in align).float32 + (asTop in align).float32) / 2f
  
  return rectCenter(bounds / 2f + (bounds - target - vec2(margin)) * vec2(alignH, alignV), target)

proc align*(rect: Rect, target: Vec2, align: Align, margin = 0f): Rect = align(rect.size, target, align, margin) + rect.xy

#collision stuff

proc intersect*(r1: Rect, r2: Rect): Rect =
  var
    x1 = max(r1.x, r2.x)
    y1 = max(r1.y, r2.y)
    x2 = max(r1.x2, r2.x2)
    y2 = max(r1.y2, r2.y2)
  
  if x2 < x1: x2 = x1
  if y2 < y1: y2 = y1
  return rect(x1, y1, x2 - x1, y2 - y1)

proc contains*(r: Rect, x, y: float32): bool {.inline.} = r.x <= x and r.x + r.w >= x and r.y <= y and r.y + r.h >= y
proc contains*(r: Rect, pos: Vec2): bool {.inline.} = r.contains(pos.x, pos.y)

proc overlaps*(a, b: Rect): bool = a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y

proc overlaps*(r1: Rect, v1: Vec2, r2: Rect, v2: Vec2, hitPos: var Vec2): bool =
  let 
    vel = v1 - v2
    #prevent inf
    rv = vec2(if vel.x == 0f: 0.000001f else: vel.x, if vel.y == 0f: 0.000001f else: vel.y)

  var invEntry, invExit: Vec2

  if rv.x > 0.0:
    invEntry.x = r2.x - (r1.x + r1.w)
    invExit.x = (r2.x + r2.w) - r1.x
  else:
    invEntry.x = (r2.x + r2.w) - r1.x
    invExit.x = r2.x - (r1.x + r1.w)

  if rv.y > 0.0:
    invEntry.y = r2.y - (r1.y + r1.h)
    invExit.y = (r2.y + r2.h) - r1.y
  else:
    invEntry.y = (r2.y + r2.h) - r1.y
    invExit.y = r2.y - (r1.y + r1.h)

  let 
    entry = invEntry / rv
    exit = invExit / rv
    entryTime = max(entry.x, entry.y)
    exitTime = min(exit.x, exit.y)

  if entryTime > exitTime or exit.x < 0.0 or exit.y < 0.0 or entry.x > 1.0 or entry.y > 1.0:
    #edge case?
    #if r1.overlaps r2:
    #  hitpos = (r1.center + r2.center) / 2f
    #  return true
  
    return false
  else:
    hitPos = vec2(r1.x + r1.w / 2f + v1.x * entryTime, r1.y + r1.h / 2f + v1.y * entryTime)
    return true

proc intersectSegments(p1, p2, p3, p4: Vec2): bool =
  let d = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y)
  if d == 0f: return false
  let 
    yd = p1.y - p3.y
    xd = p1.x - p3.x
    ua = ((p4.x - p3.x) * yd - (p4.y - p3.y) * xd) / d
  if ua < 0 or ua > 1: return false

  let ub = ((p2.x - p1.x) * yd - (p2.y - p1.y) * xd) / d
  if ub < 0 or ub > 1: return false

  return true #intersection: (x1 + (x2 - x1) * ua, y1 + (y2 - y1) * ua);

proc intersectSegment*(rect: Rect, p1, p2: Vec2): bool =
  return
    rect.contains(p1) or
    intersectSegments(p1, p2, rect.botLeft, rect.botRight) or
    intersectSegments(p1, p2, rect.botRight, rect.topRight) or
    intersectSegments(p1, p2, rect.topRight, rect.topLeft) or
    intersectSegments(p1, p2, rect.topLeft, rect.botLeft)

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
proc moveDelta*(box: Rect, vel: Vec2, solidity: proc(xy: Vec2i): bool, seg = 0.1f): Vec2 = 
  let
    left = (box.x + 0.5).int - 1
    bottom = (box.y + 0.5).int - 1
    right = (box.x + 0.5 + box.w).int + 1
    top = (box.y + 0.5 + box.h).int + 1
  
  var 
    hitbox = box
    segx = vel.x.abs
    segy = vel.y.abs

  while segx > 0f:
    hitbox.x += min(seg, segx) * vel.x.sign
    segx -= seg

    for dx in left..right:
      for dy in bottom..top:
        if solidity(vec2i(dx, dy)):
          let tile = rect((dx).float32 - 0.5f, (dy).float32 - 0.5f, 1, 1)
          if hitbox.overlaps(tile):
            hitbox.x -= tile.penetrationX(hitbox)
  
  while segy > 0f:
    hitbox.y += min(seg, segy) * vel.y.sign
    segy -= seg

    for dx in left..right:
      for dy in bottom..top:
        if solidity(vec2i(dx, dy)):
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


## Returns a point on the segment nearest to the specified point.
proc nearestSegmentPoint*(a, b, point: Vec2): Vec2 =
  let length2 = a.dst2(b)
  if length2 == 0f: return a
  let t = ((point.x - a.x) * (b.x - a.x) + (point.y - a.y) * (b.y - a.y)) / length2
  if t < 0: return a
  if t > 1: return b
  return a + (b - a) * t

## Returns the distance between the given segment and point.
proc distanceSegmentPoint*(a, b, point: Vec2): float32 = nearestSegmentPoint(a, b, point).dst(point)

## Distance between a rectangle and a point.
proc dst*(r: Rect, point: Vec2): float32 =
  if r.contains(point): 0f
  else: min(
    min(
      distanceSegmentPoint(r.xy, r.xy + vec2(r.w, 0f), point),
      distanceSegmentPoint(r.xy, r.xy + vec2(0f, r.h), point)
    ),
    min(
      distanceSegmentPoint(r.xy + r.size, r.xy + vec2(r.w, 0f), point),
      distanceSegmentPoint(r.xy + r.size, r.xy + vec2(0f, r.h), point)
    )
  )

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

#converts a 2D orthographics 3x3 matrix to a 4x4 matrix for shaders
proc toMat4*(matrix: Mat): array[16, float32] =
  result[4] = matrix[M01]
  result[1] = matrix[M10]

  result[0] = matrix[M00]
  result[5] = matrix[M11]
  result[10] = matrix[M22]
  result[12] = matrix[M02]
  result[13] = matrix[M12]
  result[15] = 1

#creates an identity matrix
proc idt*(): Mat = [1f, 0, 0, 0, 1, 0, 0, 0, 1]

#orthographic projection matrix
proc ortho*(x, y, width, height: float32): Mat =
  let right = x + width
  let top = y + height
  let xOrth = 2 / (right - x);
  let yOrth = 2 / (top - y);
  let tx = -(right + x) / (right - x);
  let ty = -(top + y) / (top - y);

  return [xOrth, 0, 0, 0, yOrth, 0, tx, ty, 1]

proc ortho*(pos, size: Vec2): Mat {.inline.} = ortho(pos.x, pos.y, size.x, size.y)

proc ortho*(size: Vec2): Mat {.inline.} = ortho(0, 0, size.x, size.y)

proc ortho*(size: Vec2i): Mat {.inline.} = ortho(size.vec2)

proc ortho*(bounds: Rect): Mat {.inline.} = ortho(bounds.xy, bounds.size)

proc `*`*(a: Mat, b: Mat): Mat = [
    a[M00] * b[M00] + a[M01] * b[M10] + a[M02] * b[M20], 
    a[M00] * b[M01] + a[M01] * b[M11] + a[M02] * b[M21],
    a[M00] * b[M02] + a[M01] * b[M12] + a[M02] * b[M22],
    a[M10] * b[M00] + a[M11] * b[M10] + a[M12] * b[M20],
    a[M10] * b[M01] + a[M11] * b[M11] + a[M12] * b[M21],
    a[M10] * b[M02] + a[M11] * b[M12] + a[M12] * b[M22],
    a[M20] * b[M00] + a[M21] * b[M10] + a[M22] * b[M20],
    a[M20] * b[M01] + a[M21] * b[M11] + a[M22] * b[M21],
    a[M20] * b[M02] + a[M21] * b[M12] + a[M22] * b[M22]
  ]

proc det*(self: Mat): float32 =
  return self[M00] * self[M11] * self[M22] + self[M01] * self[M12] * self[M20] + self[M02] * self[M10] * self[M21] -
    self[M00] * self[M12] * self[M21] - self[M01] * self[M10] * self[M22] - self[M02] * self[M11] * self[M20]

proc inv*(self: Mat): Mat =
  let invd = 1 / self.det()

  if invd == 0.0: raise newException(Exception, "Can't invert a singular matrix")

  return [
    (self[M11] * self[M22] - self[M21] * self[M12]) * invd,
    (self[M20] * self[M12] - self[M10] * self[M22]) * invd,
    (self[M10] * self[M21] - self[M20] * self[M11]) * invd,
    (self[M21] * self[M02] - self[M01] * self[M22]) * invd,
    (self[M00] * self[M22] - self[M20] * self[M02]) * invd,
    (self[M20] * self[M01] - self[M00] * self[M21]) * invd,
    (self[M01] * self[M12] - self[M11] * self[M02]) * invd,
    (self[M10] * self[M02] - self[M00] * self[M12]) * invd,
    (self[M00] * self[M11] - self[M10] * self[M01]) * invd
  ]

proc `*`*(self: Vec2, mat: Mat): Vec2 = vec2(self.x * mat[0] + self.y * mat[3] + mat[6], self.x * mat[1] + self.y * mat[4] + mat[7])

proc scl*(mat: Mat): Vec2 {.inline.} = vec2(mat[M00], mat[M11])

proc trans*(mat: Mat): Vec2 {.inline.} = vec2(mat[M02], mat[M12])

#PARTICLES

## Stateless particles based on RNG. x/y are injected into template body.
template particles*(seed: int, amount: int, ppos: Vec2, radius: float32, body: untyped) =
  var r = initRand(seed)
  for i in 0..<amount:
    let 
      rot {.inject.} = r.rand(360f.rad).float32
      v = vec2l(rot, r.rand(radius))
      pos {.inject.} = ppos + v
    body

## Stateless particles based on RNG. x/y are injected into template body.
template particlesAngle*(seed: int, amount: int, ppos: Vec2, radius: float32, rotation, spread: float32, body: untyped) =
  var r = initRand(seed)
  for i in 0..<amount:
    let
      rot {.inject.} = rotation + r.rand(-spread..spread).float32
      v = vec2l(rot, r.rand(radius))
      pos {.inject.} = ppos + v
    body

## Stateless particles based on RNG. x/y are injected into template body.
template particlesLifeOffset*(seed: int, amount: int, ppos: Vec2, basefin: float32, radiusFrom, radius: float32, body: untyped) =
  var r = initRand(seed)
  for i in 0..<amount:
    let
      lscl = r.rand(0.1f..1f)
      fin {.inject, used.} = basefin / lscl
      fout {.inject, used.} = 1f - fin
      rot {.inject, used.} = r.rand(360f.rad).float32
      count {.inject, used.} = i
      v = vec2l(rot, radiusFrom + r.rand(radius * fin))
      pos {.inject.} = ppos + v
    if fin <= 1f:
      body

template particlesLife*(seed: int, amount: int, ppos: Vec2, basefin: float32, radius: float32, body: untyped) =
  particlesLifeOffset(seed, amount, ppos, basefin, 0f, radius, body)

template circle*(amount: int, body: untyped) =
  for i in 0..<amount:
    let 
      circleAngle {.inject.} = (i.float32 / amount.float32 * pi2)
      circleIndex {.inject, used.} = i
    body

template circlev*(amount: int, len: float32, body: untyped) =
  for i in 0..<amount:
    let
      circleAngle {.inject.} = (i.float32 / amount.float32 * pi2)
      circleIndex {.inject, used.} = i
      v {.inject.} = vec2l(circleAngle, len)
    body

template shotgun*(amount: int, spacing: float32, body: untyped) =
  for i in 0..<amount:
    let angle {.inject.} = ((i - (amount div 2).float32) * spacing)
    body

#TODO remove one of these
template spread*(shots: int, spread: float32, body: untyped) =
  for i in 0..<shots:
    let 
      angleOffset {.inject.} = (i - ((shots - 1f) / 2f).float32) * spread
      spreadIndex {.inject, used.} = i
    body

#CAMERA

proc width*(cam: Cam): float32 {.inline.} = cam.size.x
proc height*(cam: Cam): float32 {.inline.} = cam.size.y

proc update*(cam: Cam, screenBounds: Rect, size: Vec2 = cam.size, pos = cam.pos) = 
  cam.size = size.max(vec2(0.000001f))
  cam.pos = pos
  cam.mat = ortho(cam.pos - cam.size/2f, cam.size)
  cam.inv = cam.mat.inv()
  cam.screenBounds = screenBounds

proc newCam*(size: Vec2 = vec2(0f, 0f)): Cam = 
  result = Cam(pos: vec2(0.0, 0.0), size: size)
  result.update(rect(vec2(), size))

proc viewport*(cam: Cam): Rect {.inline.} = rect(cam.pos - cam.size/2f, cam.size)
#alias
proc view*(cam: Cam): Rect {.inline.} = rect(cam.pos - cam.size/2f, cam.size)