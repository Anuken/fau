import math, random

const perm = [151, 160, 137, 91, 90, 15,
131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23,
190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33,
88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166,
77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244,
102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196,
135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123,
5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42,
223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228,
251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107,
49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254,
138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180]

{.push checks: off.}

proc hash(seed, i: int32): int32 {.inline.} =
  #TODO this is broken, why do I have to mod it
  perm[(i + seed).euclMod 256].int32

proc grad(hash: int32, x: float): float =
  let h: int32 = hash and 0x0F
  var grad: float = 1.0 + (h and 7).float
  if (h and 8) != 0: grad = -grad

  return grad * x

proc grad(hash: int32, x: float, y: float): float =
  let h: int32 = hash and 0x3F
  let u: float = if h < 4: x else: y
  let v: float = if h < 4: y else: x
  return (if (h and 1) != 0: -u else: u) + (if (h and 2) != 0: -2.0 * v else: 2.0 * v)

proc grad(hash: int32, x: float, y: float, z: float): float =
  let h: int = hash and 15
  let u: float = if h < 8: x else: y
  let v: float = if h < 4: x else: (if h == 12 or h == 14: x else: z)
  return (if (h and 1) != 0: -u else: u) + (if (h and 2) != 0: -v else: v)

proc noise*(x: float, seed: int32 = 0): float =
  let i0: int32 = math.floor(x).int32
  let i1 = i0 + 1

  let x0 = x - i0.float
  let x1 = x0 - 1.0

  var t0 = 1.0 - x0 * x0

  t0 *= t0

  var n0 = t0 * t0 * grad(hash(seed, i0.int32), x0)

  var t1 = 1.0 - x1 * x1

  t1 *= t1

  var n1 = t1 * t1 * grad(hash(seed, i1.int32), x1)

  return 0.395 * (n0 + n1)

proc noise*(x: float, y: float, seed: int32 = 0): float =
  let f2 = 0.366025403
  let g2 = 0.211324865
  var
    n0 = 0.0
    n1 = 0.0
    n2 = 0.0

  let s = (x + y) * f2
  let xs = x + s
  let ys = y + s
  let i = math.floor(xs).int32
  let j = math.floor(ys).int32
  let t = (i + j).float * g2
  let xO = i.float - t
  let yO = j.float - t
  let x0 = x - xO
  let y0 = y - yO

  var
    i1 = 0
    j1 = 0

  if x0 > y0:
    i1 = 1
    j1 = 0
  else:
    i1 = 0
    j1 = 1
  
  let x1 = x0 - i1.float + g2
  let y1 = y0 - j1.float + g2

  let x2 = x0 - 1.0 + 2.0 * g2
  let y2 = y0 - 1.0 + 2.0 * g2

  let gi0 = hash(seed, i + hash(seed, j))
  let gi1 = hash(seed, i + i1.int32 + hash(seed, j + j1.int32))
  let gi2 = hash(seed, i + 1 + hash(seed, j + 1))


  var t0 = 0.5 - x0 * x0 - y0 * y0
  if t0 < 0.0:
    n0 = 0.0
  else:
    t0 *= t0
    n0 = t0 * t0 * grad(gi0, x0, y0)
    
  var t1 = 0.5 - x1 * x1 - y1 * y1
  if t1 < 0.0:
    n1 = 0.0
  else:
    t1 *= t1
    n1 = t1 * t1 * grad(gi1, x1, y1)
    
  var t2 = 0.5 - x2 * x2 - y2 * y2
  if t2 < 0.0:
    n2 = 0.0
  else:
    t2 *= t2
    n2 = t2 * t2 * grad(gi2, x2, y2)

  return 45.23065 * (n0 + n1 + n2)

