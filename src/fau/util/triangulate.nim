import ../fmath

proc areVerticesClockwise(vertices: openArray[Vec2]): bool =
  if vertices.len <= 1: return false

  var
    area = 0f
    p1 = vec2()
    p2 = vec2()
    i = 0
  
  while i < vertices.len - 1:
    p1 = vertices[i]
    p2 = vertices[i + 1]
    area += p1.x * p2.y - p2.x * p1.y

    i.inc
  
  p1 = vertices[^1]
  p2 = vertices[0]
  return area + p1.x * p2.y - p2.x * p1.y < 0f

proc computeSpannedAreaSign(p1, p2, p3: Vec2): int {.inline.} =
  return signi(p1.x * (p3.y - p2.y) + p2.x * (p1.y - p3.y) + p3.x * (p2.y - p1.y))

proc triangulate*(vertices: openArray[Vec2]): seq[uint16] =
  ## Ear-clipping triangulation implementation. Ported from libGDX.

  const
    concaveVertex = -1
    convexVertex = 1

  var indices = newSeqUninitialized[uint16](vertices.len)

  if areVerticesClockwise(vertices):
    for i in 0..<vertices.len:
      indices[i] = i.uint16
  else: #reversed
    for i in 0..<vertices.len:
      indices[i] = (vertices.len - 1 - i).uint16

  template prevIndex(index: int): int = (if index == 0: vertexTypes.len else: index) - 1
  template nextIndex(index: int): int = (index + 1) mod vertexTypes.len
  template classifyVertex(i: int): int = computeSpannedAreaSign(vertices[indices[i.prevIndex]], vertices[indices[i]], vertices[indices[i.nextIndex]])

  var vertexTypes = newSeqUninitialized[int](vertices.len)

  for i in 0..<vertices.len:
    vertexTypes[i] = classifyVertex(i)
  
  var triangles = newSeqOfCap[uint16](max(0, vertices.len - 2) * 3)
  
  #triangulate.

  var vertexCount = vertices.len

  proc isEarTip(vertices: openArray[Vec2], index: int): bool = 
    if vertexTypes[index] == concaveVertex: return false
    let
      prev = index.prevIndex
      next = index.nextIndex
      p1 = vertices[indices[prev]]
      p2 = vertices[indices[index]]
      p3 = vertices[indices[next]]
    
    var i = next.nextIndex
    while i != prev:
      if vertexTypes[i] != convexVertex:
        let v = vertices[indices[i]]

        if computeSpannedAreaSign(p3, p1, v) >= 0f and computeSpannedAreaSign(p1, p2, v) >= 0f and computeSpannedAreaSign(p2, p3, v) >= 0f:
          return false

      i = i.nextIndex
    
    return true

  proc findEarTip(vertices: openArray[Vec2]): int =
    for i in 0..<vertexCount:
      if isEarTip(vertices, i): return i
    
    for i in 0..<vertexCount:
      if vertexTypes[i] != concaveVertex: return i
    
    return 0

  while vertexCount > 3:
    let earTipIndex = findEarTip(vertices)

    #cutEarTip
    triangles.add indices[earTipIndex.prevIndex]
    triangles.add indices[earTipIndex]
    triangles.add indices[earTipIndex.nextIndex]

    indices.delete(earTipIndex)
    vertexTypes.delete(earTipIndex)
    vertexCount.dec

    let 
      prev = earTipIndex.prevIndex
      next = if earTipIndex == vertexCount: 0 else: earTipIndex

    vertexTypes[prev] = classifyVertex(prev)
    vertexTypes[next] = classifyVertex(next)
  
  if vertexCount == 3:
    triangles.add indices[0]
    triangles.add indices[1]
    triangles.add indices[2]

  return triangles