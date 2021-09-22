
import math, ../fmath
export fmath

#region VECTORS

type Plane* = object
  #plane normal direction
  normal*: Vec3
  #distance to origin
  dst*: float32

type PlaneSide* = enum
  psOn, psBack, psFront

type Quat* = object
  x*, y*, z*, w*: float32

#4x4 matrix for 3D transformations - called Mat3 for Vec3 consistency
type Mat3* = array[16, float32]

type Ray* = object
  origin, direction: Vec3

type Frustum* = object
  #the six clipping planes, near, far, left, right, top, bottom
  planes: array[6, Plane]

#3D camera
type Cam3* = ref object
  #field of view for perspective cameras
  fov*: float32
  #near/far clipping planes
  near*, far*: float32
  #if set to true, a perspective projection is used.
  perspective*: bool
  #viewport size
  size*: Vec2
  #world position
  pos*: Vec3
  #normalized facing direction
  direction*: Vec3
  #normalized up vector
  up*: Vec3
  #combined projection and view matrix
  combined*: Mat3
  #projection matrix
  proj*: Mat3
  #view matrix
  view*: Mat3
  #inverse combined projection and view matrix
  invProjView*: Mat3
  #frustum for clipping
  frustum*: Frustum

template vec3*(cx, cy: float32, cz = 0f): Vec3 = Vec3(x: cx, y: cy, z: cz)
template vec2*(vec: Vec3): Vec2 = vec2(vec.x, vec.y)
template vec3*(vec: Vec2, z = 0f): Vec3 = vec3(vec.x, vec.y, z)
proc vec3*(): Vec3 {.inline.} = Vec3()

const 
  vec3Zero* = vec3(0, 0, 0)
  vec3X* = vec3(1, 0, 0)
  vec3Y* = vec3(0, 1, 0)
  vec3Z* = vec3(0, 0, 1)

template op(td: typedesc, comp: typedesc, cons: typed, op1, op2: untyped): untyped =
  func op1*(vec: td, other: td): td {.inline.} = cons(op1(vec.x, other.x), op1(vec.y, other.y), op1(vec.z, other.z))
  func op1*(vec: td, other: comp): td {.inline.} = cons(op1(vec.x, other), op1(vec.y, other), op1(vec.z, other))
  func op2*(vec: var td, other: td) {.inline.} = vec = cons(op1(vec.x, other.x), op1(vec.y, other.y), op1(vec.z, other.z))
  func op2*(vec: var td, other: comp) {.inline.} = vec = cons(op1(vec.x, other), op1(vec.y, other), op1(vec.z, other))

op(Vec3, float32, vec3, `+`, `+=`)
op(Vec3, float32, vec3, `-`, `-=`)
op(Vec3, float32, vec3, `*`, `*=`)
op(Vec3, float32, vec3, `/`, `/=`)

func `-`*(vec: Vec3): Vec3 {.inline.} = vec3(-vec.x, -vec.y, -vec.z)

#cross product
func crs*(vec, other: Vec3): Vec3 = vec3(vec.y * other.z - vec.z * other.y, vec.z * other.x - vec.x * other.z, vec.x * other.y - vec.y * other.x)

#dot product
func dot*(vec, other: Vec3): float32 {.inline.} = vec.x * other.x + vec.y * other.y + vec.z * other.z

#utility methods

func `zero`*(vec: Vec3): bool {.inline.} = vec.x == 0f and vec.y == 0f and vec.z == 0f

func `lerp`*(vec: var Vec3, other: Vec3, alpha: float32) {.inline.} = 
  let invAlpha = 1.0f - alpha
  vec = vec3((vec.x * invAlpha) + (other.x * alpha), (vec.y * invAlpha) + (other.y * alpha), (vec.z * invAlpha) + (other.z * alpha))

func `lerp`*(vec: Vec3, other: Vec3, alpha: float32): Vec3 {.inline.} = 
  let invAlpha = 1.0f - alpha
  return vec3((vec.x * invAlpha) + (other.x * alpha), (vec.y * invAlpha) + (other.y * alpha), (vec.z * invAlpha) + (other.z * alpha))

