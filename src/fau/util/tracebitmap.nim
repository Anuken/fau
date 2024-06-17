import std/algorithm, ../fmath, ../texture, sets, sequtils, tables, misc

#TODO this module is a mess!

proc convexHull(input: seq[Vec2]): seq[Vec2] =
  ## Code taken from treeform/bumpy

  var points = input

  points.sort do(a, b: Vec2) -> int:
    let xc = cmp(a.x, b.x)
    return if xc != 0: xc else: cmp(a.y, b.y)

  var upperHull: seq[Vec2]
  for i in 0 ..< points.len:
    let p = points[i]
    while upperHull.len >= 2:
      let q = upperHull[upperHull.len - 1]
      let r = upperHull[upperHull.len - 2]
      if (q.x - r.x) * (p.y - r.y) >= (q.y - r.y) * (p.x - r.x):
        discard upperHull.pop()
      else:
        break
    upperHull.add(p)
  discard upperHull.pop()

  # Deal with the lower half.
  var lowerHull: seq[Vec2]
  for i in countDown(points.len - 1, 0):
    let p = points[i]
    while lowerHull.len >= 2:
      let q = lowerHull[lowerHull.len - 1]
      let r = lowerHull[lowerHull.len - 2]
      if (q.x - r.x) * (p.y - r.y) >= (q.y - r.y) * (p.x - r.x):
        discard lowerHull.pop()
      else:
        break
    lowerHull.add(p)
  discard lowerHull.pop()

  # See if lower or upper half needs merging.
  if upperHull.len == 1 and
    lowerHull.len == 1 and
    upperHull[0].x == lowerHull[0].x and
    upperHull[0].y == lowerHull[0].y:
    return upperHull
  else:
    return upperHull & lowerHull

proc traceBitmapConvex*(img: Img): seq[Vec2] =
  ## Simple implementation of image tracing that simply takes the convex hull of all the edge points.

  template solid(x, y: int): bool = x < img.width and y < img.height and x >= 0 and y >= 0 and img.data[(x + (img.height - 1 - y) * img.width) * 4 + 3] > 10'u8

  var 
    taken: HashSet[Vec2]
    points: seq[Vec2]

  for y in 0..<img.height:
    for x in 0..<img.width:
      if solid(x, y):
        for i, dir in d4i:
          if not solid(dir.x + x, dir.y + y):
            let offset = d4i[(i + 1) mod 4]
            #I'm sure there's a far more efficient way to prevent duplicates on edges, but this is good enough for now.
            taken.incl(vec2(x, y) + (dir + offset)/2f)
            taken.incl(vec2(x, y) + (dir - offset)/2f)
  
  return convexHull(taken.toSeq)

proc traceBitmapConcave*(img: Img, spacing = 10): seq[Vec2] =
  ## This implementation sucks, the runtime complexity is probably awful. But it works.

  template solid(x, y: int): bool = x < img.width and y < img.height and x >= 0 and y >= 0 and (img.data[(x + (img.height - 1 - y) * img.width) * 4 + 3] > 10'u8 or holes[x + y * img.width])

  var 
    taken: HashSet[Vec2]
    all: seq[Vec2]
    lines: Table[Vec2, seq[Vec2]]
    first: Vec2
    holes: seq[bool] = newSeq[bool](img.width * img.height)
  
  template fillHole(x, y: int) = holes[x + y * img.width] = true

  #fix holes, they break the algorithm
  for y in 0..<img.height-1:
    for x in 0..<img.width-1:
      if not solid(x, y) and not solid(x + 1, y + 1) and solid(x + 1, y) and solid(x, y + 1):
        fillHole(x, y)
        fillHole(x + 1, y + 1)
      
      elif solid(x, y) and solid(x + 1, y + 1) and not solid(x + 1, y) and not solid(x, y + 1):
        fillHole(x + 1, y)
        fillHole(x, y + 1)

  #first, get every line segment that defines a pixel border, and slap it into a table.
  for y in 0..<img.height:
    for x in 0..<img.width:
      if solid(x, y):
        for i, dir in d4i:
          if not solid(dir.x + x, dir.y + y):
            let 
              offset = d4i[(i + 1) mod 4]
              line = (vec2(x, y) + (dir + offset)/2f, vec2(x, y) + (dir - offset)/2f)

            first = line[0]

            taken.incl line[0]
            taken.incl line[1]

            if not lines.contains(line[0]): lines[line[0]] = newSeqOfCap[Vec2](2)
            if not lines.contains(line[1]): lines[line[1]] = newSeqOfCap[Vec2](2)

            lines[line[0]].add line[1]
            lines[line[1]].add line[0]
  
  var
    passed: HashSet[Vec2]
    current = first
    start = current
    step = 0

  #then, start with a random point, find the first line that contains that point that hasn't been visited, move on to the other point on the line, and repeat
  while true:
    let choices = lines[current]
    passed.incl current

    step.inc
    if step mod spacing == 0:
      result.add current

    let next = choices.findIt(not passed.contains(it))

    if next == -1: break

    lines.del(current)
    current = choices[next]

    if current == start:
      break
            