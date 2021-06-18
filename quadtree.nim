import fmath

const maxInQuadrant = 5

type
  ## An element that can be stored in a quadtree.
  Quadable* = concept q
    `==`(q, q) is bool
  
  PopulationState = enum
    psNone
    psUnder
    psOver

  ## You should know what a quadtree is.
  # TODO: current implementation heavily relies on arc and 
  # actually creates reference cycles that have to be 
  # cut manually. The quadtree can be implemented differently 
  # though, you can store all nodes in seq and use indexes as 
  # references which is arguably faster but also more 
  # complex and easy to mess up. 
  Quadtree*[E] = ref object
    bounds*: Rect
    leaf, closed: bool
    elems*: seq[E]
    topLeft, botLeft, topRight, botRight, parent: Quadtree[E]

template remove[T](s: var seq[T], value: T): bool =
  block:
    let id = s.find(value)
    if id == -1:
      false
    else:
      s.del(id)
      true

## Constructs a new quadtree with the specified bounds.
proc newQuadtree*[E: Quadable](bounds: Rect): Quadtree[E] = Quadtree[E](bounds: bounds, leaf: true)

## Yields every child node as long as the tree is not a leaf.
iterator children*[E: Quadable](tree: Quadtree[E]): Quadtree[E] {.inline.} =
  if not tree.leaf:
    yield tree.topLeft
    yield tree.botLeft
    yield tree.topRight
    yield tree.botRight

## Removes all objects from the tree.
proc clear*[E: Quadable](tree: Quadtree[E]) =
  tree.elems.setLen(0)
  for c in tree.children: c.clear()
  tree.leaf = true

## closes the branch for passive removal
proc close*[E: Quadable](tree: Quadtree[E]) =
  tree.closed = true
  for c in tree.children: c.close()

## closes the branch for passive removal
proc population*[E: Quadable](tree: Quadtree[E], count = 0): PopulationState =
  let count = count + tree.elems.len
  if count > maxInQuadrant:
    return psOver
  for c in tree.children:
    result = c.population(count)
    if result == psOver:
      return psOver

template fittingChild[E: Quadable](tree: Quadtree[E], rect: Rect): Quadtree[E] =
  let
    vertMid = tree.bounds.x + tree.bounds.w * 0.5
    horMid = tree.bounds.y + tree.bounds.h * 0.5
    topQuadrant = rect.y > horMid
    bottomQuadrant = rect.top < horMid
  
  var result: Quadtree[E] 
  
  if rect.right < vertMid:
    if topQuadrant: result = tree.topLeft
    elif bottomQuadrant: result = tree.botLeft
  elif rect.x > vertMid:
    if topQuadrant: result = tree.topRight
    elif bottomQuadrant: result = tree.botRight

  result

  # As long as entity does not intersect inner cross of 
  # the node, it fits into the smaller quadrant. This method 
  # is pretty hot so we need it inlined.

proc split[E: Quadable](tree: Quadtree[E]) =
  if not tree.leaf: return

  let 
    subW = tree.bounds.w / 2.0
    subH = tree.bounds.h / 2.0

  template initNode(x, y: float32): Quadtree[E] =
    Quadtree[E](bounds: rect(x, y, subW, subH), leaf: true, parent: tree)

  if tree.botLeft == nil:
    tree.botLeft = initNode(tree.bounds.x, tree.bounds.y)
    tree.botRight = initNode(tree.bounds.x + subW, tree.bounds.y)
    tree.topLeft = initNode(tree.bounds.x, tree.bounds.y + subH)
    tree.topRight = initNode(tree.bounds.x + subW, tree.bounds.y + subH)
  else:
    # as quadtree rarely splits it is better to ensure leafs now 
    # instead recursive call when closing
    for c in tree.children:
      c.closed = false
      c.leaf = true
  
  tree.leaf = false
  tree.closed = false
  
  # on reinserting, objects will be moved on update as we are not storing data about
  # objects anymore

## Inserts an object into the tree. Should only be done once. Object is then removed and updated by
## returned node so store it for later. Group is used to distinguish the entity and assign it to he 
## subregion for later querying.
proc insert*[E: Quadable](tree: Quadtree[E], bounds: Rect, obj: E, updateCall: static[bool] = false): Quadtree[E] =
  result = tree
  while true:
    let next = result.fittingChild(bounds)
    if next.isNil:
      when updateCall: 
        if result != tree:
          discard tree.elems.remove(obj)
          result.elems.add(obj)
          break
        return
      else:
        result.elems.add(obj)
        break
    result = next

  if result.leaf and result.elems.len > maxInQuadrant: result.split()

## Removes an object from the tree. Should be called on node provided by insert method.
proc remove*[E: Quadable](tree: Quadtree[E], obj: E): bool =
  result = tree.elems.remove(obj)
  let population = tree.population
  case population:
  of psNone:
    tree.leaf = true
  of psUnder:
    tree.close()
  of psOver:
    discard

## Updates the object. Returned tree should be stored for another update.
proc update*[E: Quadable](tree: Quadtree[E], bounds: Rect, obj: E): Quadtree[E] =
  result = tree
  # go up
  while result.closed or not bounds.fits(result.bounds):
    result = result.parent
  
  var lower: bool
  # go down
  if result == tree and not tree.leaf:
    lower = true
    result = tree.insert(bounds, obj, true)

  # cleanup
  if result != tree and not lower:
    discard tree.remove(obj)
    result = result.insert(bounds, obj)


## Returns a list of all objects that intersect this rectangle. Uses the provided sequence for output.
proc intersect*[E: Quadable](tree: Quadtree[E], rect: Rect, dest: var seq[E]) =
  for child in tree.children:
    if child.bounds.overlaps(rect): child.intersect(rect, dest)
  
  dest.add(tree.elems)

## Returns a list of all objects that intersect this rectangle. Allocates a new sequence.
proc intersect*[E: Quadable](tree: Quadtree[E], rect: Rect): seq[E] =
  var s = newSeq[E]()
  tree.intersect(rect, s)
  return s

## has to be called to drop the tree because of reference cycles
proc destroy*[E: Quadable](tree: Quadtree[E]) =
  for c in tree.children:
    destroy(c)
  tree.parent = nil
  # just in case
  tree.topLeft = nil
  tree.botLeft = nil
  tree.topRight = nil
  tree.botRight = nil

when isMainModule:
  import strutils
  proc visualize[E: Quadable](tree: Quadtree[E], tabs = 0) =
    echo "  ".repeat(tabs), tree.elems
    for c in tree.children:
      c.visualize(tabs + 1)

  let q = newQuadtree[int](rect(0, 0, 1000, 1000))
  
  var addresses: seq[Quadtree[int]]

  for i in 0..100:
    addresses.add q.insert(rect(1, 1, 0, 0), i)
  
  q.visualize() # nodes are populated

  for i in countdown(100, 0):
    addresses[i] = addresses[i].update(rect(999, 999, 0, 0), i)
  
  q.visualize() # all objects moved

  for i in countdown(100, 0):
    addresses[i] = addresses[i].update(rect(999, 1, 0, 0), i)
  
  q.visualize() # There should be lot of empty unclosed nodes because of order in witch
  # objects were removed. This is a perfect scenario though. The closing rules are not so
  # strict to prioritize performance. 

  for i, a in addresses:
    doAssert a.remove(i)
  
  q.visualize() # tree is empty