#all angles are in radians

func len*(vec: Vec3): float32 {.inline.} = sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
func len2*(vec: Vec3): float32 {.inline.} = vec.x * vec.x + vec.y * vec.y + vec.z * vec.z
func `len=`*(vec: var Vec3, b: float32) = vec *= b / vec.len

func nor*(vec: Vec3): Vec3 {.inline.} = vec / vec.len

func lim*(vec: Vec3, limit: float32): Vec3 = 
  let l2 = vec.len2
  let limit2 = limit*limit
  return if l2 > limit2: vec * sqrt(limit2 / l2) else: vec

func dst2*(vec: Vec3, other: Vec3): float32 {.inline.} = 
  let
    dx = vec.x - other.x
    dy = vec.y - other.y
    dz = vec.z - other.z
  return dx * dx + dy * dy + dz * dz

func dst*(vec: Vec3, other: Vec3): float32 {.inline.} = sqrt(vec.dst2(other))

func within*(vec: Vec3, other: Vec3, distance: float32): bool {.inline.} = vec.dst2(other) <= distance*distance

proc `$`*(vec: Vec3): string = $vec.x & ", " & $vec.y & ", " & $vec.z

#endregion
#region QUATERNION

template quat*(ax = 0f, ay = 0f, az = 0f, aw = 1f): Quat =
  Quat(x: ax, y: ay, z: az, w: aw)

proc len2*(quat: Quat): float32 =
  quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w

proc nor*(quat: Quat): Quat =
  let len = quat.len2
  if len != 0f and len != 1f:
    let sq = len.sqrt
    return quat(quat.x / sq, quat.y / sq, quat.z / sq, quat.w / sq)
  return quat

proc conj*(q: Quat): Quat = quat(-q.x, -q.y, -q.z, q.w)

proc quatAxis*(axis: Vec3, angle: float32): Quat =
  var d = axis.len
  if d == 0f: return quat()
  d = 1f / d
  let 
    lang = if angle < 0: pi2 - (-angle.mod pi2) else: angle.mod pi2
    lsin = sin(lang / 2f)
    lcos = cos(lang / 2f)
  return quat(d * axis.x * lsin, d * axis.y * lsin, d * axis.z * lsin, lcos).nor

proc `*`*(self, other: Quat): Quat = quat(
  self.w * other.x + self.x * other.w + self.y * other.z - self.z * other.y,
  self.w * other.y + self.y * other.w + self.z * other.x - self.x * other.z,
  self.w * other.z + self.z * other.w + self.x * other.y - self.y * other.x,
  self.w * other.w - self.x * other.x - self.y * other.y - self.z * other.z
)

proc slerp*(self, other: Quat, alpha: float32): Quat =
  let d = self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
  let absDot = if d < 0f: -d else: d

  var 
    scale0 = 1f - alpha
    scale1 = alpha
  
  if 1 - absDot > 0.1:
    let angle = arccos(absDot)
    let invSinTheta = 1f / sin(angle)

    scale0 = sin((1f - alpha) * angle) * invSinTheta
    scale1 = sin((alpha * angle)) * invSinTheta

  if d < 0f: scale1 = -scale1

  return quat(
    (scale0 * self.x) + (scale1 * other.x),
    (scale0 * self.y) + (scale1 * other.y),
    (scale0 * self.z) + (scale1 * other.z),
    (scale0 * self.w) + (scale1 * other.w)
  )
  
#endregion
#region MATRICES

const
  M00 = 0
  M01 = 4
  M02 = 8
  M03 = 12
  M10 = 1
  M11 = 5
  M12 = 9
  M13 = 13
  M20 = 2
  M21 = 6
  M22 = 10
  M23 = 14
  M30 = 3
  M31 = 7
  M32 = 11
  M33 = 15

#creates an identity 3D matrix
proc idt3*(): Mat3 {.inline.} =
  result[M00] = 1f
  result[M11] = 1f
  result[M22] = 1f
  result[M33] = 1f

