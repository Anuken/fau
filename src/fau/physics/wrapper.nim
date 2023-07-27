## This module wraps and compiles Chipmunk2D without using CMake. Do not include directly.

import std/macros
import std/os

# TODO doesn't work on windows because /tmp/
const
  baseDir = "/tmp/chipmunk"
  inclDir = baseDir & "/include"
  srcDir = baseDir & "/src"
{.passC: "-I" & inclDir.}

# fetch chimpunk
static:
  if not dirExists(baseDir) or defined(clearCache):
    echo "Fetching Chipmunk repo..."
    if dirExists(baseDir): echo staticExec("rm -rf " & baseDir)
    echo staticExec("git clone --depth 1 --branch Chipmunk-7.0.3 https://github.com/slembcke/Chipmunk2D " & baseDir)

# set up types

when defined(rapidChipmunkUseFloat64):
  {.passC: "-DCP_USE_DOUBLES=1".}
else:
  {.passC: "-DCP_USE_DOUBLES=0".}

{.passC: "-DCP_COLLISION_TYPE_TYPE=uint16_t".}
{.passC: "-DCP_BITMASK_TYPE=uint64_t".}

# disable debug messages because they're annoying
# this also disables runtime assertions which is a bit trash but i don't want
# chipmunk spamming my console output
# DEAR LIBRARY DEVELOPERS: DON'T WRITE TO STDOUT IN YOUR LIBRARIES.
# SIGNED, LQDEV
# 11 OCTOBER 2020

when not defined(debug):
  {.passC: "-DNDEBUG".}

macro genCompiles: untyped =
  var
    compileList = @[
      "chipmunk.c",
      "cpArbiter.c",
      "cpArray.c",
      "cpBBTree.c",
      "cpBody.c",
      "cpCollision.c",
      "cpConstraint.c",
      "cpDampedRotarySpring.c",
      "cpDampedSpring.c",
      "cpGearJoint.c",
      "cpGrooveJoint.c",
      "cpHashSet.c",
      "cpMarch.c",
      "cpPinJoint.c",
      "cpPivotJoint.c",
      "cpPolyShape.c",
      "cpPolyline.c",
      "cpRatchetJoint.c",
      "cpRobust.c",
      "cpRotaryLimitJoint.c",
      "cpShape.c",
      "cpSimpleMotor.c",
      "cpSlideJoint.c",
      "cpSpace.c",
      "cpSpaceComponent.c",
      "cpSpaceDebug.c",
      "cpSpaceHash.c",
      "cpSpaceQuery.c",
      "cpSpaceStep.c",
      "cpSpatialIndex.c",
      "cpSweep1D.c",
    ]
  when compileOption("threads"):
    compileList.add "cpHastySpace.c"
  var pragmas = newNimNode(nnkPragma)
  for file in compileList:
    pragmas.add(newColonExpr(ident"compile", newLit(srcDir & "/" & file)))
  result = newStmtList(pragmas)
genCompiles

#TODO should run after git clone happens
#const ChipmunkLicense* = slurp(baseDir & "/LICENSE.txt")
## The Chipmunk2D license. You're legally required to credit Chipmunk
## somewhere in your application's credits if you're using it for simulating
## physics.

## Copyright (c) 2013 Scott Lembcke and Howling Moon Software
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
##

import std/math

proc cpMessage*(condition: cstring; file: cstring; line: cint; isError: cint;
               isHardError: cint; message: cstring) {.varargs, importc: "cpMessage",
    header: "<chipmunk/chipmunk.h>".}

when sizeof(pointer) == 8:
  type
    uintptr_t* = culong
else:
  type
    uintptr_t* = cuint

## Chipmunk 7.0.3

const
  CP_VERSION_MAJOR* = 7
  CP_VERSION_MINOR* = 0
  CP_VERSION_RELEASE* = 3
  CP_USE_DOUBLES* = defined(chipmunkUseFloat64)
## Most of these types can be configured at compile time.

when CP_USE_DOUBLES:
  ## Chipmunk's floating point type.
  ## Can be reconfigured at compile time.
  type
    cpFloat* = cdouble
else:
  type
    cpFloat* = cfloat

## Return the max of two cpFloats.

proc cpfmax*(a: cpFloat; b: cpFloat): cpFloat {.inline.} =
  return if (a > b): a else: b

## Return the min of two cpFloats.

proc cpfmin*(a: cpFloat; b: cpFloat): cpFloat {.inline.} =
  return if (a < b): a else: b

## Return the absolute value of a cpFloat.

proc cpfabs*(f: cpFloat): cpFloat {.inline.} =
  return if (f < 0): -f else: f

## Clamp @c f to be between @c min and @c max.

proc cpfclamp*(f: cpFloat; min: cpFloat; max: cpFloat): cpFloat {.inline.} =
  return cpfmin(cpfmax(f, min), max)

## Clamp @c f to be between 0 and 1.

proc cpfclamp01*(f: cpFloat): cpFloat {.inline.} =
  return cpfmax(0.0, cpfmin(f, 1.0))

## Linearly interpolate (or extrapolate) between @c f1 and @c f2 by @c t percent.

proc cpflerp*(f1: cpFloat; f2: cpFloat; t: cpFloat): cpFloat {.inline.} =
  return f1 * (1.0 - t) + f2 * t

## Linearly interpolate from @c f1 to @c f2 by no more than @c d.

proc cpflerpconst*(f1: cpFloat; f2: cpFloat; d: cpFloat): cpFloat {.inline.} =
  return f1 + cpfclamp(f2 - f1, -d, d)

## Hash value type.

type
  cpHashValue* = uintptr_t
## Type used internally to cache colliding object info for cpCollideShapes().
## Should be at least 32 bits.

type
  cpCollisionID* = uint32

## Oh C, how we love to define our own boolean types to get compiler compatibility
## Chipmunk's boolean type.

type
  cpBool* = cuchar
## Type used for user data pointers.
type
  cpDataPointer* = pointer
## Type used for cpSpace.collision_type.
type
  cpCollisionType* = uint16
## Type used for cpShape.group.
type
  cpGroup* = uintptr_t
## Type used for cpShapeFilter category and mask.
type
  cpBitmask* = uint64
## Type used for various timestamps in Chipmunk.
type
  cpTimestamp* = cuint

{.pragma: cpstruct, importc, header: "<chipmunk/chipmunk.h>".}

## Chipmunk's 2D vector type.
## @addtogroup cpVect
type
  cpVect* {.cpstruct.} = object
    x*: cpFloat
    y*: cpFloat

## Column major affine transform.
type
  cpTransform* {.cpstruct.} = object
    a*: cpFloat
    b*: cpFloat
    c*: cpFloat
    d*: cpFloat
    tx*: cpFloat
    ty*: cpFloat

## NUKE

type
  cpMat2x2* {.cpstruct.} = object
    a*: cpFloat                ## Row major [[a, b][c d]]
    b*: cpFloat
    c*: cpFloat
    d*: cpFloat

## Chipmunk's axis-aligned 2D bounding box type. (left, bottom, right, top)

type
  cpBB* {.bycopy.} = object
    l*: cpFloat
    b*: cpFloat
    r*: cpFloat
    t*: cpFloat

{.pragma: cpistruct, importc, incompleteStruct, header: "<chipmunk/chipmunk.h>".}

type
  cpShape* {.cpistruct.} = object
  cpCircleShape* {.cpistruct.} = object
  cpSegmentShape* {.cpistruct.} = object
  cpPolyShape* {.cpistruct.} = object
  cpArbiter* {.cpistruct.} = object
  cpSpace* {.cpistruct.} = object
  cpBody* {.cpistruct.} = object
  cpConstraint* {.cpistruct.} = object
  cpPinJoint* {.cpistruct.} = object
  cpSlideJoint* {.cpistruct.} = object
  cpPivotJoint* {.cpistruct.} = object
  cpGrooveJoint* {.cpistruct.} = object
  cpDampedSpring* {.cpistruct.} = object
  cpDampedRotarySpring* {.cpistruct.} = object
  cpRotaryLimitJoint* {.cpistruct.} = object
  cpRatchetJoint* {.cpistruct.} = object
  cpGearJoint* {.cpistruct.} = object
  cpSimpleMotorJoint* {.cpistruct.} = object

var cpvzero*: cpVect = cpVect(x: 0.0, y: 0.0)

## Convenience constructor for cpVect structs.

proc cpv*(x: cpFloat; y: cpFloat): cpVect {.inline.} =
  var v: cpVect = cpVect(x: x, y: y)
  return v

## Check if two vectors are equal. (Be careful when comparing floating point numbers!)

proc cpveql*(v1: cpVect; v2: cpVect): bool {.inline.} =
  return v1.x == v2.x and v1.y == v2.y

## Add two vectors

proc cpvadd*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpv(v1.x + v2.x, v1.y + v2.y)

## Subtract two vectors.

proc cpvsub*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpv(v1.x - v2.x, v1.y - v2.y)

## Negate a vector.

proc cpvneg*(v: cpVect): cpVect {.inline.} =
  return cpv(-v.x, -v.y)

## Scalar multiplication.

proc cpvmult*(v: cpVect; s: cpFloat): cpVect {.inline.} =
  return cpv(v.x * s, v.y * s)

## Vector dot product.

proc cpvdot*(v1: cpVect; v2: cpVect): cpFloat {.inline.} =
  return v1.x * v2.x + v1.y * v2.y

## 2D vector cross product analog.
## The cross product of 2D vectors results in a 3D vector with only a z component.
## This function returns the magnitude of the z value.

proc cpvcross*(v1: cpVect; v2: cpVect): cpFloat {.inline.} =
  return v1.x * v2.y - v1.y * v2.x

## Returns a perpendicular vector. (90 degree rotation)

proc cpvperp*(v: cpVect): cpVect {.inline.} =
  return cpv(-v.y, v.x)

## Returns a perpendicular vector. (-90 degree rotation)

proc cpvrperp*(v: cpVect): cpVect {.inline.} =
  return cpv(v.y, -v.x)

## Returns the vector projection of v1 onto v2.

proc cpvproject*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpvmult(v2, cpvdot(v1, v2) / cpvdot(v2, v2))

## Returns the unit length vector for the given angle (in radians).

proc cpvforangle*(a: cpFloat): cpVect {.inline.} =
  return cpv(cos(a), sin(a))

## Returns the angular direction v is pointing in (in radians).

proc cpvtoangle*(v: cpVect): cpFloat {.inline.} =
  return arctan2(v.y, v.x)

## Uses complex number multiplication to rotate v1 by v2. Scaling will occur if v1 is not a unit vector.

proc cpvrotate*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpv(v1.x * v2.x - v1.y * v2.y, v1.x * v2.y + v1.y * v2.x)

## Inverse of cpvrotate().

proc cpvunrotate*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpv(v1.x * v2.x + v1.y * v2.y, v1.y * v2.x - v1.x * v2.y)

## Returns the squared length of v. Faster than cpvlength() when you only need to compare lengths.

proc cpvlengthsq*(v: cpVect): cpFloat {.inline.} =
  return cpvdot(v, v)

## Returns the length of v.

proc cpvlength*(v: cpVect): cpFloat {.inline.} =
  return sqrt(cpvdot(v, v))

## Linearly interpolate between v1 and v2.

proc cpvlerp*(v1: cpVect; v2: cpVect; t: cpFloat): cpVect {.inline.} =
  return cpvadd(cpvmult(v1, 1.0 - t), cpvmult(v2, t))

## Returns a normalized copy of v.

proc cpvnormalize*(v: cpVect): cpVect {.inline.} =
  ## Neat trick I saw somewhere to avoid div/0.
  return cpvmult(v, 1.0 / (cpvlength(v) + 0.000001))

## Spherical linearly interpolate between v1 and v2.

proc cpvslerp*(v1: cpVect; v2: cpVect; t: cpFloat): cpVect {.inline.} =
  var dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2))
  var omega: cpFloat = arccos(cpfclamp(dot, -1.0, 1.0))
  if omega < 0.001:
    ## If the angle between two vectors is very small, lerp instead to avoid precision issues.
    return cpvlerp(v1, v2, t)
  else:
    var denom: cpFloat = 1.0 / sin(omega)
    return cpvadd(cpvmult(v1, sin((1.0 - t) * omega) * denom),
                 cpvmult(v2, sin(t * omega) * denom))

## Spherical linearly interpolate between v1 towards v2 by no more than angle a radians

proc cpvslerpconst*(v1: cpVect; v2: cpVect; a: cpFloat): cpVect {.inline.} =
  var dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2))
  var omega: cpFloat = arccos(cpfclamp(dot, -1.0, 1.0))
  return cpvslerp(v1, v2, cpfmin(a, omega) / omega)

## Clamp v to length len.

proc cpvclamp*(v: cpVect; len: cpFloat): cpVect {.inline.} =
  return if (cpvdot(v, v) > len * len): cpvmult(cpvnormalize(v), len) else: v

## Linearly interpolate between v1 towards v2 by distance d.

proc cpvlerpconst*(v1: cpVect; v2: cpVect; d: cpFloat): cpVect {.inline.} =
  return cpvadd(v1, cpvclamp(cpvsub(v2, v1), d))

## Returns the distance between v1 and v2.

proc cpvdist*(v1: cpVect; v2: cpVect): cpFloat {.inline.} =
  return cpvlength(cpvsub(v1, v2))

## Returns the squared distance between v1 and v2. Faster than cpvdist() when you only need to compare distances.

proc cpvdistsq*(v1: cpVect; v2: cpVect): cpFloat {.inline.} =
  return cpvlengthsq(cpvsub(v1, v2))

## Returns true if the distance between v1 and v2 is less than dist.

proc cpvnear*(v1: cpVect; v2: cpVect; dist: cpFloat): bool {.inline.} =
  return cpvdistsq(v1, v2) < dist * dist

## 2x2 matrix type used for tensors and such.

proc cpMat2x2New*(a: cpFloat; b: cpFloat; c: cpFloat; d: cpFloat): cpMat2x2 {.inline.} =
  var m: cpMat2x2 = cpMat2x2(a: a, b: b, c: c, d: d)
  return m

proc cpMat2x2Transform*(m: cpMat2x2; v: cpVect): cpVect {.inline.} =
  return cpv(v.x * m.a + v.y * m.b, v.x * m.c + v.y * m.d)

## Convenience constructor for cpBB structs.

proc cpBBNew*(l: cpFloat; b: cpFloat; r: cpFloat; t: cpFloat): cpBB {.inline.} =
  var bb: cpBB = cpBB(l: l, b: b, r: r, t: t)
  return bb

## Constructs a cpBB centered on a point with the given extents (half sizes).

proc cpBBNewForExtents*(c: cpVect; hw: cpFloat; hh: cpFloat): cpBB {.inline.} =
  return cpBBNew(c.x - hw, c.y - hh, c.x + hw, c.y + hh)

## Constructs a cpBB for a circle with the given position and radius.

proc cpBBNewForCircle*(p: cpVect; r: cpFloat): cpBB {.inline.} =
  return cpBBNewForExtents(p, r, r)

## Returns true if @c a and @c b intersect.

proc cpBBIntersects*(a: cpBB; b: cpBB): bool {.inline.} =
  return a.l <= b.r and b.l <= a.r and a.b <= b.t and b.b <= a.t

## Returns true if @c other lies completely within @c bb.

proc cpBBContainsBB*(bb: cpBB; other: cpBB): bool {.inline.} =
  return bb.l <= other.l and bb.r >= other.r and bb.b <= other.b and bb.t >= other.t

## Returns true if @c bb contains @c v.

proc cpBBContainsVect*(bb: cpBB; v: cpVect): bool {.inline.} =
  return bb.l <= v.x and bb.r >= v.x and bb.b <= v.y and bb.t >= v.y

