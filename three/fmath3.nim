
import math, fmath

# VECTORS

type Vec3* = object
  x*, y*, z*: float32

template vec3*(cx, cy, cz: float32): Vec3 = Vec3(x: cx, y: cy, z: cz)

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

# MATRICES

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

#4x4 matrix for 3D transformations - called Mat3 for Vec3 consistency
type Mat3* = array[16, float32]

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
proc `*`*(a, b: Mat3): Mat3 = [
  a[M00] * b[M00] + a[M01] * b[M10] + a[M02] * b[M20] + a[M03] * b[M30],
  a[M00] * b[M01] + a[M01] * b[M11] + a[M02] * b[M21] + a[M03] * b[M31],
  a[M00] * b[M02] + a[M01] * b[M12] + a[M02] * b[M22] + a[M03] * b[M32],
  a[M00] * b[M03] + a[M01] * b[M13] + a[M02] * b[M23] + a[M03] * b[M33],
  a[M10] * b[M00] + a[M11] * b[M10] + a[M12] * b[M20] + a[M13] * b[M30],
  a[M10] * b[M01] + a[M11] * b[M11] + a[M12] * b[M21] + a[M13] * b[M31],
  a[M10] * b[M02] + a[M11] * b[M12] + a[M12] * b[M22] + a[M13] * b[M32],
  a[M10] * b[M03] + a[M11] * b[M13] + a[M12] * b[M23] + a[M13] * b[M33],
  a[M20] * b[M00] + a[M21] * b[M10] + a[M22] * b[M20] + a[M23] * b[M30],
  a[M20] * b[M01] + a[M21] * b[M11] + a[M22] * b[M21] + a[M23] * b[M31],
  a[M20] * b[M02] + a[M21] * b[M12] + a[M22] * b[M22] + a[M23] * b[M32],
  a[M20] * b[M03] + a[M21] * b[M13] + a[M22] * b[M23] + a[M23] * b[M33],
  a[M30] * b[M00] + a[M31] * b[M10] + a[M32] * b[M20] + a[M33] * b[M30],
  a[M30] * b[M01] + a[M31] * b[M11] + a[M32] * b[M21] + a[M33] * b[M31],
  a[M30] * b[M02] + a[M31] * b[M12] + a[M32] * b[M22] + a[M33] * b[M32],
  a[M30] * b[M03] + a[M31] * b[M13] + a[M32] * b[M23] + a[M33] * b[M33]
]
  
#creates a projection matrix with a near- and far plane, a field of view in degrees and an aspect ratio. 
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
  #TODO trans3 + multiply
  return lookAt3(target - position, up) * trans3(-position)

# CAMERAS

#3D camera - TODO make object, or not?
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
  combined: Mat3
  #projection matrix
  proj: Mat3
  #view matrix
  view: Mat3
  #inverse combined projection and view matrix
  invProjView: Mat3
  #TODO
  #frustrum: Frustrum

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
proc update*(cam: Cam3) =
  if cam.perspective:
    cam.proj = projection3(cam.near.abs, cam.far.abs, cam.fov, cam.size.ratio)
  else:
    cam.proj = ortho3(-cam.size.x/2f, cam.size.x/2f, -cam.size.y/2f, cam.size.y/2f, cam.near, cam.near)
  
  cam.view = lookAt3(cam.pos, cam.pos + cam.direction, cam.up)
  cam.combined = cam.proj * cam.view
  cam.invProjView = cam.combined.inv()
  #TODO frustrum

proc resize*(cam: Cam3, size: Vec2) = 
  cam.size = size
  cam.update()

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

#TODO project, unproject