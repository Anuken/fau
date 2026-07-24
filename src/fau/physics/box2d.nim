import std/[hashes, tables]
import ../fmath
import pkg/box2d #https://github.com/jon-edward/box2d.nim

type
  BodyKind* = enum
    bkStatic
    bkKinematic
    bkDynamic

  ShapeKind* = enum
    skCircle
    skSegment
    skCapsule
    skPolygon
    skChain

  WorldObj = object
    raw: b2WorldId
    bodies: seq[Body]

  World* = ref WorldObj

  BodyObj = object of RootObj
    raw: b2BodyId

  Body* = ref BodyObj

  UserBody*[T] {.final.} = ref object of BodyObj
    user*: T  ## user data, set this to whatever you like

  ShapeObj = object of RootObj
    raw: b2ShapeId
    body: Body

  Shape* = ref ShapeObj
  CircleShape* = ref ShapeObj
  SegmentShape* = ref ShapeObj
  CapsuleShape* = ref ShapeObj
  PolygonShape* = ref ShapeObj
  ChainShape* = ref ShapeObj

  JointObj = object of RootObj
    raw: b2JointId
    bodyA, bodyB: Body

  Joint* = ref JointObj
  DistanceJoint* = ref JointObj
  RevoluteJoint* = ref JointObj
  PrismaticJoint* = ref JointObj
  WeldJoint* = ref JointObj
  WheelJoint* = ref JointObj
  MotorJoint* = ref JointObj
  MouseJoint* = ref JointObj
  FilterJoint* = ref JointObj

  ShapeFilter* = object
    ## Collision filter: shapes collide if `(a.category and b.mask) != 0` and `(b.category and a.mask) != 0`, unless they share a nonzero `group` (positive: always collide, negative: never collide).
    category*: uint64
    mask*: uint64
    group*: int32

  Manifold* = object
    ## Contact manifold data passed to contact callbacks.
    raw: b2Manifold

# ---------------------------------------------------------------------------
# common / hashing / equality
# ---------------------------------------------------------------------------

proc hash*(b: Body): Hash {.inline.} = hash(cast[pointer](b))
proc hash*(s: Shape): Hash {.inline.} = hash(cast[pointer](s))
proc `==`*(a, b: Body): bool {.inline.} = a.raw == b.raw
proc `==`*(a, b: Shape): bool {.inline.} = a.raw == b.raw

converter toB2Vec2*(v: Vec2): b2Vec2 {.inline.} = b2Vec2(x: v.x.cfloat, y: v.y.cfloat)
converter toVec2*(v: b2Vec2): Vec2 {.inline.} = vec2(v.x.float32, v.y.float32)

# ---------------------------------------------------------------------------
# destructors - no manual destroy() calls needed anywhere
# ---------------------------------------------------------------------------

proc `=destroy`(s: var ShapeObj) =
  if b2Shape_IsValid(s.raw):
    b2DestroyShape(s.raw, true)

proc `=destroy`(j: var JointObj) =
  if b2Joint_IsValid(j.raw):
    b2DestroyJoint(j.raw)

proc `=destroy`(b: var BodyObj) =
  if b2Body_IsValid(b.raw):
    b2DestroyBody(b.raw)

proc `=destroy`(w: var WorldObj) =
  if b2World_IsValid(w.raw):
    b2DestroyWorld(w.raw)

# ---------------------------------------------------------------------------
# world
# ---------------------------------------------------------------------------

proc newWorld*(gravity: Vec2 = vec2(0, -10)): World =
  ## Creates a new physics world with the given gravity vector.
  var def = b2DefaultWorldDef()
  def.gravity = gravity
  result = World(raw: b2CreateWorld(def.addr), bodies: @[])

proc gravity*(world: World): Vec2 {.inline.} =
  b2World_GetGravity(world.raw)

proc `gravity=`*(world: World, g: Vec2) {.inline.} =
  b2World_SetGravity(world.raw, g)