#creates a 3D translation matrix
proc trans3*(vec: Vec3): Mat3 =
  result[M00] = 1f
  result[M11] = 1f
  result[M22] = 1f
  result[M33] = 1f

  result[M03] = vec.x
  result[M13] = vec.y
  result[M23] = vec.z

proc pos*(mat: Mat3): Vec3 = vec3(mat[M03], mat[M13], mat[M23])

proc `pos=`*(mat: var Mat3, vec: Vec3) =
  mat[M03] = vec.x
  mat[M13] = vec.y
  mat[M23] = vec.z

proc scl*(mat: Mat3): Vec3 = vec3(mat[M00], mat[M11], mat[M22])

proc `scl=`*(mat: var Mat3, vec: Vec3) =
  mat[M00] = vec.x
  mat[M11] = vec.y
  mat[M22] = vec.z

#creates a 3D rotation matrix
proc rot3*(quat: Quat): Mat3 =
  let
    xs = quat.x * 2f
    ys = quat.y * 2f
    zs = quat.z * 2f
    wx = quat.w * xs
    wy = quat.w * ys
    wz = quat.w * zs
    xx = quat.x * xs
    xy = quat.x * ys
    xz = quat.x * zs
    yy = quat.y * ys
    yz = quat.y * zs
    zz = quat.z * zs

  result[M00] = (1f - (yy + zz))
  result[M01] = (xy - wz)
  result[M02] = (xz + wy)
  result[M03] = 0f

  result[M10] = (xy + wz)
  result[M11] = (1f - (xx + zz))
  result[M12] = (yz - wx)
  result[M13] = 0f

  result[M20] = (xz - wy)
  result[M21] = (yz + wx)
  result[M22] = (1f - (xx + yy))
  result[M23] = 0f

  result[M33] = 1f

proc rot3*(axis: Vec3, angle: float32): Mat3 = rot3(quatAxis(axis, angle))

