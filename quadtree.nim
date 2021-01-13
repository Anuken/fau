import fmath, sequtils

const maxInQuadrant = 5

type
  Bounds* = concept b
    ## The position and dimensions of a bounding box
    b.x is float32
    b.y is float32
    b.w is float32
    b.h is float32

  BoundsProvider* = concept q
    ## An element that can provide a bounding box
    boundingBox(q) is Bounds

  Quadable* = concept q
    ## An element that can be stored in a quadtree. It can take multiple
    ## forms, depending on the level of control desired
    `==`(q, q) is bool
    q is Bounds | BoundsProvider

  Quadtree*[E] = ref object
    bounds*: Rect
    leaf: bool
    elems*: seq[E]
    topLeft, botLeft, topRight, botRight: Quadtree[E]

proc newQuadtree*[E: Quadable](bounds: Rect): Quadtree[E] = Quadtree[E](bounds: bounds, leaf: true)

iterator items*[E: Quadable](tree: Quadtree[E]): E =
  for item in tree.elems:
    yield item

iterator children*[E: Quadable](tree: Quadtree[E]): Quadtree[E] =
  if not tree.leaf:
    yield tree.topLeft
    yield tree.botLeft
    yield tree.topRight
    yield tree.botRight

proc clear*[E: Quadable](tree: Quadtree[E]) =
  tree.elems.setLen(0)
  if not tree.leaf:
    for c in tree.children: c.clear()
  tree.leaf = true

template bounds(elem: Quadable): Rect =
  ## Returns the bounding box for an element
  when type(elem) is Bounds: rect(elem.x, elem.y, elem.w, elem.h)
  else: rect(elem.boundingBox.x, elem.boundingBox.y, elem.boundingBox.w, elem.boundingBox.h)

proc fittingChild[E: Quadable](tree: Quadtree[E], rect: Rect): Quadtree[E] =
  let
    vertMid = tree.bounds.x + tree.bounds.w/2.0
    horMid = tree.bounds.y + tree.bounds.h/2.0
    topQuadrant = rect.y > horMid
    bottomQuadrant = rect.y < horMid and (rect.y + rect.h) < horMid
  
  #Object can completely fit within the left quadrants
  if rect.x < vertMid and rect.x + rect.w < vertMid:
    if topQuadrant: return tree.topLeft
    elif bottomQuadrant: return tree.botLeft
  elif rect.x > vertMid: #Object can completely fit within the right quadrants
    if(topQuadrant): return tree.topRight
    elif bottomQuadrant: return tree.botRight

  #Else, object needs to be in parent cause it can't fit completely in a quadrant
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

proc insert*[E: Quadable](tree: Quadtree[E], obj: E) =
  let obounds = obj.bounds
  if not tree.bounds.overlaps(obounds):
    return

  if tree.leaf and tree.elems.len + 1 > maxInQuadrant: tree.split()

  if tree.leaf:
    tree.elems.add obj
  else:
    let child = fittingChild(tree, obounds)
    if child != nil:
      child.insert obj
    else:
      tree.elems.add obj

proc intersect*[E: Quadable](tree: Quadtree[E], rect: Rect): seq[E] =
  var result = newSeq[E]
  intersect(result)
  return result

proc intersect*[E: Quadable](tree: Quadtree[E], rect: Rect, dest: var seq[E]) =
  if not tree.leaf:
    for child in tree.children:
      if child.bounds.overlaps(rect): child.intersect(rect, dest)
  
  for elem in tree.elems:
    if elem.bounds.overlaps(rect):
      dest.add elem
    