proc step*(world: World, timeStep: float32, subStepCount: int = 4) {.inline.} =
  ## Advances the simulation by `timeStep` seconds using `subStepCount`
  ## velocity/position sub-steps (Box2D 3's TGS soft solver).
  b2World_Step(world.raw, timeStep.cfloat, subStepCount.cint)

proc enableSleeping*(world: World, enable: bool) {.inline.} =
  b2World_EnableSleeping(world.raw, enable)

proc explode*(world: World, position: Vec2, radius, impulse: float32) {.inline.} =
  var def = b2DefaultExplosionDef()
  def.position = position
  def.radius = radius.cfloat
  def.impulsePerLength = impulse.cfloat
  b2World_Explode(world.raw, def.addr)

# ---------------------------------------------------------------------------
# body
# ---------------------------------------------------------------------------

proc toRaw(kind: BodyKind): b2BodyType {.inline.} =
  case kind
  of bkStatic: b2_staticBody
  of bkKinematic: b2_kinematicBody
  of bkDynamic: b2_dynamicBody

proc toBodyKind(raw: b2BodyType): BodyKind {.inline.} =
  case raw
  of b2_staticBody: bkStatic
  of b2_kinematicBody: bkKinematic
  of b2_dynamicBody: bkDynamic
  else: raiseAssert "invalid body type - is this a valid body id?"

proc newBody*(world: World, kind: BodyKind = bkStatic, position: Vec2 = vec2(0, 0),
              angle: float32 = 0, fixedRotation = false): Body =
  ## Creates a new body in `world`.
  var def = b2DefaultBodyDef()
  def.bodyType = kind.toRaw
  def.position = position
  def.rotation = b2MakeRot(angle.cfloat)
  def.fixedRotation = fixedRotation
  result = Body(raw: b2CreateBody(world.raw, def.addr))
  world.bodies.add(result)

proc newUserBody*[T](world: World, user: T, kind: BodyKind = bkStatic,
                      position: Vec2 = vec2(0, 0), angle: float32 = 0,
                      fixedRotation = false): UserBody[T] =
  ## Like `newBody` but also stores arbitrary user data on the body.
  var def = b2DefaultBodyDef()
  def.bodyType = kind.toRaw
  def.position = position
  def.rotation = b2MakeRot(angle.cfloat)
  def.fixedRotation = fixedRotation
  result = UserBody[T](raw: b2CreateBody(world.raw, def.addr), user: user)
  world.bodies.add(Body(result))

{.push inline.}

proc kind*(body: Body): BodyKind = body.raw.b2Body_GetType.toBodyKind
proc `kind=`*(body: Body, newKind: BodyKind) = b2Body_SetType(body.raw, newKind.toRaw)

proc position*(body: Body): Vec2 = b2Body_GetPosition(body.raw)
proc angle*(body: Body): float32 = b2Body_GetRotation(body.raw).b2Rot_GetAngle

proc `position=`*(body: Body, pos: Vec2) =
  b2Body_SetTransform(body.raw, pos, b2Body_GetRotation(body.raw))

proc `angle=`*(body: Body, ang: float32) =
  b2Body_SetTransform(body.raw, b2Body_GetPosition(body.raw), b2MakeRot(ang.cfloat))

proc setTransform*(body: Body, pos: Vec2, ang: float32) =
  b2Body_SetTransform(body.raw, pos, b2MakeRot(ang.cfloat))

#shorthand, matching the chipmunk sample's `pos`
proc pos*(body: Body): Vec2 = body.position
proc `pos=`*(body: Body, p: Vec2) = body.position = p

proc mass*(body: Body): float32 = b2Body_GetMass(body.raw)
proc rotationalInertia*(body: Body): float32 = b2Body_GetRotationalInertia(body.raw)

proc localCenter*(body: Body): Vec2 = b2Body_GetLocalCenterOfMass(body.raw)
proc worldCenter*(body: Body): Vec2 = b2Body_GetWorldCenterOfMass(body.raw)