#inverts a matrix
proc inv*(mat: Mat3): Mat3 =
  let 
    det = mat[M30] * mat[M21] * mat[M12] * mat[M03] - mat[M20] * mat[M31] * mat[M12] * mat[M03] - mat[M30] * mat[M11] * 
    mat[M22] * mat[M03] + mat[M10] * mat[M31] * mat[M22] * mat[M03] + mat[M20] * mat[M11] * mat[M32] * mat[M03] - mat[M10] * 
    mat[M21] * mat[M32] * mat[M03] - mat[M30] * mat[M21] * mat[M02] * mat[M13] + mat[M20] * mat[M31] * mat[M02] * mat[M13] + 
    mat[M30] * mat[M01] * mat[M22] * mat[M13] - mat[M00] * mat[M31] * mat[M22] * mat[M13] - mat[M20] * mat[M01] * mat[M32] * 
    mat[M13] + mat[M00] * mat[M21] * mat[M32] * mat[M13] + mat[M30] * mat[M11] * mat[M02] * mat[M23] - mat[M10] * mat[M31] * 
    mat[M02] * mat[M23] - mat[M30] * mat[M01] * mat[M12] * mat[M23] + mat[M00] * mat[M31] * mat[M12] * mat[M23] + mat[M10] * 
    mat[M01] * mat[M32] * mat[M23] - mat[M00] * mat[M11] * mat[M32] * mat[M23] - mat[M20] * mat[M11] * mat[M02] * mat[M33] + 
    mat[M10] * mat[M21] * mat[M02] * mat[M33] + mat[M20] * mat[M01] * mat[M12] * mat[M33] - mat[M00] * mat[M21] * mat[M12] * 
    mat[M33] - mat[M10] * mat[M01] * mat[M22] * mat[M33] + mat[M00] * mat[M11] * mat[M22] * mat[M33]

  if det == 0f: raise newException(Exception, "non-invertible matrix")

  let invd = 1f / det;

  return [
    (mat[M12] * mat[M23] * mat[M31] - mat[M13] * mat[M22] * mat[M31] + mat[M13] * mat[M21] * mat[M32] - mat[M11] *
    mat[M23] * mat[M32] - mat[M12] * mat[M21] * mat[M33] + mat[M11] * mat[M22] * mat[M33]) * invd,
    (mat[M03] * mat[M22] * mat[M31] - mat[M02] * mat[M23] * mat[M31] - mat[M03] * mat[M21] * mat[M32] + mat[M01] *
    mat[M23] * mat[M32] + mat[M02] * mat[M21] * mat[M33] - mat[M01] * mat[M22] * mat[M33]) * invd,
    (mat[M02] * mat[M13] * mat[M31] - mat[M03] * mat[M12] * mat[M31] + mat[M03] * mat[M11] * mat[M32] - mat[M01] *
    mat[M13] * mat[M32] - mat[M02] * mat[M11] * mat[M33] + mat[M01] * mat[M12] * mat[M33]) * invd,
    (mat[M03] * mat[M12] * mat[M21] - mat[M02] * mat[M13] * mat[M21] - mat[M03] * mat[M11] * mat[M22] + mat[M01] *
    mat[M13] * mat[M22] + mat[M02] * mat[M11] * mat[M23] - mat[M01] * mat[M12] * mat[M23]) * invd,
    (mat[M13] * mat[M22] * mat[M30] - mat[M12] * mat[M23] * mat[M30] - mat[M13] * mat[M20] * mat[M32] + mat[M10] *
    mat[M23] * mat[M32] + mat[M12] * mat[M20] * mat[M33] - mat[M10] * mat[M22] * mat[M33]) * invd,
    (mat[M02] * mat[M23] * mat[M30] - mat[M03] * mat[M22] * mat[M30] + mat[M03] * mat[M20] * mat[M32] - mat[M00] *
    mat[M23] * mat[M32] - mat[M02] * mat[M20] * mat[M33] + mat[M00] * mat[M22] * mat[M33]) * invd,
    (mat[M03] * mat[M12] * mat[M30] - mat[M02] * mat[M13] * mat[M30] - mat[M03] * mat[M10] * mat[M32] + mat[M00] *
    mat[M13] * mat[M32] + mat[M02] * mat[M10] * mat[M33] - mat[M00] * mat[M12] * mat[M33]) * invd,
    (mat[M02] * mat[M13] * mat[M20] - mat[M03] * mat[M12] * mat[M20] + mat[M03] * mat[M10] * mat[M22] - mat[M00] *
    mat[M13] * mat[M22] - mat[M02] * mat[M10] * mat[M23] + mat[M00] * mat[M12] * mat[M23]) * invd,
    (mat[M11] * mat[M23] * mat[M30] - mat[M13] * mat[M21] * mat[M30] + mat[M13] * mat[M20] * mat[M31] - mat[M10] *
    mat[M23] * mat[M31] - mat[M11] * mat[M20] * mat[M33] + mat[M10] * mat[M21] * mat[M33]) * invd,
    (mat[M03] * mat[M21] * mat[M30] - mat[M01] * mat[M23] * mat[M30] - mat[M03] * mat[M20] * mat[M31] + mat[M00] *
    mat[M23] * mat[M31] + mat[M01] * mat[M20] * mat[M33] - mat[M00] * mat[M21] * mat[M33]) * invd,
    (mat[M01] * mat[M13] * mat[M30] - mat[M03] * mat[M11] * mat[M30] + mat[M03] * mat[M10] * mat[M31] - mat[M00] *
    mat[M13] * mat[M31] - mat[M01] * mat[M10] * mat[M33] + mat[M00] * mat[M11] * mat[M33]) * invd,
    (mat[M03] * mat[M11] * mat[M20] - mat[M01] * mat[M13] * mat[M20] - mat[M03] * mat[M10] * mat[M21] + mat[M00] *
    mat[M13] * mat[M21] + mat[M01] * mat[M10] * mat[M23] - mat[M00] * mat[M11] * mat[M23]) * invd,
    (mat[M12] * mat[M21] * mat[M30] - mat[M11] * mat[M22] * mat[M30] - mat[M12] * mat[M20] * mat[M31] + mat[M10] *
    mat[M22] * mat[M31] + mat[M11] * mat[M20] * mat[M32] - mat[M10] * mat[M21] * mat[M32]) * invd,
    (mat[M01] * mat[M22] * mat[M30] - mat[M02] * mat[M21] * mat[M30] + mat[M02] * mat[M20] * mat[M31] - mat[M00] *
    mat[M22] * mat[M31] - mat[M01] * mat[M20] * mat[M32] + mat[M00] * mat[M21] * mat[M32]) * invd,
    (mat[M02] * mat[M11] * mat[M30] - mat[M01] * mat[M12] * mat[M30] - mat[M02] * mat[M10] * mat[M31] + mat[M00] *
    mat[M12] * mat[M31] + mat[M01] * mat[M10] * mat[M32] - mat[M00] * mat[M11] * mat[M32]) * invd,
    (mat[M01] * mat[M12] * mat[M20] - mat[M02] * mat[M11] * mat[M20] + mat[M02] * mat[M10] * mat[M21] - mat[M00] *
    mat[M12] * mat[M21] - mat[M01] * mat[M10] * mat[M22] + mat[M00] * mat[M11] * mat[M22]) * invd
  ]

