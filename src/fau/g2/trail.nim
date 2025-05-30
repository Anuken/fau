import ../draw, ../color, ../fmath, ../mesh, ../draw, ../globals, std/[sequtils, math]

type TrailPoint = object
  v: Vec2
  width: float32

type Trail* = object
  len: int
  frequency: float32 = 60f
  points: seq[TrailPoint]
  counter: float32
  lastAngle: float32 = -1f
  lastPos: Vec2 = vec2(-1f)
  lastWidth: float32 = 0f

proc initTrail*(len: int): Trail =
  Trail(len: len, points: newSeqOfCap[TrailPoint](len))

proc clear*(trail: var Trail) =
  trail.points.setLen(0)

proc pointLen*(trail: var Trail): int =
  trail.points.len

template initPoint(pos: Vec2, w: float32): TrailPoint = TrailPoint(v: pos, width: w)

proc draw*(trail: var Trail, color: Color, width: float32, z = 0f, blend = blendNormal, cap = false) =
  if cap and trail.points.len > 0:
    let 
      p = trail.points[^1]
      w = p.width * width / trail.points.len * (trail.points.len - 1) * 2f 
    
    if p.width > 0.001f:
      draw("hcircle".patch, p.v, size = vec2(w), rotation = -trail.lastAngle + 180f.rad, color = color, z = z, blend = blend)

  let size = width / trail.points.len
  var lastAngle = trail.lastAngle

  for i in 0..<trail.points.len:
    var p = trail.points[i]
    var p2: TrailPoint

    if i < trail.points.len - 1:
      p2 = trail.points[i + 1]

      if i == 0 and trail.points.len >= (trail.len - 1):
        p.v.lerp(p2.v, trail.counter)
        p.width.lerp(p2.width, trail.counter)
    else:
      p2 = initPoint(trail.lastPos, trail.lastWidth)
    
    let a2 = if p.v == p2.v: trail.lastAngle else: -p.v.angle(p2.v)
    let a1 = if i == 0: a2 else: trail.lastAngle

    if p.width <= 0.001f or p2.width <= 0.001f: continue

    let
      c = vec2(sin(a1), cos(a1)) * i * size * p.width
      n = vec2(sin(a2), cos(a2)) * (i+1f) * size * p2.width
    
    fillQuad(
      p.v - c,
      p.v + c,
      p2.v - n,
      p2.v + n,
      color = color,
      blend = blend,
      z = z
    )

    lastAngle = a2

proc shorten*(trail: var Trail) =
  trail.counter += fau.delta * trail.frequency
  let count = trail.counter.int
  trail.counter -= count

  if count > 0 and trail.points.len > 0:
    trail.points.delete(0..min(count - 1, trail.points.len - 1))

proc update*(trail: var Trail, pos: Vec2, scale = 1f) =
  trail.counter += fau.delta * trail.frequency
  let count = trail.counter.int
  trail.counter -= count

  if count > 0:
    let toRemove = trail.points.len + (count - 1 - trail.len)
    if toRemove > 0:
      trail.points.delete(0..min(toRemove - 1, trail.points.len - 1))
    
    if count == 1 or trail.lastAngle == -1f:
      trail.points.add initPoint(pos, scale)
    else:
      let 
        lastp = trail.lastPos
        lastw = trail.lastWidth
      for i in 0..<count:
        let f = (i.float32 + 1f) / count
        trail.points.add initPoint(lastp.lerp(pos, f), lastw.lerp(scale, f))
  
  trail.lastAngle = -pos.angle(trail.lastPos)
  trail.lastPos = pos
  trail.lastWidth = scale