proc velocity*(body: Body): Vec2 = b2Body_GetLinearVelocity(body.raw)
proc `velocity=`*(body: Body, v: Vec2) = b2Body_SetLinearVelocity(body.raw, v)

proc angularVelocity*(body: Body): float32 = b2Body_GetAngularVelocity(body.raw)
proc `angularVelocity=`*(body: Body, w: float32) =
  b2Body_SetAngularVelocity(body.raw, w.cfloat)

proc linearDamping*(body: Body): float32 = b2Body_GetLinearDamping(body.raw)
proc `linearDamping=`*(body: Body, d: float32) = b2Body_SetLinearDamping(body.raw, d.cfloat)

proc angularDamping*(body: Body): float32 = b2Body_GetAngularDamping(body.raw)
proc `angularDamping=`*(body: Body, d: float32) = b2Body_SetAngularDamping(body.raw, d.cfloat)

proc gravityScale*(body: Body): float32 = b2Body_GetGravityScale(body.raw)
proc `gravityScale=`*(body: Body, s: float32) = b2Body_SetGravityScale(body.raw, s.cfloat)

proc isAwake*(body: Body): bool = b2Body_IsAwake(body.raw)
proc wake*(body: Body) = b2Body_SetAwake(body.raw, true)
proc sleep*(body: Body) = b2Body_SetAwake(body.raw, false)

proc isEnabled*(body: Body): bool = b2Body_IsEnabled(body.raw)
proc enable*(body: Body) = b2Body_Enable(body.raw)
proc disable*(body: Body) = b2Body_Disable(body.raw)

proc fixedRotation*(body: Body): bool = b2Body_IsFixedRotation(body.raw)
proc `fixedRotation=`*(body: Body, v: bool) = b2Body_SetFixedRotation(body.raw, v)

proc isBullet*(body: Body): bool = b2Body_IsBullet(body.raw)
proc `isBullet=`*(body: Body, v: bool) = b2Body_SetBullet(body.raw, v)

proc applyForce*(body: Body, force, point: Vec2, wake = true) =
  b2Body_ApplyForce(body.raw, force, point, wake)

proc applyForceToCenter*(body: Body, force: Vec2, wake = true) =
  b2Body_ApplyForceToCenter(body.raw, force, wake)

proc applyTorque*(body: Body, torque: float32, wake = true) =
  b2Body_ApplyTorque(body.raw, torque.cfloat, wake)

proc applyLinearImpulse*(body: Body, impulse, point: Vec2, wake = true) =
  b2Body_ApplyLinearImpulse(body.raw, impulse, point, wake)

proc applyLinearImpulseToCenter*(body: Body, impulse: Vec2, wake = true) =
  b2Body_ApplyLinearImpulseToCenter(body.raw, impulse, wake)

proc applyAngularImpulse*(body: Body, impulse: float32, wake = true) =
  b2Body_ApplyAngularImpulse(body.raw, impulse.cfloat, wake)

proc worldPoint*(body: Body, localPoint: Vec2): Vec2 =
  b2Body_GetWorldPoint(body.raw, localPoint)

proc localPoint*(body: Body, worldPoint: Vec2): Vec2 =
  b2Body_GetLocalPoint(body.raw, worldPoint)

{.pop.}

iterator bodies*(world: World): Body =
  ## Iterates over all bodies created in `world`.
  for b in world.bodies: yield b

# ---------------------------------------------------------------------------
# shapes
# ---------------------------------------------------------------------------

proc defaultShapeDef(density, friction, restitution: float32,
                      filter: ShapeFilter, isSensor: bool): b2ShapeDef =
  result = b2DefaultShapeDef()
  result.density = density.cfloat
  result.material.friction = friction.cfloat
  result.material.restitution = restitution.cfloat
  result.isSensor = isSensor
  result.filter = b2Filter(
    categoryBits: filter.category.uint64,
    maskBits: filter.mask.uint64,
    groupIndex: filter.group.cint)