#multiplies two matrices together
proc `*`*(a, b: Mat3): Mat3 = 
  [
    a[M00] * b[M00] + a[M01] * b[M10] + a[M02] * b[M20] + a[M03] * b[M30],
    a[M10] * b[M00] + a[M11] * b[M10] + a[M12] * b[M20] + a[M13] * b[M30],
    a[M20] * b[M00] + a[M21] * b[M10] + a[M22] * b[M20] + a[M23] * b[M30],
    a[M30] * b[M00] + a[M31] * b[M10] + a[M32] * b[M20] + a[M33] * b[M30],
    a[M00] * b[M01] + a[M01] * b[M11] + a[M02] * b[M21] + a[M03] * b[M31],
    a[M10] * b[M01] + a[M11] * b[M11] + a[M12] * b[M21] + a[M13] * b[M31],
    a[M20] * b[M01] + a[M21] * b[M11] + a[M22] * b[M21] + a[M23] * b[M31],
    a[M30] * b[M01] + a[M31] * b[M11] + a[M32] * b[M21] + a[M33] * b[M31],
    a[M00] * b[M02] + a[M01] * b[M12] + a[M02] * b[M22] + a[M03] * b[M32],
    a[M10] * b[M02] + a[M11] * b[M12] + a[M12] * b[M22] + a[M13] * b[M32],
    a[M20] * b[M02] + a[M21] * b[M12] + a[M22] * b[M22] + a[M23] * b[M32],
    a[M30] * b[M02] + a[M31] * b[M12] + a[M32] * b[M22] + a[M33] * b[M32],
    a[M00] * b[M03] + a[M01] * b[M13] + a[M02] * b[M23] + a[M03] * b[M33],
    a[M10] * b[M03] + a[M11] * b[M13] + a[M12] * b[M23] + a[M13] * b[M33],
    a[M20] * b[M03] + a[M21] * b[M13] + a[M22] * b[M23] + a[M23] * b[M33],
    a[M30] * b[M03] + a[M31] * b[M13] + a[M32] * b[M23] + a[M33] * b[M33] 
  ]

proc trans3*(mat: Mat3, vec: Vec3): Mat3 = mat * trans3(vec)

proc rot3*(mat: Mat3, quat: Quat): Mat3 = mat * rot3(quat)

#note: this crashes the nim compiler:
#proc prj*[N](vecs: array[N, float32], numVecs = vecs.len): array[N, float32] = discard

#multiplies the vectors with the given matrix
proc prj*[N](mat: Mat3, vecs: array[N, Vec3]): array[N, Vec3] =
  for i in 0..<vecs.len:
    result[i] = vec3(
      (vecs[i].x * mat[M00] + vecs[i].y * mat[M01] + vecs[i].z * mat[M02] + mat[M03]),
      (vecs[i].x * mat[M10] + vecs[i].y * mat[M11] + vecs[i].z * mat[M12] + mat[M13]),
      (vecs[i].x * mat[M20] + vecs[i].y * mat[M21] + vecs[i].z * mat[M22] + mat[M23])
    ) / (vecs[i].x * mat[M30] + vecs[i].y * mat[M31] + vecs[i].z * mat[M32] + mat[M33])

