import ../fmath, sequtils

const maxInQuadrant = 5

type
  ## The position and dimensions of a bounding box (usually, a Rect)
  Bounds* = concept b
    b.x is float32
    b.y is float32
    b.w is float32
    b.h is float32

  ## An element that can provide a bounding box
  BoundsProvider* = concept q
    boundingBox(q) is Bounds

  ## An element that can be stored in a quadtree.
  Quadable* = concept q
    `==`(q, q) is bool
    q is Bounds | BoundsProvider

  ## You should know what a quadtree is.
  Quadtree*[E] = ref object
    bounds*: Rect
    leaf: bool
    elems*: seq[E]
    topLeft, botLeft, topRight, botRight: Quadtree[E]

## Constructs a new quadtree with the specified bounds.
proc newQuadtree*[E: Quadable](bounds: Rect): Quadtree[E] = Quadtree[E](bounds: bounds, leaf: true)

## Yields every child node of this non-leaf node.
iterator children*[E: Quadable](tree: Quadtree[E]): Quadtree[E] =
  if not tree.leaf:
    yield tree.topLeft
    yield tree.botLeft
    yield tree.topRight
    yield tree.botRight

## Removes all objects from the tree.
proc clear*[E: Quadable](tree: Quadtree[E]) =
  tree.elems.setLen(0)
  if not tree.leaf:
    for c in tree.children: c.clear()
  tree.leaf = true

## Returns bounding box of an element
template bounds(elem: Quadable): Rect =
  when type(elem) is Bounds: rect(elem.x, elem.y, elem.w, elem.h)
  else: rect(elem.boundingBox.x, elem.boundingBox.y, elem.boundingBox.w, elem.boundingBox.h)

proc fittingChild[E: Quadable](tree: Quadtree[E], rect: Rect): Quadtree[E] =
  let
    vertMid = tree.bounds.x + tree.bounds.w/2.0
    horMid = tree.bounds.y + tree.bounds.h/2.0
    topQuadrant = rect.y > horMid
    bottomQuadrant = rect.y < horMid and (rect.y + rect.h) < horMid
  
  if rect.x < vertMid and rect.x + rect.w < vertMid:
    if topQuadrant: return tree.topLeft
    elif bottomQuadrant: return tree.botLeft
  elif rect.x > vertMid:
    if(topQuadrant): return tree.topRight
    elif bottomQuadrant: return tree.botRight

  return nil

proc split[E: Quadable](tree: Quadtree[E]) =
  if not tree.leaf: return

  let 
    subW = tree.bounds.w / 2.0
    subH = tree.bounds.h / 2.0

  if tree.botLeft == nil:
    tree.botLeft = Quadtree[E](bounds: rect(tree.bounds.x, tree.bounds.y, subW, subH), leaf: true)
    tree.botRight = Quadtree[E](bounds: rect(tree.bounds.x + subW, tree.bounds.y, subW, subH), leaf: true)
    tree.topLeft = Quadtree[E](bounds: rect(tree.bounds.x, tree.bounds.y + subH, subW, subH), leaf: true)
    tree.topRight = Quadtree[E](bounds: rect(tree.bounds.x + subW, tree.bounds.y + subH, subW, subH), leaf: true)
  
  tree.leaf = false
  let ecopy = tree.elems

  for obj in ecopy:
    let child = tree.fittingChild(obj.bounds)
    if not child.isNil:
      child.insert obj
      tree.elems.del(tree.elems.find(obj))

## Inserts an object into the tree. Should only be done once.
proc insert*[E: Quadable](tree: Quadtree[E], obj: E) =
  let obounds = obj.bounds
  if not tree.bounds.overlaps(obounds):
    return

  if tree.leaf and tree.elems.len + 1 > maxInQuadrant: 
    tree.split()

  if tree.leaf:
    tree.elems.add obj
  else:
    let child = fittingChild(tree, obounds)
    if child != nil:
      child.insert obj
    else:
      tree.elems.add obj

## Removes an object from the tree.
proc remove*[E: Quadable](tree: Quadtree[E], obj: E) =
  if tree.leaf:
    let idx = tree.elems.find(obj)
    if idx != -1:
      tree.elems.del idx
  else:
    let obounds = obj.bounds
    let child = fittingChild(tree, obounds)

    if child != nil:
      child.remove(obj)
    else:
      let idx = tree.elems.find(obj)
      if idx != -1:
        #TODO unsplit here
        tree.elems.del idx

## Returns a list of all objects that intersect this rectangle. Uses the provided sequence for output.
proc intersect*[E: Quadable](tree: Quadtree[E], rect: Rect, dest: var seq[E]) =
  for child in tree.children:
    if child.bounds.overlaps(rect): child.intersect(rect, dest)
  
  for elem in tree.elems:
    if elem.bounds.overlaps(rect):
      dest.add elem

## Returns a list of all objects that intersect this rectangle. Allocates a new sequence.
proc intersect*[E: Quadable](tree: Quadtree[E], rect: Rect): seq[E] =
  var s = newSeq[E]()
  tree.intersect(rect, s)
  return s

proc count*[E: Quadable](tree: Quadtree[E]): int =
  result = tree.elems.len
  for child in tree.children:
    result += child.count