proc newCircleShape*(body: Body, radius: float32, center = vec2(0, 0),
                      density = 1.0f, friction = 0.6f, restitution = 0.0f,
                      isSensor = false,
                      filter = ShapeFilter(category: 1, mask: high(uint64))): CircleShape =
  ## Attaches a circle shape to `body`.
  var def = defaultShapeDef(density, friction, restitution, filter, isSensor)
  var circle = b2Circle(center: center, radius: radius.cfloat)
  result = CircleShape(raw: b2CreateCircleShape(body.raw, def.addr, circle.addr),
                        body: body)

proc newSegmentShape*(body: Body, p1, p2: Vec2, density = 1.0f, friction = 0.6f,
                       restitution = 0.0f, isSensor = false,
                       filter = ShapeFilter(category: 1, mask: high(uint64))): SegmentShape =
  ## Attaches a line segment shape to `body`.
  var def = defaultShapeDef(density, friction, restitution, filter, isSensor)
  var segment = b2Segment(point1: p1, point2: p2)
  result = SegmentShape(raw: b2CreateSegmentShape(body.raw, def.addr, segment.addr),
                         body: body)

proc newCapsuleShape*(body: Body, p1, p2: Vec2, radius: float32, density = 1.0f,
                       friction = 0.6f, restitution = 0.0f, isSensor = false,
                       filter = ShapeFilter(category: 1, mask: high(uint64))): CapsuleShape =
  ## Attaches a capsule shape (a segment with rounded, radius-thick ends) to `body`.
  var def = defaultShapeDef(density, friction, restitution, filter, isSensor)
  var capsule = b2Capsule(center1: p1, center2: p2, radius: radius.cfloat)
  result = CapsuleShape(raw: b2CreateCapsuleShape(body.raw, def.addr, capsule.addr),
                         body: body)

proc newBoxShape*(body: Body, width, height: float32, center = vec2(0, 0),
                   angle: float32 = 0, density = 1.0f, friction = 0.6f,
                   restitution = 0.0f, isSensor = false,
                   filter = ShapeFilter(category: 1, mask: high(uint64))): PolygonShape =
  ## Attaches a rectangular polygon shape (`width` x `height`) to `body`.
  var def = defaultShapeDef(density, friction, restitution, filter, isSensor)
  var box = b2MakeOffsetBox(width * 0.5f, height * 0.5f, center, b2MakeRot(angle.cfloat))
  result = PolygonShape(raw: b2CreatePolygonShape(body.raw, def.addr, box.addr), body: body)

proc newPolygonShape*(body: Body, points: openArray[Vec2], radius: float32 = 0,
                       density = 1.0f, friction = 0.6f, restitution = 0.0f,
                       isSensor = false,
                       filter = ShapeFilter(category: 1, mask: high(uint64))): PolygonShape =
  ## Attaches a convex polygon shape to `body`. `points` should already
  ## describe a convex hull; use `b2ComputeHull` on the raw API first if not.
  var def = defaultShapeDef(density, friction, restitution, filter, isSensor)
  var raw: array[8, b2Vec2]
  assert points.len <= 8, "box2d polygons support at most 8 vertices"
  for i, p in points: raw[i] = p
  var hull = b2ComputeHull(raw[0].addr, points.len.cint)
  var polygon = b2MakePolygon(hull.addr, radius.cfloat)
  result = PolygonShape(raw: b2CreatePolygonShape(body.raw, def.addr, polygon.addr), body: body)

{.push inline.}

proc kind*(shape: Shape): ShapeKind =
  case b2Shape_GetType(shape.raw)
  of b2_circleShape: skCircle
  of b2_segmentShape: skSegment
  of b2_capsuleShape: skCapsule
  of b2_polygonShape: skPolygon
  of b2_chainSegmentShape: skChain
  else: raiseAssert("Invalid shape kind")

proc body*(shape: Shape): Body = shape.body

proc density*(shape: Shape): float32 = b2Shape_GetDensity(shape.raw)
proc `density=`*(shape: Shape, d: float32) = b2Shape_SetDensity(shape.raw, d.cfloat, true)