#multiplies this vector by the given matrix
proc prj*(v: Vec3, mat: Mat3): Vec3 =
  let lw = 1f / (v.x * mat[M30] + v.y * mat[M31] + v.z * mat[M32] + mat[M33])
  return vec3(
    (v.x * mat[M00] + v.y * mat[M01] + v.z * mat[M02] + mat[M03]) * lw, 
    (v.x * mat[M10] + v.y * mat[M11] + v.z * mat[M12] + mat[M13]) * lw, 
    (v.x * mat[M20] + v.y * mat[M21] + v.z * mat[M22] + mat[M23]) * lw
  )

#creates a projection matrix with a near and far plane, a field of view in degrees and an aspect ratio. 
proc projection3*(near, far, fovy, aspectRatio: float32): Mat3 =
  let 
    fd = 1f / tan((fovy * (PI / 180f)) / 2f).float32
    a1 = (far + near) / (near - far)
    a2 = (2f * far * near) / (near - far)
  
  return [fd / aspectRatio, 0, 0, 0, 0, fd, 0, 0, 0, 0, a1, -1, 0, 0, a2, 0]

#creates a orthographic projection matrix.
proc ortho3*(left, right, bot, top, near, far: float32): Mat3 =
  let
    tx = -(right + left) / (right - left)
    ty = -(top + bot) / (top - bot)
    tz = -(far + near) / (far - near)
  
  return [2f / (right - left), 0, 0, 0, 0, 2f / (top - bot), 0, 0, 0, 0, -2f / (far - near), 0, tx, ty, tz, 1f]

#creates a matrix to a look at matrix with a direction and an up vector. 
proc lookAt3*(direction, up: Vec3): Mat3 =
  let vex = direction.nor.crs(up).nor
  let vez = direction.nor
  let vey = vex.crs(vez).nor

  #TODO inline all this stuff
  result = idt3()
  result[M00] = vex.x
  result[M01] = vex.y
  result[M02] = vex.z
  result[M10] = vey.x
  result[M11] = vey.y
  result[M12] = vey.z
  result[M20] = -vez.x
  result[M21] = -vez.y
  result[M22] = -vez.z

proc lookAt3*(position, target, up: Vec3): Mat3 =
  lookAt3(target - position, up) * trans3(-position)

#endregion
#region 3D STRUCTURES

#constructs a plane from a normal and a distance from the origin
proc initPlane*(normal: Vec3, dst: float32): Plane = Plane(normal: normal, dst: dst)

#sets the plane normal and distance to the origin based on the three given points, which are considered to be on the plane.
proc initPlane*(p1, p2, p3: Vec3): Plane =
  result.normal = (p1 - p2).crs(p2 - p3).nor
  result.dst = -p1.dot(result.normal)

#tests a point against a plane, and returns which side it is on
proc test*(plane: Plane, vec: Vec3): PlaneSide =
  let dist = plane.normal.dot(vec) + plane.dst

  return if dist == 0: psOn
  elif dist < 0: psBack
  else: psFront

#projects the supplied vector onto this plane.
proc project*(plane: Plane, v: Vec3): Vec3 =
  return v - (plane.normal * (plane.normal.dot(v) + plane.dst))

proc ray*(orig, dir: Vec3): Ray {.inline.} = Ray(origin: orig, direction: dir.nor())

proc endPoint*(ray: Ray, dst: float32): Vec3 = ray.origin + ray.direction * dst

# FRUSTUM