proc noise*(x: float, y: float, z: float, seed: int32 = 0): float =
  var
    n0 = 0.0
    n1 = 0.0
    n2 = 0.0
    n3 = 0.0
  let
    f3 = 1.0 / 3.0
    g3 = 1.0 / 6.0

  var s = (x + y + z) * f3
  var i = math.floor(x + s).int
  var j = math.floor(y + s).int
  var k = math.floor(z + s).int
  var t = (i + j + k).float * g3
  var xO = i.float - t
  var yO = j.float - t
  var zO = k.float - t
  var x0 = x - xO
  var y0 = y - yO
  var z0 = z - zO

  var i1, j1, k1 = 0
  var i2, j2, k2 = 0
  
  if x0 >= y0:
    if y0 >= z0:
      i1 = 1
      j1 = 0
      k1 = 0
      i2 = 1
      j2 = 1
      k2 = 0
    else:
      if x0 >= z0:
        i1 = 1
        j1 = 0
        k1 = 0
        i2 = 1
        j2 = 0
        k2 = 1
      else:
        i1 = 0
        j1 = 0
        k1 = 1
        i2 = 1
        j2 = 0
        k2 = 1
  else:
    if y0 < z0:
      i1 = 0
      j1 = 0
      k1 = 1
      i2 = 0
      j2 = 1
      k2 = 1
    else:
      if x0 < z0:
        i1 = 0
        j1 = 1
        k1 = 0
        i2 = 0
        j2 = 1
        k2 = 1
      else:
        i1 = 0
        j1 = 1
        k1 = 0
        i2 = 1
        j2 = 1
        k2 = 0

  var x1 = x0 - i1.float + g3
  var y1 = y0 - j1.float + g3
  var z1 = z0 - k1.float + g3
  var x2 = x0 - i2.float + 2.0 * g3
  var y2 = y0 - j2.float + 2.0 * g3
  var z2 = z0 - k2.float + 2.0 * g3
  var x3 = x0 - 1.0 + 3.0 * g3
  var y3 = y0 - 1.0 + 3.0 * g3
  var z3 = z0 - 1.0 + 3.0 * g3

  var gi0 = hash(seed, i.int32 + hash(seed, j.int32 + hash(seed, k.int32)))
  var gi1 = hash(seed, i.int32 + i1.int32 + hash(seed, j.int32 + j1.int32 + hash(seed, k.int32 + k1.int32)))
  var gi2 = hash(seed, i.int32 + i2.int32 + hash(seed, j.int32 + j2.int32 + hash(seed, k.int32 + k2.int32)))
  var gi3 = hash(seed, i.int32 + 1 + hash(seed, j.int32 + 1 + hash(seed, k.int32 + 1)))

  var t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0
  if t0 < 0:
    n0 = 0.0
  else:
    t0 *= t0
    n0 = t0 * t0 * grad(gi0, x0, y0, z0)

  var t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1
  if t1 < 0:
    n1 = 0.0
  else:
    t1 *= t1
    n1 = t1 * t1 * grad(gi1, x1, y1, z1) 
  
  var t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2
  if t2 < 0:
    n2 = 0.0
  else:
    t2 *= t2
    n2 = t2 * t2 * grad(gi2, x2, y2, z2) 

  
  var t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3
  if t3 < 0:
    n3 = 0.0
  else:
    t3 *= t3
    n3 = t3 * t3 * grad(gi3, x3, y3, z3)

  return 32.0 * (n0 + n1 + n2 + n3)

proc fractal*(x: float, octaves: int, freq = 1.0, amp = 1.0, persistence = 0.5, lac = 2.0): float =
  var output = 0.0
  var denom = 0.0
  var frequency = freq
  var amplitude = amp

  for i in 0..<octaves:
    output += amplitude * noise(x * frequency)
    denom += amplitude

    frequency *= lac
    amplitude *= persistence
  
  return output / denom

proc fractal*(x: float, y: float, octaves: int, freq = 1.0, amp = 1.0, persistence = 0.5, lac = 2.0): float =
  var output = 0.0
  var denom = 0.0
  var frequency = freq
  var amplitude = amp

  for i in 0..<octaves:
    output += amplitude * noise(x * frequency, y * frequency)
    denom += amplitude

    frequency *= lac
    amplitude *= persistence
  
  return output / denom

proc fractal*(x: float, y: float, z: float, octaves: int, freq = 1.0, amp = 1.0, persistence = 0.5, lac = 2.0): float =
  var output = 0.0
  var denom = 0.0
  var frequency = freq
  var amplitude = amp

  for i in 0..<octaves:
    output += amplitude * noise(x * frequency, y * frequency, z * frequency)
    denom += amplitude

    frequency *= lac
    amplitude *= persistence
  
  return output / denom

{.pop.}