proc friction*(shape: Shape): float32 = b2Shape_GetFriction(shape.raw)
proc `friction=`*(shape: Shape, f: float32) = b2Shape_SetFriction(shape.raw, f.cfloat)

proc restitution*(shape: Shape): float32 = b2Shape_GetRestitution(shape.raw)
proc `restitution=`*(shape: Shape, r: float32) = b2Shape_SetRestitution(shape.raw, r.cfloat)

proc isSensor*(shape: Shape): bool = b2Shape_IsSensor(shape.raw)

proc filter*(shape: Shape): ShapeFilter =
  let f = b2Shape_GetFilter(shape.raw)
  ShapeFilter(category: f.categoryBits, mask: f.maskBits, group: f.groupIndex.int32)

proc `filter=`*(shape: Shape, filt: ShapeFilter) =
  b2Shape_SetFilter(shape.raw, b2Filter(categoryBits: filt.category, maskBits: filt.mask,
                                         groupIndex: filt.group.cint))

proc testPoint*(shape: Shape, point: Vec2): bool = b2Shape_TestPoint(shape.raw, point)

{.pop.}

iterator shapes*(body: Body): Shape =
  ## Iterates over all shapes attached to `body`.
  var buf: array[64, b2ShapeId]
  let count = b2Body_GetShapes(body.raw, buf[0].addr, 64)
  for i in 0 ..< count.int:
    yield Shape(raw: buf[i], body: body)

# ---------------------------------------------------------------------------
# joints
# ---------------------------------------------------------------------------

proc newDistanceJoint*(bodyA, bodyB: Body, anchorA, anchorB: Vec2,
                        length: float32 = -1, minLength = 0.0f,
                        maxLength = float32.high, enableSpring = false,
                        hertz = 0.0f, dampingRatio = 0.0f, enableLimit = false): DistanceJoint =
  ## Constrains two anchor points on `bodyA`/`bodyB` to a fixed (or spring-y, clamped) distance apart. If `length` is negative, it's computed from the current anchor positions.
  var def = b2DefaultDistanceJointDef()
  def.bodyIdA = bodyA.raw
  def.bodyIdB = bodyB.raw
  def.localAnchorA = anchorA
  def.localAnchorB = anchorB
  def.length = (if length < 0: (bodyB.worldPoint(anchorB) - bodyA.worldPoint(anchorA)).len else: length).cfloat
  def.minLength = minLength.cfloat
  def.maxLength = maxLength.cfloat
  def.enableSpring = enableSpring
  def.hertz = hertz.cfloat
  def.dampingRatio = dampingRatio.cfloat
  def.enableLimit = enableLimit
  result = DistanceJoint(raw: b2CreateDistanceJoint(b2Body_GetWorld(bodyA.raw), def.addr),
                          bodyA: bodyA, bodyB: bodyB)

proc newRevoluteJoint*(bodyA, bodyB: Body, anchorA, anchorB: Vec2,
                        enableLimit = false, lowerAngle = 0.0f, upperAngle = 0.0f,
                        enableMotor = false, motorSpeed = 0.0f,
                        maxMotorTorque = 0.0f): RevoluteJoint =
  ## A hinge joint: pins `bodyA` and `bodyB` together at a single point, allowing free rotation (optionally limited and/or motorized).
  var def = b2DefaultRevoluteJointDef()
  def.bodyIdA = bodyA.raw
  def.bodyIdB = bodyB.raw
  def.localAnchorA = anchorA
  def.localAnchorB = anchorB
  def.enableLimit = enableLimit
  def.lowerAngle = lowerAngle.cfloat
  def.upperAngle = upperAngle.cfloat
  def.enableMotor = enableMotor
  def.motorSpeed = motorSpeed.cfloat
  def.maxMotorTorque = maxMotorTorque.cfloat
  result = RevoluteJoint(raw: b2CreateRevoluteJoint(b2Body_GetWorld(bodyA.raw), def.addr),
                          bodyA: bodyA, bodyB: bodyB)