## Returns a bounding box that holds both bounding boxes.

proc cpBBMerge*(a: cpBB; b: cpBB): cpBB {.inline.} =
  return cpBBNew(cpfmin(a.l, b.l), cpfmin(a.b, b.b), cpfmax(a.r, b.r), cpfmax(a.t, b.t))

## Returns a bounding box that holds both @c bb and @c v.

proc cpBBExpand*(bb: cpBB; v: cpVect): cpBB {.inline.} =
  return cpBBNew(cpfmin(bb.l, v.x), cpfmin(bb.b, v.y), cpfmax(bb.r, v.x),
                cpfmax(bb.t, v.y))

## Returns the center of a bounding box.

proc cpBBCenter*(bb: cpBB): cpVect {.inline.} =
  return cpvlerp(cpv(bb.l, bb.b), cpv(bb.r, bb.t), 0.5)

## Returns the area of the bounding box.

proc cpBBArea*(bb: cpBB): cpFloat {.inline.} =
  return (bb.r - bb.l) * (bb.t - bb.b)

## Merges @c a and @c b and returns the area of the merged bounding box.

proc cpBBMergedArea*(a: cpBB; b: cpBB): cpFloat {.inline.} =
  return (cpfmax(a.r, b.r) - cpfmin(a.l, b.l)) *
      (cpfmax(a.t, b.t) - cpfmin(a.b, b.b))

## Returns the fraction along the segment query the cpBB is hit. Returns INFINITY if it doesn't hit.

proc cpBBSegmentQuery*(bb: cpBB; a: cpVect; b: cpVect): cpFloat {.inline.} =
  var delta: cpVect = cpvsub(b, a)
  var
    tmin: cpFloat = -Inf
    tmax: cpFloat = Inf
  if delta.x == 0.0:
    if a.x < bb.l or bb.r < a.x:
      return Inf
  else:
    var t1: cpFloat = (bb.l - a.x) / delta.x
    var t2: cpFloat = (bb.r - a.x) / delta.x
    tmin = cpfmax(tmin, cpfmin(t1, t2))
    tmax = cpfmin(tmax, cpfmax(t1, t2))
  if delta.y == 0.0:
    if a.y < bb.b or bb.t < a.y:
      return Inf
  else:
    var t1: cpFloat = (bb.b - a.y) / delta.y
    var t2: cpFloat = (bb.t - a.y) / delta.y
    tmin = cpfmax(tmin, cpfmin(t1, t2))
    tmax = cpfmin(tmax, cpfmax(t1, t2))
  if tmin <= tmax and 0.0 <= tmax and tmin <= 1.0:
    return cpfmax(tmin, 0.0)
  else:
    return Inf

## Return true if the bounding box intersects the line segment with ends @c a and @c b.

proc cpBBIntersectsSegment*(bb: cpBB; a: cpVect; b: cpVect): bool {.inline.} =
  return cpBBSegmentQuery(bb, a, b) != Inf

## Clamp a vector to a bounding box.

proc cpBBClampVect*(bb: cpBB; v: cpVect): cpVect {.inline.} =
  return cpv(cpfclamp(v.x, bb.l, bb.r), cpfclamp(v.y, bb.b, bb.t))

## Wrap a vector to a bounding box.

proc cpBBWrapVect*(bb: cpBB; v: cpVect): cpVect {.inline.} =
  var dx: cpFloat = cpfabs(bb.r - bb.l)
  var modx: cpFloat = floorMod(v.x - bb.l, dx)
  var x: cpFloat = if (modx > 0.0): modx else: modx + dx
  var dy: cpFloat = cpfabs(bb.t - bb.b)
  var mody: cpFloat = floorMod(v.y - bb.b, dy)
  var y: cpFloat = if (mody > 0.0): mody else: mody + dy
  return cpv(x + bb.l, y + bb.b)

## Returns a bounding box offseted by @c v.

proc cpBBOffset*(bb: cpBB; v: cpVect): cpBB {.inline.} =
  return cpBBNew(bb.l + v.x, bb.b + v.y, bb.r + v.x, bb.t + v.y)

## Identity transform matrix.

var cpTransformIdentity*: cpTransform = cpTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0)

## Construct a new transform matrix.
## (a, b) is the x basis vector.
## (c, d) is the y basis vector.
## (tx, ty) is the translation.

proc cpTransformNew*(a: cpFloat; b: cpFloat; c: cpFloat; d: cpFloat; tx: cpFloat;
                    ty: cpFloat): cpTransform {.inline.} =
  var t: cpTransform = cpTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
  return t

## Construct a new transform matrix in transposed order.

proc cpTransformNewTranspose*(a: cpFloat; c: cpFloat; tx: cpFloat; b: cpFloat;
                             d: cpFloat; ty: cpFloat): cpTransform {.inline.} =
  var t: cpTransform = cpTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
  return t

## Get the inverse of a transform matrix.

proc cpTransformInverse*(t: cpTransform): cpTransform {.inline.} =
  var inv_det: cpFloat = 1.0 / (t.a * t.d - t.c * t.b)
  return cpTransformNewTranspose(t.d * inv_det, -(t.c * inv_det),
                                (t.c * t.ty - t.tx * t.d) * inv_det, -(t.b * inv_det),
                                t.a * inv_det, (t.tx * t.b - t.a * t.ty) * inv_det)

## Multiply two transformation matrices.

proc cpTransformMult*(t1: cpTransform; t2: cpTransform): cpTransform {.inline.} =
  return cpTransformNewTranspose(t1.a * t2.a + t1.c * t2.b, t1.a * t2.c + t1.c * t2.d,
                                t1.a * t2.tx + t1.c * t2.ty + t1.tx,
                                t1.b * t2.a + t1.d * t2.b, t1.b * t2.c + t1.d * t2.d,
                                t1.b * t2.tx + t1.d * t2.ty + t1.ty)

## Transform an absolute point. (i.e. a vertex)

proc cpTransformPoint*(t: cpTransform; p: cpVect): cpVect {.inline.} =
  return cpv(t.a * p.x + t.c * p.y + t.tx, t.b * p.x + t.d * p.y + t.ty)

## Transform a vector (i.e. a normal)

proc cpTransformVect*(t: cpTransform; v: cpVect): cpVect {.inline.} =
  return cpv(t.a * v.x + t.c * v.y, t.b * v.x + t.d * v.y)

## Transform a cpBB.

proc cpTransformbBB*(t: cpTransform; bb: cpBB): cpBB {.inline.} =
  var center: cpVect = cpBBCenter(bb)
  var hw: cpFloat = (bb.r - bb.l) * 0.5
  var hh: cpFloat = (bb.t - bb.b) * 0.5
  var
    a: cpFloat = t.a * hw
    b: cpFloat = t.c * hh
    d: cpFloat = t.b * hw
    e: cpFloat = t.d * hh
  var hw_max: cpFloat = cpfmax(cpfabs(a + b), cpfabs(a - b))
  var hh_max: cpFloat = cpfmax(cpfabs(d + e), cpfabs(d - e))
  return cpBBNewForExtents(cpTransformPoint(t, center), hw_max, hh_max)

## Create a transation matrix.

proc cpTransformTranslate*(translate: cpVect): cpTransform {.inline.} =
  return cpTransformNewTranspose(1.0, 0.0, translate.x, 0.0, 1.0, translate.y)

## Create a scale matrix.

proc cpTransformScale*(scaleX: cpFloat; scaleY: cpFloat): cpTransform {.inline.} =
  return cpTransformNewTranspose(scaleX, 0.0, 0.0, 0.0, scaleY, 0.0)

## Create a rotation matrix.

proc cpTransformRotate*(radians: cpFloat): cpTransform {.inline.} =
  var rot: cpVect = cpvforangle(radians)
  return cpTransformNewTranspose(rot.x, -rot.y, 0.0, rot.y, rot.x, 0.0)

## Create a rigid transformation matrix. (transation + rotation)

proc cpTransformRigid*(translate: cpVect; radians: cpFloat): cpTransform {.inline.} =
  var rot: cpVect = cpvforangle(radians)
  return cpTransformNewTranspose(rot.x, -rot.y, translate.x, rot.y, rot.x, translate.y)

## Fast inverse of a rigid transformation matrix.

proc cpTransformRigidInverse*(t: cpTransform): cpTransform {.inline.} =
  return cpTransformNewTranspose(t.d, -t.c, (t.c * t.ty - t.tx * t.d), -t.b, t.a,
                                (t.tx * t.b - t.a * t.ty))

## See source for documentation...

proc cpTransformWrap*(outer: cpTransform; inner: cpTransform): cpTransform {.inline.} =
  return cpTransformMult(cpTransformInverse(outer), cpTransformMult(inner, outer))

proc cpTransformWrapInverse*(outer: cpTransform; inner: cpTransform): cpTransform {.
    inline.} =
  return cpTransformMult(outer, cpTransformMult(inner, cpTransformInverse(outer)))

proc cpTransformOrtho*(bb: cpBB): cpTransform {.inline.} =
  return cpTransformNewTranspose(2.0 / (bb.r - bb.l), 0.0,
                                -((bb.r + bb.l) / (bb.r - bb.l)), 0.0,
                                2.0 / (bb.t - bb.b),
                                -((bb.t + bb.b) / (bb.t - bb.b)))

proc cpTransformBoneScale*(v0: cpVect; v1: cpVect): cpTransform {.inline.} =
  var d: cpVect = cpvsub(v1, v0)
  return cpTransformNewTranspose(d.x, -d.y, v0.x, d.y, d.x, v0.y)

proc cpTransformAxialScale*(axis: cpVect; pivot: cpVect; scale: cpFloat): cpTransform {.
    inline.} =
  var A: cpFloat = axis.x * axis.y * (scale - 1.0)
  var B: cpFloat = cpvdot(axis, pivot) * (1.0 - scale)
  return cpTransformNewTranspose(scale * axis.x * axis.x + axis.y * axis.y, A, axis.x * B, A,
                                axis.x * axis.x + scale * axis.y * axis.y, axis.y * B)


## 	Spatial indexes are data structures that are used to accelerate collision detection
## 	and spatial queries. Chipmunk provides a number of spatial index algorithms to pick from
## 	and they are programmed in a generic way so that you can use them for holding more than
## 	just cpShape structs.
## 	
## 	It works by using @c void pointers to the objects you add and using a callback to ask your code
## 	for bounding boxes when it needs them. Several types of queries can be performed an index as well
## 	as reindexing and full collision information. All communication to the spatial indexes is performed
## 	through callback functions.
## 	
## 	Spatial indexes should be treated as opaque structs.
## 	This meanns you shouldn't be reading any of the struct fields.
##
## Spatial index bounding box callback function type.
## The spatial index calls this function and passes you a pointer to an object you added
## when it needs to get the bounding box associated with that object.

type
  cpSpatialIndexBBFunc* = proc (obj: pointer): cpBB

## Spatial index/object iterator callback function type.

type
  cpSpatialIndexIteratorFunc* = proc (obj: pointer; data: pointer)

## Spatial query callback function type.

type
  cpSpatialIndexQueryFunc* = proc (obj1: pointer; obj2: pointer; id: cpCollisionID;
                                data: pointer): cpCollisionID

## Spatial segment query callback function type.

type
  cpSpatialIndexSegmentQueryFunc* = proc (obj1: pointer; obj2: pointer; data: pointer): cpFloat

## @private


