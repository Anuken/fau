# Simple texture packer algorithm.
# Taken from https://github.com/liquid600pgm/rapid/issues/17#issuecomment-593066196

type
  Node = object
    x, y, w: int16
  Packer = ref object
    w, h: int32
    nodes: seq[Node]

proc newPacker*(width, height: int32): Packer =
  result = Packer(w: width, h: height)
  result.nodes.add Node(w: width.int16)

proc rectFits(atlas: Packer, idx: int32, w,h: int16): int16 =
  if atlas.nodes[idx].x + w > atlas.w: return -1
  var # check if there is enough space at location i
    y = atlas.nodes[idx].y
    spaceLeft = w
    i = idx
  while spaceLeft > 0:
    if i == len(atlas.nodes): 
      return -1
    y = max(y, atlas.nodes[i].y)
    if y + h > atlas.h: 
      return -1
    spaceLeft -= atlas.nodes[i].w
    inc(i)
  return y # recta fits

proc addSkylineNode(atlas: Packer, idx: int32, x,y,w,h: int16) =
  atlas.nodes.insert(Node(x: x, y: y + h, w: w), idx)
  var i = idx+1 # New Iterator
  # delete skyline segments that fall under the shadow of the new segment
  while i < len(atlas.nodes):
    let # prev node and i-th node
      pnode = addr atlas.nodes[i-1]
      inode = addr atlas.nodes[i]
    if inode.x < pnode.x + pnode.w:
      let shrink =
        pnode.x - inode.x + pnode.w
      inode.x += shrink
      inode.w -= shrink
      if inode.w <= 0:
        atlas.nodes.delete(i)
        dec(i) # reverse i-th
      else: break
    else: break
    inc(i) # next node
  # merge same height skyline segments that are next to each other
  i = 0 # reset iterator
  while i < high(atlas.nodes):
    let # next node and i-th node
      nnode = addr atlas.nodes[i+1]
      inode = addr atlas.nodes[i]
    if inode.y == nnode.y:
      inode.w += nnode.w
      atlas.nodes.delete(i+1)
      dec(i) # Reverse i-th
    inc(i) # nextn ode

# Procedure that does the actual packing.
proc packInternal(atlas: Packer, width, height: int): tuple[x, y: int] =
  let 
    w = width.int16
    h = height.int16

  var # initial best fits
    bestIDX = -1'i32
    bestX = -1'i16
    bestY = -1'i16
  block: # find best fit
    var
      bestH = atlas.h
      bestW = atlas.w
      i: int32 = 0
    while i < len(atlas.nodes):
      let y = atlas.rectFits(i, w, h)
      if y != -1: # fits
        let node = addr atlas.nodes[i]
        if y + h < bestH or y + h == bestH and node.w < bestW:
          bestIDX = i
          bestW = node.w
          bestH = y + h
          bestX = node.x
          bestY = y
      inc(i) # next node
  if bestIDX != -1: # Can be packed
    addSkylineNode(atlas, bestIDX, bestX, bestY, w, h)
    # Return Packing Position
    result.x = bestX; result.y = bestY
  else: result.x = -1; result.y = -1 # not packed

# Packs a rectangle at a position. Returns the position, or -1 if packing failed.
# Applies a default padding of one pixel around the rectangle.
proc pack*(atlas: Packer, width, height: int, padding = 1): tuple[x, y: int] =
  result = packInternal(atlas, width + padding*2, height + padding*2)
  result.x += padding
  result.y += padding