#creates a new frustum based on the given inverse combined projection and view matrix.
proc initFrustum*(invProjView: Mat3): Frustum =
  #eight points making up the near and far clipping "rectangles". order is counterclockwise, starting at bottom left
  let points = invProjView.prj([
    vec3(-1, -1, -1), vec3(1, -1, -1), vec3(1, 1, -1), vec3(-1, 1, -1),
    vec3(-1, -1, 1), vec3(1, -1, 1), vec3(1, 1, 1), vec3(-1, 1, 1)
  ])
  return Frustum(planes: [
    initPlane(points[1], points[0], points[2]),
    initPlane(points[4], points[5], points[7]),
    initPlane(points[0], points[4], points[3]),
    initPlane(points[5], points[1], points[6]),
    initPlane(points[2], points[3], points[6]),
    initPlane(points[4], points[0], points[1])
  ])

#returns whether this frustum contains a point
proc contains*(frustum: Frustum, point: Vec3): bool =
  for plane in frustum.planes:
    if plane.test(point) == psBack: return false
  return true

#returns whether this frustum overlaps a sphere
proc contains*(self: Frustum, center: Vec3, radius: float32): bool =
  for i in 0..<6:
    if self.planes[i].normal.x * center.x + self.planes[i].normal.y * center.y + self.planes[i].normal.z * center.z < -radius - self.planes[i].dst: 
      return false
  return true

#endregion
#region CAMERA

#creates a new camera with standard parameters
proc newCam3*(): Cam3 = Cam3(
  fov: 67f,
  near: 1f,
  far: 100f,
  perspective: true,
  size: vec2(1f),
  direction: vec3(0, 0, -1),
  up: vec3(0, 1, 0),
  combined: idt3(),
  proj: idt3(),
  view: idt3(),
  invProjView: idt3()
)

#updates the camera's view/proj matrix
proc update*(cam: Cam3, size = cam.size) =
  cam.size = size
  if cam.perspective:
    cam.proj = projection3(cam.near.abs, cam.far.abs, cam.fov, cam.size.ratio)
  else:
    cam.proj = ortho3(-cam.size.x/2f, cam.size.x/2f, -cam.size.y/2f, cam.size.y/2f, cam.near, cam.far)
  
  cam.view = lookAt3(cam.pos, cam.pos + cam.direction, cam.up)
  cam.combined = cam.proj * cam.view
  cam.invProjView = cam.combined.inv()
  cam.frustum = initFrustum(cam.invProjView)

proc lookAt*(cam: Cam3, pos: Vec3) =
  let dir = nor(pos - cam.pos)
  if not dir.zero:
    let dt = dir.dot(cam.up)

    if abs(dt - 1) < 0.000000001f:
      #collinear
      cam.up = -cam.direction
    elif abs(dt + 1) < 0.000000001f:
      #collinear opposite
      cam.up = cam.direction
    
    cam.direction = dir
    cam.up = cam.direction.crs(cam.up).crs(cam.direction).nor()

#Translates a point given in screen coordinates to world space.
proc unproject*(cam: Cam3, coords: Vec3, viewPos: Vec2 = vec2(0, 0), viewSize: Vec2 = cam.size): Vec3 =
  let rel = coords.vec2 - viewPos
  return vec3((rel.x * 2f) / viewSize.x - 1f, (rel.y * 2f) / viewSize.y - 1f, 2 * coords.z - 1f).prj(cam.invProjView)

#Projects the coordinates given in world space to screen coordinates.
proc project*(cam: Cam3, coords: Vec3, viewPos: Vec2 = vec2(0, 0), viewSize: Vec2 = cam.size): Vec3 =
  let wc = coords.prj(cam.combined)
  return vec3(viewSize.x * (wc.x + 1)/2f + viewPos.x, viewSize.y * (wc.y + 1)/2f + viewPos.y, (wc.z + 1f) / 2f)

#Creates a picking ray from the coordinates given in screen coordinates.
proc pickRay*(cam: Cam3, coords: Vec2, viewPos = vec2(0, 0), viewSize = cam.size): Ray =
  result.origin = cam.unproject(vec3(coords, 0f), viewPos, viewSize)
  result.direction = (cam.unproject(vec3(coords, 1f), viewPos, viewSize) - result.origin).nor

#endregion
#region MESH



#endregion