type
  cpSpatialIndexDestroyImpl* = proc (index: ptr cpSpatialIndex)
  cpSpatialIndexCountImpl* = proc (index: ptr cpSpatialIndex): cint
  cpSpatialIndexEachImpl* = proc (index: ptr cpSpatialIndex;
                               `func`: cpSpatialIndexIteratorFunc; data: pointer)
  cpSpatialIndexContainsImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                   hashid: cpHashValue): cpBool
  cpSpatialIndexInsertImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                 hashid: cpHashValue)
  cpSpatialIndexRemoveImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                 hashid: cpHashValue)
  cpSpatialIndexReindexImpl* = proc (index: ptr cpSpatialIndex)
  cpSpatialIndexReindexObjectImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                        hashid: cpHashValue)
  cpSpatialIndexReindexQueryImpl* = proc (index: ptr cpSpatialIndex;
                                       `func`: cpSpatialIndexQueryFunc;
                                       data: pointer)
  cpSpatialIndexQueryImpl* = proc (index: ptr cpSpatialIndex; obj: pointer; bb: cpBB;
                                `func`: cpSpatialIndexQueryFunc; data: pointer)
  cpSpatialIndexSegmentQueryImpl* = proc (index: ptr cpSpatialIndex; obj: pointer;
                                       a: cpVect; b: cpVect; t_exit: cpFloat;
                                       `func`: cpSpatialIndexSegmentQueryFunc;
                                       data: pointer)
  cpSpatialIndexClass* {.importc: "cpSpatialIndexClass",
                        header: "<chipmunk/chipmunk.h>", bycopy.} = object
    destroy* {.importc: "destroy".}: cpSpatialIndexDestroyImpl
    count* {.importc: "count".}: cpSpatialIndexCountImpl
    each* {.importc: "each".}: cpSpatialIndexEachImpl
    contains* {.importc: "contains".}: cpSpatialIndexContainsImpl
    insert* {.importc: "insert".}: cpSpatialIndexInsertImpl
    remove* {.importc: "remove".}: cpSpatialIndexRemoveImpl
    reindex* {.importc: "reindex".}: cpSpatialIndexReindexImpl
    reindexObject* {.importc: "reindexObject".}: cpSpatialIndexReindexObjectImpl
    reindexQuery* {.importc: "reindexQuery".}: cpSpatialIndexReindexQueryImpl
    query* {.importc: "query".}: cpSpatialIndexQueryImpl
    segmentQuery* {.importc: "segmentQuery".}: cpSpatialIndexSegmentQueryImpl
  cpSpatialIndex* {.importc: "cpSpatialIndex", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    klass* {.importc: "klass".}: ptr cpSpatialIndexClass
    bbfunc* {.importc: "bbfunc".}: cpSpatialIndexBBFunc
    staticIndex* {.importc: "staticIndex".}: ptr cpSpatialIndex
    dynamicIndex* {.importc: "dynamicIndex".}: ptr cpSpatialIndex


## Allocate a spatial hash.

type cpSpaceHash* {.importc, incompleteStruct.} = object

proc cpSpaceHashAlloc*(): ptr cpSpaceHash {.importc: "cpSpaceHashAlloc",
                                        header: "<chipmunk/chipmunk.h>".}
## Initialize a spatial hash.

proc cpSpaceHashInit*(hash: ptr cpSpaceHash; celldim: cpFloat; numcells: cint;
                     bbfunc: cpSpatialIndexBBFunc; staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpSpaceHashInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a spatial hash.

proc cpSpaceHashNew*(celldim: cpFloat; cells: cint; bbfunc: cpSpatialIndexBBFunc;
                    staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpSpaceHashNew", header: "<chipmunk/chipmunk.h>".}
## Change the cell dimensions and table size of the spatial hash to tune it.
## The cell dimensions should roughly match the average size of your objects
## and the table size should be ~10 larger than the number of objects inserted.
## Some trial and error is required to find the optimum numbers for efficiency.

proc cpSpaceHashResize*(hash: ptr cpSpaceHash; celldim: cpFloat; numcells: cint) {.
    importc: "cpSpaceHashResize", header: "<chipmunk/chipmunk.h>".}

## Allocate a bounding box tree.

type cpBBTree* {.importc, incompleteStruct.} = object

proc cpBBTreeAlloc*(): ptr cpBBTree {.importc: "cpBBTreeAlloc",
                                  header: "<chipmunk/chipmunk.h>".}
## Initialize a bounding box tree.

proc cpBBTreeInit*(tree: ptr cpBBTree; bbfunc: cpSpatialIndexBBFunc;
                  staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpBBTreeInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a bounding box tree.

proc cpBBTreeNew*(bbfunc: cpSpatialIndexBBFunc; staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpBBTreeNew", header: "<chipmunk/chipmunk.h>".}
## Perform a static top down optimization of the tree.

proc cpBBTreeOptimize*(index: ptr cpSpatialIndex) {.importc: "cpBBTreeOptimize",
    header: "<chipmunk/chipmunk.h>".}
## Bounding box tree velocity callback function.
## This function should return an estimate for the object's velocity.

type
  cpBBTreeVelocityFunc* = proc (obj: pointer): cpVect

## Set the velocity function for the bounding box tree to enable temporal coherence.

proc cpBBTreeSetVelocityFunc*(index: ptr cpSpatialIndex;
                             `func`: cpBBTreeVelocityFunc) {.
    importc: "cpBBTreeSetVelocityFunc", header: "<chipmunk/chipmunk.h>".}

## Allocate a 1D sort and sweep broadphase.

type cpSweep1D* {.importc, incompleteStruct.} = object

proc cpSweep1DAlloc*(): ptr cpSweep1D {.importc: "cpSweep1DAlloc",
                                    header: "<chipmunk/chipmunk.h>".}
## Initialize a 1D sort and sweep broadphase.

proc cpSweep1DInit*(sweep: ptr cpSweep1D; bbfunc: cpSpatialIndexBBFunc;
                   staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpSweep1DInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a 1D sort and sweep broadphase.

proc cpSweep1DNew*(bbfunc: cpSpatialIndexBBFunc; staticIndex: ptr cpSpatialIndex): ptr cpSpatialIndex {.
    importc: "cpSweep1DNew", header: "<chipmunk/chipmunk.h>".}

## Destroy and free a spatial index.

proc cpSpatialIndexFree*(index: ptr cpSpatialIndex) {.importc: "cpSpatialIndexFree",
    header: "<chipmunk/chipmunk.h>".}
## Collide the objects in @c dynamicIndex against the objects in @c staticIndex using the query callback function.

proc cpSpatialIndexCollideStatic*(dynamicIndex: ptr cpSpatialIndex;
                                 staticIndex: ptr cpSpatialIndex;
                                 `func`: cpSpatialIndexQueryFunc; data: pointer) {.
    importc: "cpSpatialIndexCollideStatic", header: "<chipmunk/chipmunk.h>".}
## Destroy a spatial index.

proc cpSpatialIndexDestroy*(index: ptr cpSpatialIndex) {.inline.} =
  if index.klass != nil:
    index.klass.destroy(index)

## Get the number of objects in the spatial index.

proc cpSpatialIndexCount*(index: ptr cpSpatialIndex): cint {.inline.} =
  return index.klass.count(index)

## Iterate the objects in the spatial index. @c func will be called once for each object.

proc cpSpatialIndexEach*(index: ptr cpSpatialIndex;
                        `func`: cpSpatialIndexIteratorFunc; data: pointer) {.inline.} =
  index.klass.each(index, `func`, data)

## Returns true if the spatial index contains the given object.
## Most spatial indexes use hashed storage, so you must provide a hash value too.

proc cpSpatialIndexContains*(index: ptr cpSpatialIndex; obj: pointer;
                            hashid: cpHashValue): cpBool {.inline.} =
  return index.klass.contains(index, obj, hashid)

## Add an object to a spatial index.
## Most spatial indexes use hashed storage, so you must provide a hash value too.

proc cpSpatialIndexInsert*(index: ptr cpSpatialIndex; obj: pointer;
                          hashid: cpHashValue) {.inline.} =
  index.klass.insert(index, obj, hashid)

## Remove an object from a spatial index.
## Most spatial indexes use hashed storage, so you must provide a hash value too.

proc cpSpatialIndexRemove*(index: ptr cpSpatialIndex; obj: pointer;
                          hashid: cpHashValue) {.inline.} =
  index.klass.remove(index, obj, hashid)

## Perform a full reindex of a spatial index.

proc cpSpatialIndexReindex*(index: ptr cpSpatialIndex) {.inline.} =
  index.klass.reindex(index)

## Reindex a single object in the spatial index.

proc cpSpatialIndexReindexObject*(index: ptr cpSpatialIndex; obj: pointer;
                                 hashid: cpHashValue) {.inline.} =
  index.klass.reindexObject(index, obj, hashid)

## Perform a rectangle query against the spatial index, calling @c func for each potential match.

proc cpSpatialIndexQuery*(index: ptr cpSpatialIndex; obj: pointer; bb: cpBB;
                         `func`: cpSpatialIndexQueryFunc; data: pointer) {.inline.} =
  index.klass.query(index, obj, bb, `func`, data)

## Perform a segment query against the spatial index, calling @c func for each potential match.

proc cpSpatialIndexSegmentQuery*(index: ptr cpSpatialIndex; obj: pointer; a: cpVect;
                                b: cpVect; t_exit: cpFloat;
                                `func`: cpSpatialIndexSegmentQueryFunc;
                                data: pointer) {.inline.} =
  index.klass.segmentQuery(index, obj, a, b, t_exit, `func`, data)

## Simultaneously reindex and find all colliding objects.
## @c func will be called once for each potentially overlapping pair of objects found.
## If the spatial index was initialized with a static index, it will collide it's objects against that as well.

proc cpSpatialIndexReindexQuery*(index: ptr cpSpatialIndex;
                                `func`: cpSpatialIndexQueryFunc; data: pointer) {.
    inline.} =
  index.klass.reindexQuery(index, `func`, data)

## The cpArbiter struct tracks pairs of colliding shapes.
## They are also used in conjuction with collision handler callbacks
## allowing you to retrieve information on the collision or change it.
## A unique arbiter value is used for each pair of colliding objects. It persists until the shapes separate.

const
  CP_MAX_CONTACTS_PER_ARBITER* = 2

## Get the restitution (elasticity) that will be applied to the pair of colliding objects.

proc cpArbiterGetRestitution*(arb: ptr cpArbiter): cpFloat {.
    importc: "cpArbiterGetRestitution", header: "<chipmunk/chipmunk.h>".}
## Override the restitution (elasticity) that will be applied to the pair of colliding objects.

proc cpArbiterSetRestitution*(arb: ptr cpArbiter; restitution: cpFloat) {.
    importc: "cpArbiterSetRestitution", header: "<chipmunk/chipmunk.h>".}
## Get the friction coefficient that will be applied to the pair of colliding objects.

proc cpArbiterGetFriction*(arb: ptr cpArbiter): cpFloat {.
    importc: "cpArbiterGetFriction", header: "<chipmunk/chipmunk.h>".}
## Override the friction coefficient that will be applied to the pair of colliding objects.

proc cpArbiterSetFriction*(arb: ptr cpArbiter; friction: cpFloat) {.
    importc: "cpArbiterSetFriction", header: "<chipmunk/chipmunk.h>".}
## Get the relative surface velocity of the two shapes in contact.

proc cpArbiterGetSurfaceVelocity*(arb: ptr cpArbiter): cpVect {.
    importc: "cpArbiterGetSurfaceVelocity", header: "<chipmunk/chipmunk.h>".}
## Override the relative surface velocity of the two shapes in contact.
## By default this is calculated to be the difference of the two surface velocities clamped to the tangent plane.

proc cpArbiterSetSurfaceVelocity*(arb: ptr cpArbiter; vr: cpVect) {.
    importc: "cpArbiterSetSurfaceVelocity", header: "<chipmunk/chipmunk.h>".}
## Get the user data pointer associated with this pair of colliding objects.

proc cpArbiterGetUserData*(arb: ptr cpArbiter): cpDataPointer {.
    importc: "cpArbiterGetUserData", header: "<chipmunk/chipmunk.h>".}
## Set a user data point associated with this pair of colliding objects.
## If you need to perform any cleanup for this pointer, you must do it yourself, in the separate callback for instance.

proc cpArbiterSetUserData*(arb: ptr cpArbiter; userData: cpDataPointer) {.
    importc: "cpArbiterSetUserData", header: "<chipmunk/chipmunk.h>".}
## Calculate the total impulse including the friction that was applied by this arbiter.
## This function should only be called from a post-solve, post-step or cpBodyEachArbiter callback.

proc cpArbiterTotalImpulse*(arb: ptr cpArbiter): cpVect {.
    importc: "cpArbiterTotalImpulse", header: "<chipmunk/chipmunk.h>".}
## Calculate the amount of energy lost in a collision including static, but not dynamic friction.
## This function should only be called from a post-solve, post-step or cpBodyEachArbiter callback.

proc cpArbiterTotalKE*(arb: ptr cpArbiter): cpFloat {.importc: "cpArbiterTotalKE",
    header: "<chipmunk/chipmunk.h>".}
## Mark a collision pair to be ignored until the two objects separate.
## Pre-solve and post-solve callbacks will not be called, but the separate callback will be called.

proc cpArbiterIgnore*(arb: ptr cpArbiter): cpBool {.importc: "cpArbiterIgnore",
    header: "<chipmunk/chipmunk.h>".}
## Return the colliding shapes involved for this arbiter.
## The order of their cpSpace.collision_type values will match
## the order set when the collision handler was registered.

proc cpArbiterGetShapes*(arb: ptr cpArbiter; a: ptr ptr cpShape; b: ptr ptr cpShape) {.
    importc: "cpArbiterGetShapes", header: "<chipmunk/chipmunk.h>".}
## A macro shortcut for defining and retrieving the shapes from an arbiter.
## #define CP_ARBITER_GET_SHAPES(__arb__, __a__, __b__) cpShape *__a__, *__b__; cpArbiterGetShapes(__arb__, &__a__, &__b__);

proc cpArbiterGetBodies*(arb: ptr cpArbiter; a: ptr ptr cpBody; b: ptr ptr cpBody) {.
    importc: "cpArbiterGetBodies", header: "<chipmunk/chipmunk.h>".}
## A macro shortcut for defining and retrieving the bodies from an arbiter.
## #define CP_ARBITER_GET_BODIES(__arb__, __a__, __b__) cpBody *__a__, *__b__; cpArbiterGetBodies(__arb__, &__a__, &__b__);
## A struct that wraps up the important collision data for an arbiter.

type
  INNER_C_STRUCT_cpArbiter_88* {.importc: "no_name", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    pointA* {.importc: "pointA".}: cpVect ## The position of the contact on the surface of each shape.
    pointB* {.importc: "pointB".}: cpVect ## Penetration distance of the two shapes. Overlapping means it will be negative.
                                      ## This value is calculated as cpvdot(cpvsub(point2, point1), normal) and is ignored by cpArbiterSetContactPointSet().
    distance* {.importc: "distance".}: cpFloat

  cpContactPointSet* {.importc: "cpContactPointSet", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    count* {.importc: "count".}: cint ## The number of contact points in the set.
    ## The normal of the collision.
    normal* {.importc: "normal".}: cpVect ## The array of contact points.
    points* {.importc: "points".}: array[CP_MAX_CONTACTS_PER_ARBITER,
                                      INNER_C_STRUCT_cpArbiter_88]


## Return a contact set from an arbiter.

proc cpArbiterGetContactPointSet*(arb: ptr cpArbiter): cpContactPointSet {.
    importc: "cpArbiterGetContactPointSet", header: "<chipmunk/chipmunk.h>".}
## Replace the contact point set for an arbiter.
## This can be a very powerful feature, but use it with caution!

proc cpArbiterSetContactPointSet*(arb: ptr cpArbiter; set: ptr cpContactPointSet) {.
    importc: "cpArbiterSetContactPointSet", header: "<chipmunk/chipmunk.h>".}
## Returns true if this is the first step a pair of objects started colliding.

proc cpArbiterIsFirstContact*(arb: ptr cpArbiter): cpBool {.
    importc: "cpArbiterIsFirstContact", header: "<chipmunk/chipmunk.h>".}
## Returns true if the separate callback is due to a shape being removed from the space.

proc cpArbiterIsRemoval*(arb: ptr cpArbiter): cpBool {.importc: "cpArbiterIsRemoval",
    header: "<chipmunk/chipmunk.h>".}
## Get the number of contact points for this arbiter.

proc cpArbiterGetCount*(arb: ptr cpArbiter): cint {.importc: "cpArbiterGetCount",
    header: "<chipmunk/chipmunk.h>".}
## Get the normal of the collision.

proc cpArbiterGetNormal*(arb: ptr cpArbiter): cpVect {.importc: "cpArbiterGetNormal",
    header: "<chipmunk/chipmunk.h>".}
## Get the position of the @c ith contact point on the surface of the first shape.

proc cpArbiterGetPointA*(arb: ptr cpArbiter; i: cint): cpVect {.
    importc: "cpArbiterGetPointA", header: "<chipmunk/chipmunk.h>".}
## Get the position of the @c ith contact point on the surface of the second shape.

proc cpArbiterGetPointB*(arb: ptr cpArbiter; i: cint): cpVect {.
    importc: "cpArbiterGetPointB", header: "<chipmunk/chipmunk.h>".}
## Get the depth of the @c ith contact point.

proc cpArbiterGetDepth*(arb: ptr cpArbiter; i: cint): cpFloat {.
    importc: "cpArbiterGetDepth", header: "<chipmunk/chipmunk.h>".}
## If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
## You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc cpArbiterCallWildcardBeginA*(arb: ptr cpArbiter; space: ptr cpSpace): cpBool {.
    importc: "cpArbiterCallWildcardBeginA", header: "<chipmunk/chipmunk.h>".}
## If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
## You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc cpArbiterCallWildcardBeginB*(arb: ptr cpArbiter; space: ptr cpSpace): cpBool {.
    importc: "cpArbiterCallWildcardBeginB", header: "<chipmunk/chipmunk.h>".}
## If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
## You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc cpArbiterCallWildcardPreSolveA*(arb: ptr cpArbiter; space: ptr cpSpace): cpBool {.
    importc: "cpArbiterCallWildcardPreSolveA", header: "<chipmunk/chipmunk.h>".}
## If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
## You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc cpArbiterCallWildcardPreSolveB*(arb: ptr cpArbiter; space: ptr cpSpace): cpBool {.
    importc: "cpArbiterCallWildcardPreSolveB", header: "<chipmunk/chipmunk.h>".}
## If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.

proc cpArbiterCallWildcardPostSolveA*(arb: ptr cpArbiter; space: ptr cpSpace) {.
    importc: "cpArbiterCallWildcardPostSolveA", header: "<chipmunk/chipmunk.h>".}
## If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.

proc cpArbiterCallWildcardPostSolveB*(arb: ptr cpArbiter; space: ptr cpSpace) {.
    importc: "cpArbiterCallWildcardPostSolveB", header: "<chipmunk/chipmunk.h>".}
## If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.

proc cpArbiterCallWildcardSeparateA*(arb: ptr cpArbiter; space: ptr cpSpace) {.
    importc: "cpArbiterCallWildcardSeparateA", header: "<chipmunk/chipmunk.h>".}
## If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.

proc cpArbiterCallWildcardSeparateB*(arb: ptr cpArbiter; space: ptr cpSpace) {.
    importc: "cpArbiterCallWildcardSeparateB", header: "<chipmunk/chipmunk.h>".}

## Chipmunk's rigid body type. Rigid bodies hold the physical properties of an object like
## it's mass, and position and velocity of it's center of gravity. They don't have an shape on their own.
## They are given a shape by creating collision shapes (cpShape) that point to the body.

type ## A dynamic body is one that is affected by gravity, forces, and collisions.
    ## This is the default body type.
  cpBodyType* {.size: sizeof(cint).} = enum
    CP_BODY_TYPE_DYNAMIC, ## A kinematic body is an infinite mass, user controlled body that is not affected by gravity, forces or collisions.
                         ## Instead the body only moves based on it's velocity.
                         ## Dynamic bodies collide normally with kinematic bodies, though the kinematic body will be unaffected.
                         ## Collisions between two kinematic bodies, or a kinematic body and a static body produce collision callbacks, but no collision response.
    CP_BODY_TYPE_KINEMATIC, ## A static body is a body that never (or rarely) moves. If you move a static body, you must call one of the cpSpaceReindex*() functions.
                           ## Chipmunk uses this information to optimize the collision detection.
                           ## Static bodies do not produce collision callbacks when colliding with other static bodies.
    CP_BODY_TYPE_STATIC


## Rigid body velocity update function type.

type
  cpBodyVelocityFunc* = proc (body: ptr cpBody; gravity: cpVect; damping: cpFloat;
                           dt: cpFloat) {.cdecl.}

## Rigid body position update function type.

type
  cpBodyPositionFunc* = proc (body: ptr cpBody; dt: cpFloat) {.cdecl.}

## Allocate a cpBody.

proc cpBodyAlloc*(): ptr cpBody {.importc: "cpBodyAlloc", header: "<chipmunk/chipmunk.h>".}
## Initialize a cpBody.

proc cpBodyInit*(body: ptr cpBody; mass: cpFloat; moment: cpFloat): ptr cpBody {.
    importc: "cpBodyInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a cpBody.

proc cpBodyNew*(mass: cpFloat; moment: cpFloat): ptr cpBody {.importc: "cpBodyNew",
    header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a cpBody, and set it as a kinematic body.

proc cpBodyNewKinematic*(): ptr cpBody {.importc: "cpBodyNewKinematic",
                                     header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a cpBody, and set it as a static body.

proc cpBodyNewStatic*(): ptr cpBody {.importc: "cpBodyNewStatic", header: "<chipmunk/chipmunk.h>".}
## Destroy a cpBody.

proc cpBodyDestroy*(body: ptr cpBody) {.importc: "cpBodyDestroy", header: "<chipmunk/chipmunk.h>".}
## Destroy and free a cpBody.

proc cpBodyFree*(body: ptr cpBody) {.importc: "cpBodyFree", header: "<chipmunk/chipmunk.h>".}
## Defined in cpSpace.c
## Wake up a sleeping or idle body.

proc cpBodyActivate*(body: ptr cpBody) {.importc: "cpBodyActivate", header: "<chipmunk/chipmunk.h>".}
## Wake up any sleeping or idle bodies touching a static body.

proc cpBodyActivateStatic*(body: ptr cpBody; filter: ptr cpShape) {.
    importc: "cpBodyActivateStatic", header: "<chipmunk/chipmunk.h>".}
## Force a body to fall asleep immediately.

proc cpBodySleep*(body: ptr cpBody) {.importc: "cpBodySleep", header: "<chipmunk/chipmunk.h>".}
## Force a body to fall asleep immediately along with other bodies in a group.

proc cpBodySleepWithGroup*(body: ptr cpBody; group: ptr cpBody) {.
    importc: "cpBodySleepWithGroup", header: "<chipmunk/chipmunk.h>".}
## Returns true if the body is sleeping.

proc cpBodyIsSleeping*(body: ptr cpBody): cpBool {.importc: "cpBodyIsSleeping",
    header: "<chipmunk/chipmunk.h>".}
## Get the type of the body.

proc cpBodyGetType*(body: ptr cpBody): cpBodyType {.importc: "cpBodyGetType",
    header: "<chipmunk/chipmunk.h>".}
## Set the type of the body.

proc cpBodySetType*(body: ptr cpBody; `type`: cpBodyType) {.importc: "cpBodySetType",
    header: "<chipmunk/chipmunk.h>".}
## Get the space this body is added to.

proc cpBodyGetSpace*(body: ptr cpBody): ptr cpSpace {.importc: "cpBodyGetSpace",
    header: "<chipmunk/chipmunk.h>".}
## Get the mass of the body.

proc cpBodyGetMass*(body: ptr cpBody): cpFloat {.importc: "cpBodyGetMass",
    header: "<chipmunk/chipmunk.h>".}
## Set the mass of the body.

proc cpBodySetMass*(body: ptr cpBody; m: cpFloat) {.importc: "cpBodySetMass",
    header: "<chipmunk/chipmunk.h>".}
## Get the moment of inertia of the body.

proc cpBodyGetMoment*(body: ptr cpBody): cpFloat {.importc: "cpBodyGetMoment",
    header: "<chipmunk/chipmunk.h>".}
## Set the moment of inertia of the body.

proc cpBodySetMoment*(body: ptr cpBody; i: cpFloat) {.importc: "cpBodySetMoment",
    header: "<chipmunk/chipmunk.h>".}
## Set the position of a body.

proc cpBodyGetPosition*(body: ptr cpBody): cpVect {.importc: "cpBodyGetPosition",
    header: "<chipmunk/chipmunk.h>".}
## Set the position of the body.

proc cpBodySetPosition*(body: ptr cpBody; pos: cpVect) {.importc: "cpBodySetPosition",
    header: "<chipmunk/chipmunk.h>".}
## Get the offset of the center of gravity in body local coordinates.

proc cpBodyGetCenterOfGravity*(body: ptr cpBody): cpVect {.
    importc: "cpBodyGetCenterOfGravity", header: "<chipmunk/chipmunk.h>".}
## Set the offset of the center of gravity in body local coordinates.

proc cpBodySetCenterOfGravity*(body: ptr cpBody; cog: cpVect) {.
    importc: "cpBodySetCenterOfGravity", header: "<chipmunk/chipmunk.h>".}
## Get the velocity of the body.

proc cpBodyGetVelocity*(body: ptr cpBody): cpVect {.importc: "cpBodyGetVelocity",
    header: "<chipmunk/chipmunk.h>".}
## Set the velocity of the body.

proc cpBodySetVelocity*(body: ptr cpBody; velocity: cpVect) {.
    importc: "cpBodySetVelocity", header: "<chipmunk/chipmunk.h>".}
## Get the force applied to the body for the next time step.

proc cpBodyGetForce*(body: ptr cpBody): cpVect {.importc: "cpBodyGetForce",
    header: "<chipmunk/chipmunk.h>".}
## Set the force applied to the body for the next time step.

proc cpBodySetForce*(body: ptr cpBody; force: cpVect) {.importc: "cpBodySetForce",
    header: "<chipmunk/chipmunk.h>".}
## Get the angle of the body.

proc cpBodyGetAngle*(body: ptr cpBody): cpFloat {.importc: "cpBodyGetAngle",
    header: "<chipmunk/chipmunk.h>".}
## Set the angle of a body.

proc cpBodySetAngle*(body: ptr cpBody; a: cpFloat) {.importc: "cpBodySetAngle",
    header: "<chipmunk/chipmunk.h>".}
## Get the angular velocity of the body.

proc cpBodyGetAngularVelocity*(body: ptr cpBody): cpFloat {.
    importc: "cpBodyGetAngularVelocity", header: "<chipmunk/chipmunk.h>".}
## Set the angular velocity of the body.

proc cpBodySetAngularVelocity*(body: ptr cpBody; angularVelocity: cpFloat) {.
    importc: "cpBodySetAngularVelocity", header: "<chipmunk/chipmunk.h>".}
## Get the torque applied to the body for the next time step.

proc cpBodyGetTorque*(body: ptr cpBody): cpFloat {.importc: "cpBodyGetTorque",
    header: "<chipmunk/chipmunk.h>".}
## Set the torque applied to the body for the next time step.

proc cpBodySetTorque*(body: ptr cpBody; torque: cpFloat) {.importc: "cpBodySetTorque",
    header: "<chipmunk/chipmunk.h>".}
## Get the rotation vector of the body. (The x basis vector of it's transform.)

proc cpBodyGetRotation*(body: ptr cpBody): cpVect {.importc: "cpBodyGetRotation",
    header: "<chipmunk/chipmunk.h>".}
## Get the user data pointer assigned to the body.

proc cpBodyGetUserData*(body: ptr cpBody): cpDataPointer {.
    importc: "cpBodyGetUserData", header: "<chipmunk/chipmunk.h>".}
## Set the user data pointer assigned to the body.

proc cpBodySetUserData*(body: ptr cpBody; userData: cpDataPointer) {.
    importc: "cpBodySetUserData", header: "<chipmunk/chipmunk.h>".}
## Set the callback used to update a body's velocity.

proc cpBodySetVelocityUpdateFunc*(body: ptr cpBody; velocityFunc: cpBodyVelocityFunc) {.
    importc: "cpBodySetVelocityUpdateFunc", header: "<chipmunk/chipmunk.h>".}
## Set the callback used to update a body's position.
## NOTE: It's not generally recommended to override this unless you call the default position update function.

proc cpBodySetPositionUpdateFunc*(body: ptr cpBody; positionFunc: cpBodyPositionFunc) {.
    importc: "cpBodySetPositionUpdateFunc", header: "<chipmunk/chipmunk.h>".}
## Default velocity integration function..

proc cpBodyUpdateVelocity*(body: ptr cpBody; gravity: cpVect; damping: cpFloat;
                          dt: cpFloat) {.importc: "cpBodyUpdateVelocity",
                                       header: "<chipmunk/chipmunk.h>".}
## Default position integration function.

proc cpBodyUpdatePosition*(body: ptr cpBody; dt: cpFloat) {.
    importc: "cpBodyUpdatePosition", header: "<chipmunk/chipmunk.h>".}
## Convert body relative/local coordinates to absolute/world coordinates.

proc cpBodyLocalToWorld*(body: ptr cpBody; point: cpVect): cpVect {.
    importc: "cpBodyLocalToWorld", header: "<chipmunk/chipmunk.h>".}
## Convert body absolute/world coordinates to  relative/local coordinates.

proc cpBodyWorldToLocal*(body: ptr cpBody; point: cpVect): cpVect {.
    importc: "cpBodyWorldToLocal", header: "<chipmunk/chipmunk.h>".}
## Apply a force to a body. Both the force and point are expressed in world coordinates.

proc cpBodyApplyForceAtWorldPoint*(body: ptr cpBody; force: cpVect; point: cpVect) {.
    importc: "cpBodyApplyForceAtWorldPoint", header: "<chipmunk/chipmunk.h>".}
## Apply a force to a body. Both the force and point are expressed in body local coordinates.

proc cpBodyApplyForceAtLocalPoint*(body: ptr cpBody; force: cpVect; point: cpVect) {.
    importc: "cpBodyApplyForceAtLocalPoint", header: "<chipmunk/chipmunk.h>".}
## Apply an impulse to a body. Both the impulse and point are expressed in world coordinates.

proc cpBodyApplyImpulseAtWorldPoint*(body: ptr cpBody; impulse: cpVect; point: cpVect) {.
    importc: "cpBodyApplyImpulseAtWorldPoint", header: "<chipmunk/chipmunk.h>".}
## Apply an impulse to a body. Both the impulse and point are expressed in body local coordinates.

proc cpBodyApplyImpulseAtLocalPoint*(body: ptr cpBody; impulse: cpVect; point: cpVect) {.
    importc: "cpBodyApplyImpulseAtLocalPoint", header: "<chipmunk/chipmunk.h>".}
## Get the velocity on a body (in world units) at a point on the body in world coordinates.

proc cpBodyGetVelocityAtWorldPoint*(body: ptr cpBody; point: cpVect): cpVect {.
    importc: "cpBodyGetVelocityAtWorldPoint", header: "<chipmunk/chipmunk.h>".}
## Get the velocity on a body (in world units) at a point on the body in local coordinates.

proc cpBodyGetVelocityAtLocalPoint*(body: ptr cpBody; point: cpVect): cpVect {.
    importc: "cpBodyGetVelocityAtLocalPoint", header: "<chipmunk/chipmunk.h>".}
## Get the amount of kinetic energy contained by the body.

proc cpBodyKineticEnergy*(body: ptr cpBody): cpFloat {.
    importc: "cpBodyKineticEnergy", header: "<chipmunk/chipmunk.h>".}
## Body/shape iterator callback function type.

type
  cpBodyShapeIteratorFunc* = proc (body: ptr cpBody; shape: ptr cpShape; data: pointer) {.cdecl.}

## Call @c func once for each shape attached to @c body and added to the space.

proc cpBodyEachShape*(body: ptr cpBody; `func`: cpBodyShapeIteratorFunc; data: pointer) {.
    importc: "cpBodyEachShape", header: "<chipmunk/chipmunk.h>".}
## Body/constraint iterator callback function type.

type
  cpBodyConstraintIteratorFunc* = proc (body: ptr cpBody;
                                     constraint: ptr cpConstraint; data: pointer) {.cdecl.}

## Call @c func once for each constraint attached to @c body and added to the space.

proc cpBodyEachConstraint*(body: ptr cpBody; `func`: cpBodyConstraintIteratorFunc;
                          data: pointer) {.importc: "cpBodyEachConstraint",
    header: "<chipmunk/chipmunk.h>".}
## Body/arbiter iterator callback function type.

type
  cpBodyArbiterIteratorFunc* = proc (body: ptr cpBody; arbiter: ptr cpArbiter;
                                  data: pointer) {.cdecl.}

## Call @c func once for each arbiter that is currently active on the body.

proc cpBodyEachArbiter*(body: ptr cpBody; `func`: cpBodyArbiterIteratorFunc;
                       data: pointer) {.importc: "cpBodyEachArbiter",
                                      header: "<chipmunk/chipmunk.h>".}

## The cpShape struct defines the shape of a rigid body.
## Point query info struct.

type
  cpPointQueryInfo* {.importc: "cpPointQueryInfo", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    shape* {.importc: "shape".}: ptr cpShape ## The nearest shape, NULL if no shape was within range.
    ## The closest point on the shape's surface. (in world space coordinates)
    point* {.importc: "point".}: cpVect ## The distance to the point. The distance is negative if the point is inside the shape.
    distance* {.importc: "distance".}: cpFloat ## The gradient of the signed distance function.
                                           ## The value should be similar to info.p/info.d, but accurate even for very small values of info.d.
    gradient* {.importc: "gradient".}: cpVect


## Segment query info struct.

type
  cpSegmentQueryInfo* {.importc: "cpSegmentQueryInfo", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    shape* {.importc: "shape".}: ptr cpShape ## The shape that was hit, or NULL if no collision occured.
    ## The point of impact.
    point* {.importc: "point".}: cpVect ## The normal of the surface hit.
    normal* {.importc: "normal".}: cpVect ## The normalized distance along the query segment in the range [0, 1].
    alpha* {.importc: "alpha".}: cpFloat


## Fast collision filtering type that is used to determine if two objects collide before calling collision or query callbacks.

type
  cpShapeFilter* {.importc: "cpShapeFilter", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    group* {.importc: "group".}: cpGroup ## Two objects with the same non-zero group value do not collide.
                                     ## This is generally used to group objects in a composite object together to disable self collisions.
    ## A bitmask of user definable categories that this object belongs to.
    ## The category/mask combinations of both objects in a collision must agree for a collision to occur.
    categories* {.importc: "categories".}: cpBitmask ## A bitmask of user definable category types that this object object collides with.
                                                 ## The category/mask combinations of both objects in a collision must agree for a collision to occur.
    mask* {.importc: "mask".}: cpBitmask


## Collision filter value for a shape that will collide with anything except CP_SHAPE_FILTER_NONE.

var CP_SHAPE_FILTER_ALL* {.importc: "CP_SHAPE_FILTER_ALL", header: "<chipmunk/chipmunk.h>".}: cpShapeFilter

## Collision filter value for a shape that does not collide with anything.

var CP_SHAPE_FILTER_NONE* {.importc: "CP_SHAPE_FILTER_NONE", header: "<chipmunk/chipmunk.h>".}: cpShapeFilter

## Create a new collision filter.

proc cpShapeFilterNew*(group: cpGroup; categories: cpBitmask; mask: cpBitmask): cpShapeFilter {.
    inline.} =
  var filter: cpShapeFilter
  return filter

## Destroy a shape.

proc cpShapeDestroy*(shape: ptr cpShape) {.importc: "cpShapeDestroy",
                                       header: "<chipmunk/chipmunk.h>".}
## Destroy and Free a shape.

proc cpShapeFree*(shape: ptr cpShape) {.importc: "cpShapeFree", header: "<chipmunk/chipmunk.h>".}
## Update, cache and return the bounding box of a shape based on the body it's attached to.

proc cpShapeCacheBB*(shape: ptr cpShape): cpBB {.importc: "cpShapeCacheBB",
    header: "<chipmunk/chipmunk.h>".}
## Update, cache and return the bounding box of a shape with an explicit transformation.

proc cpShapeUpdate*(shape: ptr cpShape; transform: cpTransform): cpBB {.
    importc: "cpShapeUpdate", header: "<chipmunk/chipmunk.h>".}
## Perform a nearest point query. It finds the closest point on the surface of shape to a specific point.
## The value returned is the distance between the points. A negative distance means the point is inside the shape.

proc cpShapePointQuery*(shape: ptr cpShape; p: cpVect; `out`: ptr cpPointQueryInfo): cpFloat {.
    importc: "cpShapePointQuery", header: "<chipmunk/chipmunk.h>".}
## Perform a segment query against a shape. @c info must be a pointer to a valid cpSegmentQueryInfo structure.

proc cpShapeSegmentQuery*(shape: ptr cpShape; a: cpVect; b: cpVect; radius: cpFloat;
                         info: ptr cpSegmentQueryInfo): cpBool {.
    importc: "cpShapeSegmentQuery", header: "<chipmunk/chipmunk.h>".}
## Return contact information about two shapes.

proc cpShapesCollide*(a: ptr cpShape; b: ptr cpShape): cpContactPointSet {.
    importc: "cpShapesCollide", header: "<chipmunk/chipmunk.h>".}
## The cpSpace this body is added to.

proc cpShapeGetSpace*(shape: ptr cpShape): ptr cpSpace {.importc: "cpShapeGetSpace",
    header: "<chipmunk/chipmunk.h>".}
## The cpBody this shape is connected to.

proc cpShapeGetBody*(shape: ptr cpShape): ptr cpBody {.importc: "cpShapeGetBody",
    header: "<chipmunk/chipmunk.h>".}
## Set the cpBody this shape is connected to.
## Can only be used if the shape is not currently added to a space.

proc cpShapeSetBody*(shape: ptr cpShape; body: ptr cpBody) {.importc: "cpShapeSetBody",
    header: "<chipmunk/chipmunk.h>".}
## Get the mass of the shape if you are having Chipmunk calculate mass properties for you.

proc cpShapeGetMass*(shape: ptr cpShape): cpFloat {.importc: "cpShapeGetMass",
    header: "<chipmunk/chipmunk.h>".}
## Set the mass of this shape to have Chipmunk calculate mass properties for you.

proc cpShapeSetMass*(shape: ptr cpShape; mass: cpFloat) {.importc: "cpShapeSetMass",
    header: "<chipmunk/chipmunk.h>".}
## Get the density of the shape if you are having Chipmunk calculate mass properties for you.

proc cpShapeGetDensity*(shape: ptr cpShape): cpFloat {.importc: "cpShapeGetDensity",
    header: "<chipmunk/chipmunk.h>".}
## Set the density  of this shape to have Chipmunk calculate mass properties for you.

proc cpShapeSetDensity*(shape: ptr cpShape; density: cpFloat) {.
    importc: "cpShapeSetDensity", header: "<chipmunk/chipmunk.h>".}
## Get the calculated moment of inertia for this shape.

proc cpShapeGetMoment*(shape: ptr cpShape): cpFloat {.importc: "cpShapeGetMoment",
    header: "<chipmunk/chipmunk.h>".}
## Get the calculated area of this shape.

proc cpShapeGetArea*(shape: ptr cpShape): cpFloat {.importc: "cpShapeGetArea",
    header: "<chipmunk/chipmunk.h>".}
## Get the centroid of this shape.

proc cpShapeGetCenterOfGravity*(shape: ptr cpShape): cpVect {.
    importc: "cpShapeGetCenterOfGravity", header: "<chipmunk/chipmunk.h>".}
## Get the bounding box that contains the shape given it's current position and angle.

proc cpShapeGetBB*(shape: ptr cpShape): cpBB {.importc: "cpShapeGetBB",
    header: "<chipmunk/chipmunk.h>".}
## Get if the shape is set to be a sensor or not.

proc cpShapeGetSensor*(shape: ptr cpShape): cpBool {.importc: "cpShapeGetSensor",
    header: "<chipmunk/chipmunk.h>".}
## Set if the shape is a sensor or not.

proc cpShapeSetSensor*(shape: ptr cpShape; sensor: cpBool) {.
    importc: "cpShapeSetSensor", header: "<chipmunk/chipmunk.h>".}
## Get the elasticity of this shape.

proc cpShapeGetElasticity*(shape: ptr cpShape): cpFloat {.
    importc: "cpShapeGetElasticity", header: "<chipmunk/chipmunk.h>".}
## Set the elasticity of this shape.

proc cpShapeSetElasticity*(shape: ptr cpShape; elasticity: cpFloat) {.
    importc: "cpShapeSetElasticity", header: "<chipmunk/chipmunk.h>".}
## Get the friction of this shape.

proc cpShapeGetFriction*(shape: ptr cpShape): cpFloat {.
    importc: "cpShapeGetFriction", header: "<chipmunk/chipmunk.h>".}
## Set the friction of this shape.

proc cpShapeSetFriction*(shape: ptr cpShape; friction: cpFloat) {.
    importc: "cpShapeSetFriction", header: "<chipmunk/chipmunk.h>".}
## Get the surface velocity of this shape.

proc cpShapeGetSurfaceVelocity*(shape: ptr cpShape): cpVect {.
    importc: "cpShapeGetSurfaceVelocity", header: "<chipmunk/chipmunk.h>".}
## Set the surface velocity of this shape.

proc cpShapeSetSurfaceVelocity*(shape: ptr cpShape; surfaceVelocity: cpVect) {.
    importc: "cpShapeSetSurfaceVelocity", header: "<chipmunk/chipmunk.h>".}
## Get the user definable data pointer of this shape.

proc cpShapeGetUserData*(shape: ptr cpShape): cpDataPointer {.
    importc: "cpShapeGetUserData", header: "<chipmunk/chipmunk.h>".}
## Set the user definable data pointer of this shape.

proc cpShapeSetUserData*(shape: ptr cpShape; userData: cpDataPointer) {.
    importc: "cpShapeSetUserData", header: "<chipmunk/chipmunk.h>".}
## Set the collision type of this shape.

proc cpShapeGetCollisionType*(shape: ptr cpShape): cpCollisionType {.
    importc: "cpShapeGetCollisionType", header: "<chipmunk/chipmunk.h>".}
## Get the collision type of this shape.

proc cpShapeSetCollisionType*(shape: ptr cpShape; collisionType: cpCollisionType) {.
    importc: "cpShapeSetCollisionType", header: "<chipmunk/chipmunk.h>".}
## Get the collision filtering parameters of this shape.

proc cpShapeGetFilter*(shape: ptr cpShape): cpShapeFilter {.
    importc: "cpShapeGetFilter", header: "<chipmunk/chipmunk.h>".}
## Set the collision filtering parameters of this shape.

proc cpShapeSetFilter*(shape: ptr cpShape; filter: cpShapeFilter) {.
    importc: "cpShapeSetFilter", header: "<chipmunk/chipmunk.h>".}

## Allocate a circle shape.

proc cpCircleShapeAlloc*(): ptr cpCircleShape {.importc: "cpCircleShapeAlloc",
    header: "<chipmunk/chipmunk.h>".}
## Initialize a circle shape.

proc cpCircleShapeInit*(circle: ptr cpCircleShape; body: ptr cpBody; radius: cpFloat;
                       offset: cpVect): ptr cpCircleShape {.
    importc: "cpCircleShapeInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a circle shape.

proc cpCircleShapeNew*(body: ptr cpBody; radius: cpFloat; offset: cpVect): ptr cpShape {.
    importc: "cpCircleShapeNew", header: "<chipmunk/chipmunk.h>".}
## Get the offset of a circle shape.

proc cpCircleShapeGetOffset*(shape: ptr cpShape): cpVect {.
    importc: "cpCircleShapeGetOffset", header: "<chipmunk/chipmunk.h>".}
## Get the radius of a circle shape.

proc cpCircleShapeGetRadius*(shape: ptr cpShape): cpFloat {.
    importc: "cpCircleShapeGetRadius", header: "<chipmunk/chipmunk.h>".}

## Allocate a segment shape.

proc cpSegmentShapeAlloc*(): ptr cpSegmentShape {.importc: "cpSegmentShapeAlloc",
    header: "<chipmunk/chipmunk.h>".}
## Initialize a segment shape.

proc cpSegmentShapeInit*(seg: ptr cpSegmentShape; body: ptr cpBody; a: cpVect; b: cpVect;
                        radius: cpFloat): ptr cpSegmentShape {.
    importc: "cpSegmentShapeInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a segment shape.

proc cpSegmentShapeNew*(body: ptr cpBody; a: cpVect; b: cpVect; radius: cpFloat): ptr cpShape {.
    importc: "cpSegmentShapeNew", header: "<chipmunk/chipmunk.h>".}
## Let Chipmunk know about the geometry of adjacent segments to avoid colliding with endcaps.

proc cpSegmentShapeSetNeighbors*(shape: ptr cpShape; prev: cpVect; next: cpVect) {.
    importc: "cpSegmentShapeSetNeighbors", header: "<chipmunk/chipmunk.h>".}
## Get the first endpoint of a segment shape.

proc cpSegmentShapeGetA*(shape: ptr cpShape): cpVect {.importc: "cpSegmentShapeGetA",
    header: "<chipmunk/chipmunk.h>".}
## Get the second endpoint of a segment shape.

proc cpSegmentShapeGetB*(shape: ptr cpShape): cpVect {.importc: "cpSegmentShapeGetB",
    header: "<chipmunk/chipmunk.h>".}
## Get the normal of a segment shape.

proc cpSegmentShapeGetNormal*(shape: ptr cpShape): cpVect {.
    importc: "cpSegmentShapeGetNormal", header: "<chipmunk/chipmunk.h>".}
## Get the first endpoint of a segment shape.

proc cpSegmentShapeGetRadius*(shape: ptr cpShape): cpFloat {.
    importc: "cpSegmentShapeGetRadius", header: "<chipmunk/chipmunk.h>".}

## Allocate a polygon shape.

proc cpPolyShapeAlloc*(): ptr cpPolyShape {.importc: "cpPolyShapeAlloc",
                                        header: "<chipmunk/chipmunk.h>".}
## Initialize a polygon shape with rounded corners.
## A convex hull will be created from the vertexes.

proc cpPolyShapeInit*(poly: ptr cpPolyShape; body: ptr cpBody; count: cint;
                     verts: ptr cpVect; transform: cpTransform; radius: cpFloat): ptr cpPolyShape {.
    importc: "cpPolyShapeInit", header: "<chipmunk/chipmunk.h>".}
## Initialize a polygon shape with rounded corners.
## The vertexes must be convex with a counter-clockwise winding.

proc cpPolyShapeInitRaw*(poly: ptr cpPolyShape; body: ptr cpBody; count: cint;
                        verts: ptr cpVect; radius: cpFloat): ptr cpPolyShape {.
    importc: "cpPolyShapeInitRaw", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a polygon shape with rounded corners.
## A convex hull will be created from the vertexes.

proc cpPolyShapeNew*(body: ptr cpBody; count: cint; verts: ptr cpVect;
                    transform: cpTransform; radius: cpFloat): ptr cpShape {.
    importc: "cpPolyShapeNew", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a polygon shape with rounded corners.
## The vertexes must be convex with a counter-clockwise winding.

proc cpPolyShapeNewRaw*(body: ptr cpBody; count: cint; verts: ptr cpVect; radius: cpFloat): ptr cpShape {.
    importc: "cpPolyShapeNewRaw", header: "<chipmunk/chipmunk.h>".}
## Initialize a box shaped polygon shape with rounded corners.

proc cpBoxShapeInit*(poly: ptr cpPolyShape; body: ptr cpBody; width: cpFloat;
                    height: cpFloat; radius: cpFloat): ptr cpPolyShape {.
    importc: "cpBoxShapeInit", header: "<chipmunk/chipmunk.h>".}
## Initialize an offset box shaped polygon shape with rounded corners.

proc cpBoxShapeInit2*(poly: ptr cpPolyShape; body: ptr cpBody; box: cpBB; radius: cpFloat): ptr cpPolyShape {.
    importc: "cpBoxShapeInit2", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a box shaped polygon shape.

proc cpBoxShapeNew*(body: ptr cpBody; width: cpFloat; height: cpFloat; radius: cpFloat): ptr cpShape {.
    importc: "cpBoxShapeNew", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize an offset box shaped polygon shape.

proc cpBoxShapeNew2*(body: ptr cpBody; box: cpBB; radius: cpFloat): ptr cpShape {.
    importc: "cpBoxShapeNew2", header: "<chipmunk/chipmunk.h>".}
## Get the number of verts in a polygon shape.

proc cpPolyShapeGetCount*(shape: ptr cpShape): cint {.importc: "cpPolyShapeGetCount",
    header: "<chipmunk/chipmunk.h>".}
## Get the @c ith vertex of a polygon shape.

proc cpPolyShapeGetVert*(shape: ptr cpShape; index: cint): cpVect {.
    importc: "cpPolyShapeGetVert", header: "<chipmunk/chipmunk.h>".}
## Get the radius of a polygon shape.

proc cpPolyShapeGetRadius*(shape: ptr cpShape): cpFloat {.
    importc: "cpPolyShapeGetRadius", header: "<chipmunk/chipmunk.h>".}

type
  cpConstraintPreSolveFunc* = proc (constraint: ptr cpConstraint; space: ptr cpSpace)

## Callback function type that gets called after solving a joint.

type
  cpConstraintPostSolveFunc* = proc (constraint: ptr cpConstraint; space: ptr cpSpace)

## Destroy a constraint.

proc cpConstraintDestroy*(constraint: ptr cpConstraint) {.
    importc: "cpConstraintDestroy", header: "<chipmunk/chipmunk.h>".}
## Destroy and free a constraint.

proc cpConstraintFree*(constraint: ptr cpConstraint) {.importc: "cpConstraintFree",
    header: "<chipmunk/chipmunk.h>".}
## Get the cpSpace this constraint is added to.

proc cpConstraintGetSpace*(constraint: ptr cpConstraint): ptr cpSpace {.
    importc: "cpConstraintGetSpace", header: "<chipmunk/chipmunk.h>".}
## Get the first body the constraint is attached to.

proc cpConstraintGetBodyA*(constraint: ptr cpConstraint): ptr cpBody {.
    importc: "cpConstraintGetBodyA", header: "<chipmunk/chipmunk.h>".}
## Get the second body the constraint is attached to.

proc cpConstraintGetBodyB*(constraint: ptr cpConstraint): ptr cpBody {.
    importc: "cpConstraintGetBodyB", header: "<chipmunk/chipmunk.h>".}
## Get the maximum force that this constraint is allowed to use.

proc cpConstraintGetMaxForce*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpConstraintGetMaxForce", header: "<chipmunk/chipmunk.h>".}
## Set the maximum force that this constraint is allowed to use. (defaults to INFINITY)

proc cpConstraintSetMaxForce*(constraint: ptr cpConstraint; maxForce: cpFloat) {.
    importc: "cpConstraintSetMaxForce", header: "<chipmunk/chipmunk.h>".}
## Get rate at which joint error is corrected.

proc cpConstraintGetErrorBias*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpConstraintGetErrorBias", header: "<chipmunk/chipmunk.h>".}
## Set rate at which joint error is corrected.
## Defaults to pow(1.0 - 0.1, 60.0) meaning that it will
## correct 10% of the error every 1/60th of a second.

proc cpConstraintSetErrorBias*(constraint: ptr cpConstraint; errorBias: cpFloat) {.
    importc: "cpConstraintSetErrorBias", header: "<chipmunk/chipmunk.h>".}
## Get the maximum rate at which joint error is corrected.

proc cpConstraintGetMaxBias*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpConstraintGetMaxBias", header: "<chipmunk/chipmunk.h>".}
## Set the maximum rate at which joint error is corrected. (defaults to INFINITY)

proc cpConstraintSetMaxBias*(constraint: ptr cpConstraint; maxBias: cpFloat) {.
    importc: "cpConstraintSetMaxBias", header: "<chipmunk/chipmunk.h>".}
## Get if the two bodies connected by the constraint are allowed to collide or not.

proc cpConstraintGetCollideBodies*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintGetCollideBodies", header: "<chipmunk/chipmunk.h>".}
## Set if the two bodies connected by the constraint are allowed to collide or not. (defaults to cpFalse)

proc cpConstraintSetCollideBodies*(constraint: ptr cpConstraint;
                                  collideBodies: cpBool) {.
    importc: "cpConstraintSetCollideBodies", header: "<chipmunk/chipmunk.h>".}
## Get the pre-solve function that is called before the solver runs.

proc cpConstraintGetPreSolveFunc*(constraint: ptr cpConstraint): cpConstraintPreSolveFunc {.
    importc: "cpConstraintGetPreSolveFunc", header: "<chipmunk/chipmunk.h>".}
## Set the pre-solve function that is called before the solver runs.

proc cpConstraintSetPreSolveFunc*(constraint: ptr cpConstraint;
                                 preSolveFunc: cpConstraintPreSolveFunc) {.
    importc: "cpConstraintSetPreSolveFunc", header: "<chipmunk/chipmunk.h>".}
## Get the post-solve function that is called before the solver runs.

proc cpConstraintGetPostSolveFunc*(constraint: ptr cpConstraint): cpConstraintPostSolveFunc {.
    importc: "cpConstraintGetPostSolveFunc", header: "<chipmunk/chipmunk.h>".}
## Set the post-solve function that is called before the solver runs.

proc cpConstraintSetPostSolveFunc*(constraint: ptr cpConstraint;
                                  postSolveFunc: cpConstraintPostSolveFunc) {.
    importc: "cpConstraintSetPostSolveFunc", header: "<chipmunk/chipmunk.h>".}
## Get the user definable data pointer for this constraint

proc cpConstraintGetUserData*(constraint: ptr cpConstraint): cpDataPointer {.
    importc: "cpConstraintGetUserData", header: "<chipmunk/chipmunk.h>".}
## Set the user definable data pointer for this constraint

proc cpConstraintSetUserData*(constraint: ptr cpConstraint; userData: cpDataPointer) {.
    importc: "cpConstraintSetUserData", header: "<chipmunk/chipmunk.h>".}
## Get the last impulse applied by this constraint.

proc cpConstraintGetImpulse*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpConstraintGetImpulse", header: "<chipmunk/chipmunk.h>".}

## Check if a constraint is a pin joint.

proc cpConstraintIsPinJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsPinJoint", header: "<chipmunk/chipmunk.h>".}
## Allocate a pin joint.

proc cpPinJointAlloc*(): ptr cpPinJoint {.importc: "cpPinJointAlloc",
                                      header: "<chipmunk/chipmunk.h>".}
## Initialize a pin joint.

proc cpPinJointInit*(joint: ptr cpPinJoint; a: ptr cpBody; b: ptr cpBody; anchorA: cpVect;
                    anchorB: cpVect): ptr cpPinJoint {.importc: "cpPinJointInit",
    header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a pin joint.

proc cpPinJointNew*(a: ptr cpBody; b: ptr cpBody; anchorA: cpVect; anchorB: cpVect): ptr cpConstraint {.
    importc: "cpPinJointNew", header: "<chipmunk/chipmunk.h>".}
## Get the location of the first anchor relative to the first body.

proc cpPinJointGetAnchorA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpPinJointGetAnchorA", header: "<chipmunk/chipmunk.h>".}
## Set the location of the first anchor relative to the first body.

proc cpPinJointSetAnchorA*(constraint: ptr cpConstraint; anchorA: cpVect) {.
    importc: "cpPinJointSetAnchorA", header: "<chipmunk/chipmunk.h>".}
## Get the location of the second anchor relative to the second body.

proc cpPinJointGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpPinJointGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## Set the location of the second anchor relative to the second body.

proc cpPinJointSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpPinJointSetAnchorB", header: "<chipmunk/chipmunk.h>".}
## Get the distance the joint will maintain between the two anchors.

proc cpPinJointGetDist*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpPinJointGetDist", header: "<chipmunk/chipmunk.h>".}
## Set the distance the joint will maintain between the two anchors.

proc cpPinJointSetDist*(constraint: ptr cpConstraint; dist: cpFloat) {.
    importc: "cpPinJointSetDist", header: "<chipmunk/chipmunk.h>".}

## Check if a constraint is a slide joint.

proc cpConstraintIsSlideJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsSlideJoint", header: "<chipmunk/chipmunk.h>".}
## Allocate a slide joint.

proc cpSlideJointAlloc*(): ptr cpSlideJoint {.importc: "cpSlideJointAlloc",
    header: "<chipmunk/chipmunk.h>".}
## Initialize a slide joint.

proc cpSlideJointInit*(joint: ptr cpSlideJoint; a: ptr cpBody; b: ptr cpBody;
                      anchorA: cpVect; anchorB: cpVect; min: cpFloat; max: cpFloat): ptr cpSlideJoint {.
    importc: "cpSlideJointInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a slide joint.

proc cpSlideJointNew*(a: ptr cpBody; b: ptr cpBody; anchorA: cpVect; anchorB: cpVect;
                     min: cpFloat; max: cpFloat): ptr cpConstraint {.
    importc: "cpSlideJointNew", header: "<chipmunk/chipmunk.h>".}
## Get the location of the first anchor relative to the first body.

proc cpSlideJointGetAnchorA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpSlideJointGetAnchorA", header: "<chipmunk/chipmunk.h>".}
## Set the location of the first anchor relative to the first body.

proc cpSlideJointSetAnchorA*(constraint: ptr cpConstraint; anchorA: cpVect) {.
    importc: "cpSlideJointSetAnchorA", header: "<chipmunk/chipmunk.h>".}
## Get the location of the second anchor relative to the second body.

proc cpSlideJointGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpSlideJointGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## Set the location of the second anchor relative to the second body.

proc cpSlideJointSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpSlideJointSetAnchorB", header: "<chipmunk/chipmunk.h>".}
## Get the minimum distance the joint will maintain between the two anchors.

proc cpSlideJointGetMin*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpSlideJointGetMin", header: "<chipmunk/chipmunk.h>".}
## Set the minimum distance the joint will maintain between the two anchors.

proc cpSlideJointSetMin*(constraint: ptr cpConstraint; min: cpFloat) {.
    importc: "cpSlideJointSetMin", header: "<chipmunk/chipmunk.h>".}
## Get the maximum distance the joint will maintain between the two anchors.

proc cpSlideJointGetMax*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpSlideJointGetMax", header: "<chipmunk/chipmunk.h>".}
## Set the maximum distance the joint will maintain between the two anchors.

proc cpSlideJointSetMax*(constraint: ptr cpConstraint; max: cpFloat) {.
    importc: "cpSlideJointSetMax", header: "<chipmunk/chipmunk.h>".}

## Check if a constraint is a slide joint.

proc cpConstraintIsPivotJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsPivotJoint", header: "<chipmunk/chipmunk.h>".}
## Allocate a pivot joint

proc cpPivotJointAlloc*(): ptr cpPivotJoint {.importc: "cpPivotJointAlloc",
    header: "<chipmunk/chipmunk.h>".}
## Initialize a pivot joint.

proc cpPivotJointInit*(joint: ptr cpPivotJoint; a: ptr cpBody; b: ptr cpBody;
                      anchorA: cpVect; anchorB: cpVect): ptr cpPivotJoint {.
    importc: "cpPivotJointInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a pivot joint.

proc cpPivotJointNew*(a: ptr cpBody; b: ptr cpBody; pivot: cpVect): ptr cpConstraint {.
    importc: "cpPivotJointNew", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a pivot joint with specific anchors.

proc cpPivotJointNew2*(a: ptr cpBody; b: ptr cpBody; anchorA: cpVect; anchorB: cpVect): ptr cpConstraint {.
    importc: "cpPivotJointNew2", header: "<chipmunk/chipmunk.h>".}
## Get the location of the first anchor relative to the first body.

proc cpPivotJointGetAnchorA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpPivotJointGetAnchorA", header: "<chipmunk/chipmunk.h>".}
## Set the location of the first anchor relative to the first body.

proc cpPivotJointSetAnchorA*(constraint: ptr cpConstraint; anchorA: cpVect) {.
    importc: "cpPivotJointSetAnchorA", header: "<chipmunk/chipmunk.h>".}
## Get the location of the second anchor relative to the second body.

proc cpPivotJointGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpPivotJointGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## Set the location of the second anchor relative to the second body.

proc cpPivotJointSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpPivotJointSetAnchorB", header: "<chipmunk/chipmunk.h>".}

## Check if a constraint is a slide joint.

proc cpConstraintIsGrooveJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsGrooveJoint", header: "<chipmunk/chipmunk.h>".}
## Allocate a groove joint.

proc cpGrooveJointAlloc*(): ptr cpGrooveJoint {.importc: "cpGrooveJointAlloc",
    header: "<chipmunk/chipmunk.h>".}
## Initialize a groove joint.

proc cpGrooveJointInit*(joint: ptr cpGrooveJoint; a: ptr cpBody; b: ptr cpBody;
                       groove_a: cpVect; groove_b: cpVect; anchorB: cpVect): ptr cpGrooveJoint {.
    importc: "cpGrooveJointInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a groove joint.

proc cpGrooveJointNew*(a: ptr cpBody; b: ptr cpBody; groove_a: cpVect; groove_b: cpVect;
                      anchorB: cpVect): ptr cpConstraint {.
    importc: "cpGrooveJointNew", header: "<chipmunk/chipmunk.h>".}
## Get the first endpoint of the groove relative to the first body.

proc cpGrooveJointGetGrooveA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpGrooveJointGetGrooveA", header: "<chipmunk/chipmunk.h>".}
## Set the first endpoint of the groove relative to the first body.

proc cpGrooveJointSetGrooveA*(constraint: ptr cpConstraint; grooveA: cpVect) {.
    importc: "cpGrooveJointSetGrooveA", header: "<chipmunk/chipmunk.h>".}
## Get the first endpoint of the groove relative to the first body.

proc cpGrooveJointGetGrooveB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpGrooveJointGetGrooveB", header: "<chipmunk/chipmunk.h>".}
## Set the first endpoint of the groove relative to the first body.

proc cpGrooveJointSetGrooveB*(constraint: ptr cpConstraint; grooveB: cpVect) {.
    importc: "cpGrooveJointSetGrooveB", header: "<chipmunk/chipmunk.h>".}
## Get the location of the second anchor relative to the second body.

proc cpGrooveJointGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpGrooveJointGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## Set the location of the second anchor relative to the second body.

proc cpGrooveJointSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpGrooveJointSetAnchorB", header: "<chipmunk/chipmunk.h>".}

## Check if a constraint is a slide joint.

proc cpConstraintIsDampedSpring*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsDampedSpring", header: "<chipmunk/chipmunk.h>".}
## Function type used for damped spring force callbacks.

type
  cpDampedSpringForceFunc* = proc (spring: ptr cpConstraint; dist: cpFloat): cpFloat

## Allocate a damped spring.

proc cpDampedSpringAlloc*(): ptr cpDampedSpring {.importc: "cpDampedSpringAlloc",
    header: "<chipmunk/chipmunk.h>".}
## Initialize a damped spring.

proc cpDampedSpringInit*(joint: ptr cpDampedSpring; a: ptr cpBody; b: ptr cpBody;
                        anchorA: cpVect; anchorB: cpVect; restLength: cpFloat;
                        stiffness: cpFloat; damping: cpFloat): ptr cpDampedSpring {.
    importc: "cpDampedSpringInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a damped spring.

proc cpDampedSpringNew*(a: ptr cpBody; b: ptr cpBody; anchorA: cpVect; anchorB: cpVect;
                       restLength: cpFloat; stiffness: cpFloat; damping: cpFloat): ptr cpConstraint {.
    importc: "cpDampedSpringNew", header: "<chipmunk/chipmunk.h>".}
## Get the location of the first anchor relative to the first body.

proc cpDampedSpringGetAnchorA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpDampedSpringGetAnchorA", header: "<chipmunk/chipmunk.h>".}
## Set the location of the first anchor relative to the first body.

proc cpDampedSpringSetAnchorA*(constraint: ptr cpConstraint; anchorA: cpVect) {.
    importc: "cpDampedSpringSetAnchorA", header: "<chipmunk/chipmunk.h>".}
## Get the location of the second anchor relative to the second body.

proc cpDampedSpringGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpDampedSpringGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## Set the location of the second anchor relative to the second body.

proc cpDampedSpringSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpDampedSpringSetAnchorB", header: "<chipmunk/chipmunk.h>".}
## Get the rest length of the spring.

proc cpDampedSpringGetRestLength*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedSpringGetRestLength", header: "<chipmunk/chipmunk.h>".}
## Set the rest length of the spring.

proc cpDampedSpringSetRestLength*(constraint: ptr cpConstraint; restLength: cpFloat) {.
    importc: "cpDampedSpringSetRestLength", header: "<chipmunk/chipmunk.h>".}
## Get the stiffness of the spring in force/distance.

proc cpDampedSpringGetStiffness*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedSpringGetStiffness", header: "<chipmunk/chipmunk.h>".}
## Set the stiffness of the spring in force/distance.

proc cpDampedSpringSetStiffness*(constraint: ptr cpConstraint; stiffness: cpFloat) {.
    importc: "cpDampedSpringSetStiffness", header: "<chipmunk/chipmunk.h>".}
## Get the damping of the spring.

proc cpDampedSpringGetDamping*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedSpringGetDamping", header: "<chipmunk/chipmunk.h>".}
## Set the damping of the spring.

proc cpDampedSpringSetDamping*(constraint: ptr cpConstraint; damping: cpFloat) {.
    importc: "cpDampedSpringSetDamping", header: "<chipmunk/chipmunk.h>".}
## Get the damping of the spring.

proc cpDampedSpringGetSpringForceFunc*(constraint: ptr cpConstraint): cpDampedSpringForceFunc {.
    importc: "cpDampedSpringGetSpringForceFunc", header: "<chipmunk/chipmunk.h>".}
## Set the damping of the spring.

proc cpDampedSpringSetSpringForceFunc*(constraint: ptr cpConstraint;
                                      springForceFunc: cpDampedSpringForceFunc) {.
    importc: "cpDampedSpringSetSpringForceFunc", header: "<chipmunk/chipmunk.h>".}

## Check if a constraint is a damped rotary springs.

proc cpConstraintIsDampedRotarySpring*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsDampedRotarySpring", header: "<chipmunk/chipmunk.h>".}
## Function type used for damped rotary spring force callbacks.

type
  cpDampedRotarySpringTorqueFunc* = proc (spring: ptr cpConstraint;
                                       relativeAngle: cpFloat): cpFloat

## Allocate a damped rotary spring.

proc cpDampedRotarySpringAlloc*(): ptr cpDampedRotarySpring {.
    importc: "cpDampedRotarySpringAlloc", header: "<chipmunk/chipmunk.h>".}
## Initialize a damped rotary spring.

proc cpDampedRotarySpringInit*(joint: ptr cpDampedRotarySpring; a: ptr cpBody;
                              b: ptr cpBody; restAngle: cpFloat; stiffness: cpFloat;
                              damping: cpFloat): ptr cpDampedRotarySpring {.
    importc: "cpDampedRotarySpringInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a damped rotary spring.

proc cpDampedRotarySpringNew*(a: ptr cpBody; b: ptr cpBody; restAngle: cpFloat;
                             stiffness: cpFloat; damping: cpFloat): ptr cpConstraint {.
    importc: "cpDampedRotarySpringNew", header: "<chipmunk/chipmunk.h>".}
## Get the rest length of the spring.

proc cpDampedRotarySpringGetRestAngle*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedRotarySpringGetRestAngle", header: "<chipmunk/chipmunk.h>".}
## Set the rest length of the spring.

proc cpDampedRotarySpringSetRestAngle*(constraint: ptr cpConstraint;
                                      restAngle: cpFloat) {.
    importc: "cpDampedRotarySpringSetRestAngle", header: "<chipmunk/chipmunk.h>".}
## Get the stiffness of the spring in force/distance.

proc cpDampedRotarySpringGetStiffness*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedRotarySpringGetStiffness", header: "<chipmunk/chipmunk.h>".}
## Set the stiffness of the spring in force/distance.

proc cpDampedRotarySpringSetStiffness*(constraint: ptr cpConstraint;
                                      stiffness: cpFloat) {.
    importc: "cpDampedRotarySpringSetStiffness", header: "<chipmunk/chipmunk.h>".}
## Get the damping of the spring.

proc cpDampedRotarySpringGetDamping*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedRotarySpringGetDamping", header: "<chipmunk/chipmunk.h>".}
## Set the damping of the spring.

proc cpDampedRotarySpringSetDamping*(constraint: ptr cpConstraint; damping: cpFloat) {.
    importc: "cpDampedRotarySpringSetDamping", header: "<chipmunk/chipmunk.h>".}
## Get the damping of the spring.

proc cpDampedRotarySpringGetSpringTorqueFunc*(constraint: ptr cpConstraint): cpDampedRotarySpringTorqueFunc {.
    importc: "cpDampedRotarySpringGetSpringTorqueFunc",
    header: "<chipmunk/chipmunk.h>".}
## Set the damping of the spring.

proc cpDampedRotarySpringSetSpringTorqueFunc*(constraint: ptr cpConstraint;
    springTorqueFunc: cpDampedRotarySpringTorqueFunc) {.
    importc: "cpDampedRotarySpringSetSpringTorqueFunc",
    header: "<chipmunk/chipmunk.h>".}

## Check if a constraint is a damped rotary springs.

proc cpConstraintIsRotaryLimitJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsRotaryLimitJoint", header: "<chipmunk/chipmunk.h>".}
## Allocate a damped rotary limit joint.

proc cpRotaryLimitJointAlloc*(): ptr cpRotaryLimitJoint {.
    importc: "cpRotaryLimitJointAlloc", header: "<chipmunk/chipmunk.h>".}
## Initialize a damped rotary limit joint.

proc cpRotaryLimitJointInit*(joint: ptr cpRotaryLimitJoint; a: ptr cpBody;
                            b: ptr cpBody; min: cpFloat; max: cpFloat): ptr cpRotaryLimitJoint {.
    importc: "cpRotaryLimitJointInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a damped rotary limit joint.

proc cpRotaryLimitJointNew*(a: ptr cpBody; b: ptr cpBody; min: cpFloat; max: cpFloat): ptr cpConstraint {.
    importc: "cpRotaryLimitJointNew", header: "<chipmunk/chipmunk.h>".}
## Get the minimum distance the joint will maintain between the two anchors.

proc cpRotaryLimitJointGetMin*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRotaryLimitJointGetMin", header: "<chipmunk/chipmunk.h>".}
## Set the minimum distance the joint will maintain between the two anchors.

proc cpRotaryLimitJointSetMin*(constraint: ptr cpConstraint; min: cpFloat) {.
    importc: "cpRotaryLimitJointSetMin", header: "<chipmunk/chipmunk.h>".}
## Get the maximum distance the joint will maintain between the two anchors.

proc cpRotaryLimitJointGetMax*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRotaryLimitJointGetMax", header: "<chipmunk/chipmunk.h>".}
## Set the maximum distance the joint will maintain between the two anchors.

proc cpRotaryLimitJointSetMax*(constraint: ptr cpConstraint; max: cpFloat) {.
    importc: "cpRotaryLimitJointSetMax", header: "<chipmunk/chipmunk.h>".}

## Check if a constraint is a damped rotary springs.

proc cpConstraintIsRatchetJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsRatchetJoint", header: "<chipmunk/chipmunk.h>".}
## Allocate a ratchet joint.

proc cpRatchetJointAlloc*(): ptr cpRatchetJoint {.importc: "cpRatchetJointAlloc",
    header: "<chipmunk/chipmunk.h>".}
## Initialize a ratched joint.

proc cpRatchetJointInit*(joint: ptr cpRatchetJoint; a: ptr cpBody; b: ptr cpBody;
                        phase: cpFloat; ratchet: cpFloat): ptr cpRatchetJoint {.
    importc: "cpRatchetJointInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a ratchet joint.

proc cpRatchetJointNew*(a: ptr cpBody; b: ptr cpBody; phase: cpFloat; ratchet: cpFloat): ptr cpConstraint {.
    importc: "cpRatchetJointNew", header: "<chipmunk/chipmunk.h>".}
## Get the angle of the current ratchet tooth.

proc cpRatchetJointGetAngle*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRatchetJointGetAngle", header: "<chipmunk/chipmunk.h>".}
## Set the angle of the current ratchet tooth.

proc cpRatchetJointSetAngle*(constraint: ptr cpConstraint; angle: cpFloat) {.
    importc: "cpRatchetJointSetAngle", header: "<chipmunk/chipmunk.h>".}
## Get the phase offset of the ratchet.

proc cpRatchetJointGetPhase*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRatchetJointGetPhase", header: "<chipmunk/chipmunk.h>".}
## Get the phase offset of the ratchet.

proc cpRatchetJointSetPhase*(constraint: ptr cpConstraint; phase: cpFloat) {.
    importc: "cpRatchetJointSetPhase", header: "<chipmunk/chipmunk.h>".}
## Get the angular distance of each ratchet.

proc cpRatchetJointGetRatchet*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRatchetJointGetRatchet", header: "<chipmunk/chipmunk.h>".}
## Set the angular distance of each ratchet.

proc cpRatchetJointSetRatchet*(constraint: ptr cpConstraint; ratchet: cpFloat) {.
    importc: "cpRatchetJointSetRatchet", header: "<chipmunk/chipmunk.h>".}

## Check if a constraint is a damped rotary springs.

proc cpConstraintIsGearJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsGearJoint", header: "<chipmunk/chipmunk.h>".}
## Allocate a gear joint.

proc cpGearJointAlloc*(): ptr cpGearJoint {.importc: "cpGearJointAlloc",
                                        header: "<chipmunk/chipmunk.h>".}
## Initialize a gear joint.

proc cpGearJointInit*(joint: ptr cpGearJoint; a: ptr cpBody; b: ptr cpBody;
                     phase: cpFloat; ratio: cpFloat): ptr cpGearJoint {.
    importc: "cpGearJointInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a gear joint.

proc cpGearJointNew*(a: ptr cpBody; b: ptr cpBody; phase: cpFloat; ratio: cpFloat): ptr cpConstraint {.
    importc: "cpGearJointNew", header: "<chipmunk/chipmunk.h>".}
## Get the phase offset of the gears.

proc cpGearJointGetPhase*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpGearJointGetPhase", header: "<chipmunk/chipmunk.h>".}
## Set the phase offset of the gears.

proc cpGearJointSetPhase*(constraint: ptr cpConstraint; phase: cpFloat) {.
    importc: "cpGearJointSetPhase", header: "<chipmunk/chipmunk.h>".}
## Get the angular distance of each ratchet.

proc cpGearJointGetRatio*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpGearJointGetRatio", header: "<chipmunk/chipmunk.h>".}
## Set the ratio of a gear joint.

proc cpGearJointSetRatio*(constraint: ptr cpConstraint; ratio: cpFloat) {.
    importc: "cpGearJointSetRatio", header: "<chipmunk/chipmunk.h>".}

## Opaque struct type for damped rotary springs.

type
  cpSimpleMotor* {.importc, incompleteStruct.} = object

## Check if a constraint is a damped rotary springs.

proc cpConstraintIsSimpleMotor*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsSimpleMotor", header: "<chipmunk/chipmunk.h>".}
## Allocate a simple motor.

proc cpSimpleMotorAlloc*(): ptr cpSimpleMotor {.importc: "cpSimpleMotorAlloc",
    header: "<chipmunk/chipmunk.h>".}
## initialize a simple motor.

proc cpSimpleMotorInit*(joint: ptr cpSimpleMotor; a: ptr cpBody; b: ptr cpBody;
                       rate: cpFloat): ptr cpSimpleMotor {.
    importc: "cpSimpleMotorInit", header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a simple motor.

proc cpSimpleMotorNew*(a: ptr cpBody; b: ptr cpBody; rate: cpFloat): ptr cpConstraint {.
    importc: "cpSimpleMotorNew", header: "<chipmunk/chipmunk.h>".}
## Get the rate of the motor.

proc cpSimpleMotorGetRate*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpSimpleMotorGetRate", header: "<chipmunk/chipmunk.h>".}
## Set the rate of the motor.

proc cpSimpleMotorSetRate*(constraint: ptr cpConstraint; rate: cpFloat) {.
    importc: "cpSimpleMotorSetRate", header: "<chipmunk/chipmunk.h>".}

## Collision begin event function callback type.
## Returning false from a begin callback causes the collision to be ignored until
## the the separate callback is called when the objects stop colliding.

type
  cpCollisionBeginFunc* = proc (arb: ptr cpArbiter; space: ptr cpSpace;
                             userData: cpDataPointer): cpBool {.cdecl.}

## Collision pre-solve event function callback type.
## Returning false from a pre-step callback causes the collision to be ignored until the next step.

type
  cpCollisionPreSolveFunc* = proc (arb: ptr cpArbiter; space: ptr cpSpace;
                                userData: cpDataPointer): cpBool {.cdecl.}

## Collision post-solve event function callback type.

type
  cpCollisionPostSolveFunc* = proc (arb: ptr cpArbiter; space: ptr cpSpace;
                                 userData: cpDataPointer) {.cdecl.}

## Collision separate event function callback type.

type
  cpCollisionSeparateFunc* = proc (arb: ptr cpArbiter; space: ptr cpSpace;
                                userData: cpDataPointer) {.cdecl.}

## Struct that holds function callback pointers to configure custom collision handling.
## Collision handlers have a pair of types; when a collision occurs between two shapes that have these types, the collision handler functions are triggered.

type
  cpCollisionHandler* {.importc: "cpCollisionHandler", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    typeA* {.importc: "typeA".}: cpCollisionType ## Collision type identifier of the first shape that this handler recognizes.
                                             ## In the collision handler callback, the shape with this type will be the first argument. Read only.
    ## Collision type identifier of the second shape that this handler recognizes.
    ## In the collision handler callback, the shape with this type will be the second argument. Read only.
    typeB* {.importc: "typeB".}: cpCollisionType ## This function is called when two shapes with types that match this collision handler begin colliding.
    beginFunc* {.importc: "beginFunc".}: cpCollisionBeginFunc ## This function is called each step when two shapes with types that match this collision handler are colliding.
                                                          ## It's called before the collision solver runs so that you can affect a collision's outcome.
    preSolveFunc* {.importc: "preSolveFunc".}: cpCollisionPreSolveFunc ## This function is called each step when two shapes with types that match this collision handler are colliding.
                                                                   ## It's called after the collision solver runs so that you can read back information about the collision to trigger events in your game.
    postSolveFunc* {.importc: "postSolveFunc".}: cpCollisionPostSolveFunc ## This function is called when two shapes with types that match this collision handler stop colliding.
    separateFunc* {.importc: "separateFunc".}: cpCollisionSeparateFunc ## This is a user definable context pointer that is passed to all of the collision handler functions.
    userData* {.importc: "userData".}: cpDataPointer


## TODO: Make timestep a parameter?
## Allocate a cpSpace.

proc cpSpaceAlloc*(): ptr cpSpace {.importc: "cpSpaceAlloc", header: "<chipmunk/chipmunk.h>".}
## Initialize a cpSpace.

proc cpSpaceInit*(space: ptr cpSpace): ptr cpSpace {.importc: "cpSpaceInit",
    header: "<chipmunk/chipmunk.h>".}
## Allocate and initialize a cpSpace.

proc cpSpaceNew*(): ptr cpSpace {.importc: "cpSpaceNew", header: "<chipmunk/chipmunk.h>".}
## Destroy a cpSpace.

proc cpSpaceDestroy*(space: ptr cpSpace) {.importc: "cpSpaceDestroy",
                                       header: "<chipmunk/chipmunk.h>".}
## Destroy and free a cpSpace.

proc cpSpaceFree*(space: ptr cpSpace) {.importc: "cpSpaceFree", header: "<chipmunk/chipmunk.h>".}
## Number of iterations to use in the impulse solver to solve contacts and other constraints.

proc cpSpaceGetIterations*(space: ptr cpSpace): cint {.
    importc: "cpSpaceGetIterations", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetIterations*(space: ptr cpSpace; iterations: cint) {.
    importc: "cpSpaceSetIterations", header: "<chipmunk/chipmunk.h>".}
## Gravity to pass to rigid bodies when integrating velocity.

proc cpSpaceGetGravity*(space: ptr cpSpace): cpVect {.importc: "cpSpaceGetGravity",
    header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetGravity*(space: ptr cpSpace; gravity: cpVect) {.
    importc: "cpSpaceSetGravity", header: "<chipmunk/chipmunk.h>".}
## Damping rate expressed as the fraction of velocity bodies retain each second.
## A value of 0.9 would mean that each body's velocity will drop 10% per second.
## The default value is 1.0, meaning no damping is applied.
## @note This damping value is different than those of cpDampedSpring and cpDampedRotarySpring.

proc cpSpaceGetDamping*(space: ptr cpSpace): cpFloat {.importc: "cpSpaceGetDamping",
    header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetDamping*(space: ptr cpSpace; damping: cpFloat) {.
    importc: "cpSpaceSetDamping", header: "<chipmunk/chipmunk.h>".}
## Speed threshold for a body to be considered idle.
## The default value of 0 means to let the space guess a good threshold based on gravity.

proc cpSpaceGetIdleSpeedThreshold*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetIdleSpeedThreshold", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetIdleSpeedThreshold*(space: ptr cpSpace; idleSpeedThreshold: cpFloat) {.
    importc: "cpSpaceSetIdleSpeedThreshold", header: "<chipmunk/chipmunk.h>".}
## Time a group of bodies must remain idle in order to fall asleep.
## Enabling sleeping also implicitly enables the the contact graph.
## The default value of INFINITY disables the sleeping algorithm.

proc cpSpaceGetSleepTimeThreshold*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetSleepTimeThreshold", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetSleepTimeThreshold*(space: ptr cpSpace; sleepTimeThreshold: cpFloat) {.
    importc: "cpSpaceSetSleepTimeThreshold", header: "<chipmunk/chipmunk.h>".}
## Amount of encouraged penetration between colliding shapes.
## Used to reduce oscillating contacts and keep the collision cache warm.
## Defaults to 0.1. If you have poor simulation quality,
## increase this number as much as possible without allowing visible amounts of overlap.

proc cpSpaceGetCollisionSlop*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetCollisionSlop", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetCollisionSlop*(space: ptr cpSpace; collisionSlop: cpFloat) {.
    importc: "cpSpaceSetCollisionSlop", header: "<chipmunk/chipmunk.h>".}
## Determines how fast overlapping shapes are pushed apart.
## Expressed as a fraction of the error remaining after each second.
## Defaults to pow(1.0 - 0.1, 60.0) meaning that Chipmunk fixes 10% of overlap each frame at 60Hz.

proc cpSpaceGetCollisionBias*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetCollisionBias", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetCollisionBias*(space: ptr cpSpace; collisionBias: cpFloat) {.
    importc: "cpSpaceSetCollisionBias", header: "<chipmunk/chipmunk.h>".}
## Number of frames that contact information should persist.
## Defaults to 3. There is probably never a reason to change this value.

proc cpSpaceGetCollisionPersistence*(space: ptr cpSpace): cpTimestamp {.
    importc: "cpSpaceGetCollisionPersistence", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetCollisionPersistence*(space: ptr cpSpace;
                                    collisionPersistence: cpTimestamp) {.
    importc: "cpSpaceSetCollisionPersistence", header: "<chipmunk/chipmunk.h>".}
## User definable data pointer.
## Generally this points to your game's controller or game state
## class so you can access it when given a cpSpace reference in a callback.

proc cpSpaceGetUserData*(space: ptr cpSpace): cpDataPointer {.
    importc: "cpSpaceGetUserData", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetUserData*(space: ptr cpSpace; userData: cpDataPointer) {.
    importc: "cpSpaceSetUserData", header: "<chipmunk/chipmunk.h>".}
## The Space provided static body for a given cpSpace.
## This is merely provided for convenience and you are not required to use it.

proc cpSpaceGetStaticBody*(space: ptr cpSpace): ptr cpBody {.
    importc: "cpSpaceGetStaticBody", header: "<chipmunk/chipmunk.h>".}
## Returns the current (or most recent) time step used with the given space.
## Useful from callbacks if your time step is not a compile-time global.

proc cpSpaceGetCurrentTimeStep*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetCurrentTimeStep", header: "<chipmunk/chipmunk.h>".}
## returns true from inside a callback when objects cannot be added/removed.

proc cpSpaceIsLocked*(space: ptr cpSpace): cpBool {.importc: "cpSpaceIsLocked",
    header: "<chipmunk/chipmunk.h>".}
## Create or return the existing collision handler that is called for all collisions that are not handled by a more specific collision handler.

proc cpSpaceAddDefaultCollisionHandler*(space: ptr cpSpace): ptr cpCollisionHandler {.
    importc: "cpSpaceAddDefaultCollisionHandler", header: "<chipmunk/chipmunk.h>".}
## Create or return the existing collision handler for the specified pair of collision types.
## If wildcard handlers are used with either of the collision types, it's the responibility of the custom handler to invoke the wildcard handlers.

proc cpSpaceAddCollisionHandler*(space: ptr cpSpace; a: cpCollisionType;
                                b: cpCollisionType): ptr cpCollisionHandler {.
    importc: "cpSpaceAddCollisionHandler", header: "<chipmunk/chipmunk.h>".}
## Create or return the existing wildcard collision handler for the specified type.

proc cpSpaceAddWildcardHandler*(space: ptr cpSpace; `type`: cpCollisionType): ptr cpCollisionHandler {.
    importc: "cpSpaceAddWildcardHandler", header: "<chipmunk/chipmunk.h>".}
## Add a collision shape to the simulation.
## If the shape is attached to a static body, it will be added as a static shape.

proc cpSpaceAddShape*(space: ptr cpSpace; shape: ptr cpShape): ptr cpShape {.
    importc: "cpSpaceAddShape", header: "<chipmunk/chipmunk.h>".}
## Add a rigid body to the simulation.

proc cpSpaceAddBody*(space: ptr cpSpace; body: ptr cpBody): ptr cpBody {.
    importc: "cpSpaceAddBody", header: "<chipmunk/chipmunk.h>".}
## Add a constraint to the simulation.

proc cpSpaceAddConstraint*(space: ptr cpSpace; constraint: ptr cpConstraint): ptr cpConstraint {.
    importc: "cpSpaceAddConstraint", header: "<chipmunk/chipmunk.h>".}
## Remove a collision shape from the simulation.

proc cpSpaceRemoveShape*(space: ptr cpSpace; shape: ptr cpShape) {.
    importc: "cpSpaceRemoveShape", header: "<chipmunk/chipmunk.h>".}
## Remove a rigid body from the simulation.

proc cpSpaceRemoveBody*(space: ptr cpSpace; body: ptr cpBody) {.
    importc: "cpSpaceRemoveBody", header: "<chipmunk/chipmunk.h>".}
## Remove a constraint from the simulation.

proc cpSpaceRemoveConstraint*(space: ptr cpSpace; constraint: ptr cpConstraint) {.
    importc: "cpSpaceRemoveConstraint", header: "<chipmunk/chipmunk.h>".}
## Test if a collision shape has been added to the space.

proc cpSpaceContainsShape*(space: ptr cpSpace; shape: ptr cpShape): cpBool {.
    importc: "cpSpaceContainsShape", header: "<chipmunk/chipmunk.h>".}
## Test if a rigid body has been added to the space.

proc cpSpaceContainsBody*(space: ptr cpSpace; body: ptr cpBody): cpBool {.
    importc: "cpSpaceContainsBody", header: "<chipmunk/chipmunk.h>".}
## Test if a constraint has been added to the space.

proc cpSpaceContainsConstraint*(space: ptr cpSpace; constraint: ptr cpConstraint): cpBool {.
    importc: "cpSpaceContainsConstraint", header: "<chipmunk/chipmunk.h>".}
## Post Step callback function type.

type
  cpPostStepFunc* = proc (space: ptr cpSpace; key: pointer; data: pointer) {.cdecl.}

## Schedule a post-step callback to be called when cpSpaceStep() finishes.
## You can only register one callback per unique value for @c key.
## Returns true only if @c key has never been scheduled before.
## It's possible to pass @c NULL for @c func if you only want to mark @c key as being used.

proc cpSpaceAddPostStepCallback*(space: ptr cpSpace; `func`: cpPostStepFunc;
                                key: pointer; data: pointer): cpBool {.
    importc: "cpSpaceAddPostStepCallback", header: "<chipmunk/chipmunk.h>".}
## TODO: Queries and iterators should take a cpSpace parametery.
## TODO: They should also be abortable.
## Nearest point query callback function type.

type
  cpSpacePointQueryFunc* = proc (shape: ptr cpShape; point: cpVect; distance: cpFloat;
                              gradient: cpVect; data: pointer) {.cdecl.}

## Query the space at a point and call @c func for each shape found.

proc cpSpacePointQuery*(space: ptr cpSpace; point: cpVect; maxDistance: cpFloat;
                       filter: cpShapeFilter; `func`: cpSpacePointQueryFunc;
                       data: pointer) {.importc: "cpSpacePointQuery",
                                      header: "<chipmunk/chipmunk.h>".}
## Query the space at a point and return the nearest shape found. Returns NULL if no shapes were found.

proc cpSpacePointQueryNearest*(space: ptr cpSpace; point: cpVect;
                              maxDistance: cpFloat; filter: cpShapeFilter;
                              `out`: ptr cpPointQueryInfo): ptr cpShape {.
    importc: "cpSpacePointQueryNearest", header: "<chipmunk/chipmunk.h>".}
## Segment query callback function type.

type
  cpSpaceSegmentQueryFunc* = proc (shape: ptr cpShape; point: cpVect; normal: cpVect;
                                alpha: cpFloat; data: pointer) {.cdecl.}

## Perform a directed line segment query (like a raycast) against the space calling @c func for each shape intersected.

proc cpSpaceSegmentQuery*(space: ptr cpSpace; start: cpVect; `end`: cpVect;
                         radius: cpFloat; filter: cpShapeFilter;
                         `func`: cpSpaceSegmentQueryFunc; data: pointer) {.
    importc: "cpSpaceSegmentQuery", header: "<chipmunk/chipmunk.h>".}
## Perform a directed line segment query (like a raycast) against the space and return the first shape hit. Returns NULL if no shapes were hit.

proc cpSpaceSegmentQueryFirst*(space: ptr cpSpace; start: cpVect; `end`: cpVect;
                              radius: cpFloat; filter: cpShapeFilter;
                              `out`: ptr cpSegmentQueryInfo): ptr cpShape {.
    importc: "cpSpaceSegmentQueryFirst", header: "<chipmunk/chipmunk.h>".}
## Rectangle Query callback function type.

type
  cpSpaceBBQueryFunc* = proc (shape: ptr cpShape; data: pointer) {.cdecl.}

## Perform a fast rectangle query on the space calling @c func for each shape found.
## Only the shape's bounding boxes are checked for overlap, not their full shape.

proc cpSpaceBBQuery*(space: ptr cpSpace; bb: cpBB; filter: cpShapeFilter;
                    `func`: cpSpaceBBQueryFunc; data: pointer) {.
    importc: "cpSpaceBBQuery", header: "<chipmunk/chipmunk.h>".}
## Shape query callback function type.

type
  cpSpaceShapeQueryFunc* = proc (shape: ptr cpShape; points: ptr cpContactPointSet;
                              data: pointer) {.cdecl.}

## Query a space for any shapes overlapping the given shape and call @c func for each shape found.

proc cpSpaceShapeQuery*(space: ptr cpSpace; shape: ptr cpShape;
                       `func`: cpSpaceShapeQueryFunc; data: pointer): cpBool {.
    importc: "cpSpaceShapeQuery", header: "<chipmunk/chipmunk.h>".}
## Space/body iterator callback function type.

type
  cpSpaceBodyIteratorFunc* = proc (body: ptr cpBody; data: pointer) {.cdecl.}

## Call @c func for each body in the space.

proc cpSpaceEachBody*(space: ptr cpSpace; `func`: cpSpaceBodyIteratorFunc;
                     data: pointer) {.importc: "cpSpaceEachBody",
                                    header: "<chipmunk/chipmunk.h>".}
## Space/body iterator callback function type.

type
  cpSpaceShapeIteratorFunc* = proc (shape: ptr cpShape; data: pointer) {.cdecl.}

## Call @c func for each shape in the space.

proc cpSpaceEachShape*(space: ptr cpSpace; `func`: cpSpaceShapeIteratorFunc;
                      data: pointer) {.importc: "cpSpaceEachShape",
                                     header: "<chipmunk/chipmunk.h>".}
## Space/constraint iterator callback function type.

type
  cpSpaceConstraintIteratorFunc* = proc (constraint: ptr cpConstraint; data: pointer) {.cdecl.}

## Call @c func for each shape in the space.

proc cpSpaceEachConstraint*(space: ptr cpSpace;
                           `func`: cpSpaceConstraintIteratorFunc; data: pointer) {.
    importc: "cpSpaceEachConstraint", header: "<chipmunk/chipmunk.h>".}
## Update the collision detection info for the static shapes in the space.

proc cpSpaceReindexStatic*(space: ptr cpSpace) {.importc: "cpSpaceReindexStatic",
    header: "<chipmunk/chipmunk.h>".}
## Update the collision detection data for a specific shape in the space.

proc cpSpaceReindexShape*(space: ptr cpSpace; shape: ptr cpShape) {.
    importc: "cpSpaceReindexShape", header: "<chipmunk/chipmunk.h>".}
## Update the collision detection data for all shapes attached to a body.

proc cpSpaceReindexShapesForBody*(space: ptr cpSpace; body: ptr cpBody) {.
    importc: "cpSpaceReindexShapesForBody", header: "<chipmunk/chipmunk.h>".}
## Switch the space to use a spatial has as it's spatial index.

proc cpSpaceUseSpatialHash*(space: ptr cpSpace; dim: cpFloat; count: cint) {.
    importc: "cpSpaceUseSpatialHash", header: "<chipmunk/chipmunk.h>".}
## Step the space forward in time by @c dt.

proc cpSpaceStep*(space: ptr cpSpace; dt: cpFloat) {.importc: "cpSpaceStep",
    header: "<chipmunk/chipmunk.h>".}

## Version string.

var cpVersionString* {.importc: "cpVersionString", header: "<chipmunk/chipmunk.h>".}: cstring

## Calculate the moment of inertia for a circle.
## @c r1 and @c r2 are the inner and outer diameters. A solid circle has an inner diameter of 0.

proc cpMomentForCircle*(m: cpFloat; r1: cpFloat; r2: cpFloat; offset: cpVect): cpFloat {.
    importc: "cpMomentForCircle", header: "<chipmunk/chipmunk.h>".}
## Calculate area of a hollow circle.
## @c r1 and @c r2 are the inner and outer diameters. A solid circle has an inner diameter of 0.

proc cpAreaForCircle*(r1: cpFloat; r2: cpFloat): cpFloat {.importc: "cpAreaForCircle",
    header: "<chipmunk/chipmunk.h>".}
## Calculate the moment of inertia for a line segment.
## Beveling radius is not supported.

proc cpMomentForSegment*(m: cpFloat; a: cpVect; b: cpVect; radius: cpFloat): cpFloat {.
    importc: "cpMomentForSegment", header: "<chipmunk/chipmunk.h>".}
## Calculate the area of a fattened (capsule shaped) line segment.

proc cpAreaForSegment*(a: cpVect; b: cpVect; radius: cpFloat): cpFloat {.
    importc: "cpAreaForSegment", header: "<chipmunk/chipmunk.h>".}
## Calculate the moment of inertia for a solid polygon shape assuming it's center of gravity is at it's centroid. The offset is added to each vertex.

proc cpMomentForPoly*(m: cpFloat; count: cint; verts: ptr cpVect; offset: cpVect;
                     radius: cpFloat): cpFloat {.importc: "cpMomentForPoly",
    header: "<chipmunk/chipmunk.h>".}
## Calculate the signed area of a polygon. A Clockwise winding gives positive area.
## This is probably backwards from what you expect, but matches Chipmunk's the winding for poly shapes.

proc cpAreaForPoly*(count: cint; verts: ptr cpVect; radius: cpFloat): cpFloat {.
    importc: "cpAreaForPoly", header: "<chipmunk/chipmunk.h>".}
## Calculate the natural centroid of a polygon.

proc cpCentroidForPoly*(count: cint; verts: ptr cpVect): cpVect {.
    importc: "cpCentroidForPoly", header: "<chipmunk/chipmunk.h>".}
## Calculate the moment of inertia for a solid box.

proc cpMomentForBox*(m: cpFloat; width: cpFloat; height: cpFloat): cpFloat {.
    importc: "cpMomentForBox", header: "<chipmunk/chipmunk.h>".}
## Calculate the moment of inertia for a solid box.

proc cpMomentForBox2*(m: cpFloat; box: cpBB): cpFloat {.importc: "cpMomentForBox2",
    header: "<chipmunk/chipmunk.h>".}

proc cpConvexHull*(count: cint; verts: ptr cpVect; result: ptr cpVect; first: ptr cint;
                  tol: cpFloat): cint {.importc: "cpConvexHull", header: "<chipmunk/chipmunk.h>".}

proc cpClosetPointOnSegment*(p: cpVect; a: cpVect; b: cpVect): cpVect {.inline.} =
  var delta: cpVect
  var t: cpFloat
  return cpvadd(b, cpvmult(delta, t))