proc newPrismaticJoint*(bodyA, bodyB: Body, anchorA, anchorB, axis: Vec2,
                         enableLimit = false, lowerTranslation = 0.0f,
                         upperTranslation = 0.0f, enableMotor = false,
                         motorSpeed = 0.0f, maxMotorForce = 0.0f): PrismaticJoint =
  ## A sliding joint: constrains `bodyA`/`bodyB` to move along `axis` only.
  var def = b2DefaultPrismaticJointDef()
  def.bodyIdA = bodyA.raw
  def.bodyIdB = bodyB.raw
  def.localAnchorA = anchorA
  def.localAnchorB = anchorB
  def.localAxisA = axis
  def.enableLimit = enableLimit
  def.lowerTranslation = lowerTranslation.cfloat
  def.upperTranslation = upperTranslation.cfloat
  def.enableMotor = enableMotor
  def.motorSpeed = motorSpeed.cfloat
  def.maxMotorForce = maxMotorForce.cfloat
  result = PrismaticJoint(raw: b2CreatePrismaticJoint(b2Body_GetWorld(bodyA.raw), def.addr),
                           bodyA: bodyA, bodyB: bodyB)

proc newWeldJoint*(bodyA, bodyB: Body, anchorA, anchorB: Vec2,
                    linearHertz = 0.0f, angularHertz = 0.0f,
                    linearDampingRatio = 0.0f, angularDampingRatio = 0.0f): WeldJoint =
  ## Rigidly fuses `bodyA` and `bodyB` together (optionally with some spring "give" if hertz values are nonzero).
  var def = b2DefaultWeldJointDef()
  def.bodyIdA = bodyA.raw
  def.bodyIdB = bodyB.raw
  def.localAnchorA = anchorA
  def.localAnchorB = anchorB
  def.linearHertz = linearHertz.cfloat
  def.angularHertz = angularHertz.cfloat
  def.linearDampingRatio = linearDampingRatio.cfloat
  def.angularDampingRatio = angularDampingRatio.cfloat
  result = WeldJoint(raw: b2CreateWeldJoint(b2Body_GetWorld(bodyA.raw), def.addr),
                      bodyA: bodyA, bodyB: bodyB)

proc newMouseJoint*(bodyA, bodyB: Body, target: Vec2, hertz = 5.0f,
                     dampingRatio = 0.7f, maxForce = 1000.0f): MouseJoint =
  ## Drags `bodyB` towards a moving world-space `target` point, as if held by a mouse cursor. `bodyA` is typically a fixed/ground body.
  var def = b2DefaultMouseJointDef()
  def.bodyIdA = bodyA.raw
  def.bodyIdB = bodyB.raw
  def.target = target
  def.hertz = hertz.cfloat
  def.dampingRatio = dampingRatio.cfloat
  def.maxForce = maxForce.cfloat
  result = MouseJoint(raw: b2CreateMouseJoint(b2Body_GetWorld(bodyA.raw), def.addr),
                       bodyA: bodyA, bodyB: bodyB)

{.push inline.}

proc bodyA*(joint: Joint): Body = joint.bodyA
proc bodyB*(joint: Joint): Body = joint.bodyB

proc collideConnected*(joint: Joint): bool = b2Joint_GetCollideConnected(joint.raw)
proc `collideConnected=`*(joint: Joint, v: bool) = b2Joint_SetCollideConnected(joint.raw, v)

proc target*(joint: MouseJoint): Vec2 = b2MouseJoint_GetTarget(joint.raw)
proc `target=`*(joint: MouseJoint, t: Vec2) = b2MouseJoint_SetTarget(joint.raw, t)

proc motorSpeed*(joint: RevoluteJoint): float32 = b2RevoluteJoint_GetMotorSpeed(joint.raw)
proc `motorSpeed=`*(joint: RevoluteJoint, s: float32) =
  b2RevoluteJoint_SetMotorSpeed(joint.raw, s.cfloat)

proc angle*(joint: RevoluteJoint): float32 = b2RevoluteJoint_GetAngle(joint.raw)

{.pop.}