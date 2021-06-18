import fmath

const maxInQuadrant = 5

type
  Group = concept g
    `==`(g, g) is bool

  ## An element that can be stored in a quadtree.
  Quadable* = concept q
    `==`(q, q) is bool
  
  ## reduces junk id collection
  QuadStorage[E, G] = object
    len, count: int 
    # len allows reusing of old groups
    # count avoids looping trough elements to count them
    groups: seq[tuple[group: G, elems: seq[E]]]
  
  PopulationState = enum
    psNone
    psUnder
    psOver

  ## You should know what a quadtree is.
  # TODO: current implementation heavily relies on arc and 
  # actually creates a reference cycles that has to be 
  # cut manually. The quadtree can be implemented differently 
  # though, you can store all nodes in seq and use indexes as 
  # references which is arguably faster but also more 
  # complex and easy to fuck up. 
  Quadtree*[E, G] = ref object
    bounds*: Rect
    leaf, closed: bool
    elems*: QuadStorage[E, G]
    topLeft, botLeft, topRight, botRight, parent: Quadtree[E, G]

template insert*[E: Quadable, G: Group](q: var QuadStorage, elem: E, aGroup: G) =
  block:
    var unfinished = true
    for i in 0..<q.len:
      if q.groups[i].group == aGroup:
        q.groups[i].elems.add(elem)
        unfinished = false
        break
    
    if unfinished:
      if q.groups.len == q.len:
        q.groups.add((aGroup, @[elem]))
      else:
        q.groups[q.len].group = aGroup
        q.groups[q.len].elems.add(elem)
      q.len.inc()
    q.count.inc()
    
template remove*[E: Quadable, G: Group](q: var QuadStorage, elem: E, aGroup: G): bool =
  block:
    var removed: bool
    for i in 0..<q.len:
      let g = q.groups[i].addr
      if g.group == aGroup:
        if g.elems.len == 1:
          g.elems.setLen(0)
          swap(q.groups[i], q.groups[q.groups.high])
          q.len.dec()
          removed = true
          break
        else:
          let i = g.elems.find(elem)
          if i != -1:
            g.elems.del(i)
            removed = true
            break
    if removed:
      q.count.dec()
    removed

# this is why it is worth it, in cases of big groups of friendly units will not have to loop over
# them selfs when looking for enemies. Players tent to spam units which by it self slows down the game.
template query*[E: Quadable, G: Group](q: var QuadStorage, buff: var seq[E], aGroup: G, including: static[bool]) =
  when including:
    for g in q.groups:
      if g.group == aGroup:
        buff.add(g.elems)
        break
  else:
    for g in q.groups:
      if g.group != aGroup:
        buff.add(g.elems)

## Constructs a new quadtree with the specified bounds.
proc newQuadtree*[E: Quadable, G: Group](bounds: Rect): Quadtree[E, G] = Quadtree[E, G](bounds: bounds, leaf: true)

## Yields every child node as lon as tree is not leaf.
iterator children*[E: Quadable, G: Group](tree: Quadtree[E, G]): Quadtree[E, G] {.inline.} =
  if not tree.leaf:
    yield tree.topLeft
    yield tree.botLeft
    yield tree.topRight
    yield tree.botRight

## Removes all objects from the tree.
proc clear*[E: Quadable, G: Group](tree: Quadtree[E, G]) =
  tree.elems.setLen(0)
  for c in tree.children: c.clear()
  tree.leaf = true

## closes the branch for passive removal
proc close*[E: Quadable, G: Group](tree: Quadtree[E, G]) =
  tree.closed = true
  for c in tree.children: c.close()

## closes the branch for passive removal
proc population*[E: Quadable, G: Group](tree: Quadtree[E, G], count = 0): PopulationState =
  let count = count + tree.elems.count
  if count > maxInQuadrant:
    return psOver
  for c in tree.children:
    result = c.population(count)
    if result == psOver:
      return psOver

template fittingChild[E: Quadable, G: Group](tree: Quadtree[E, G], rect: Rect): Quadtree[E, G] =
  let
    vertMid = tree.bounds.x + tree.bounds.w * 0.5
    horMid = tree.bounds.y + tree.bounds.h * 0.5
    topQuadrant = rect.y > horMid
    bottomQuadrant = rect.top < horMid
  
  var result: Quadtree[E, G] 
  
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

proc split[E: Quadable, G: Group](tree: Quadtree[E, G]) =
  if not tree.leaf: return

  let 
    subW = tree.bounds.w / 2.0
    subH = tree.bounds.h / 2.0

  template initNode(x, y: float32): Quadtree[E, G] =
    Quadtree[E, G](bounds: rect(x, y, subW, subH), leaf: true, parent: tree)

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
## returned node so store it for later.
proc insert*[E: Quadable, G: Group](tree: Quadtree[E, G], bounds: Rect, obj: E, group: G, updateCall: static[bool] = false): Quadtree[E, G] =
  result = tree
  while true:
    let next = result.fittingChild(bounds)
    if next.isNil:
      when updateCall: 
        if result != tree:
          discard tree.elems.remove(obj, group)
          result.elems.insert(obj, group)
          break
        return
      else:
        result.elems.insert(obj, group)
        break
    result = next

  if result.leaf and result.elems.count > maxInQuadrant: result.split()

## Removes an object from the tree. Should be called on node provided by insert method.
proc remove*[E: Quadable, G: Group](tree: Quadtree[E, G], obj: E, group: G): bool =
  result = tree.elems.remove(obj, group)
  let population = tree.population
  case population:
  of psNone:
    tree.leaf = true
  of psUnder:
    tree.close()
  of psOver:
    discard

## Updates the object. Returned tree should be stored for another update.
proc update*[E: Quadable, G: Group](tree: Quadtree[E, G], bounds: Rect, obj: E, group: G): Quadtree[E, G] =
  result = tree
  # go up
  while result.closed or not bounds.fits(result.bounds):
    result = result.parent
  
  var lower: bool
  # go down
  if result == tree and not tree.leaf:
    lower = true
    result = tree.insert(bounds, obj, group, true)

  # cleanup
  if result != tree and not lower:
    discard tree.remove(obj, group)
    result = result.insert(bounds, obj, group)


## Returns a list of all objects that intersect this rectangle. Uses the provided sequence for output.
proc intersect*[E: Quadable, G: Group](tree: Quadtree[E, G], rect: Rect, dest: var seq[E], group = -1, including: static[bool] = false) =
  for child in tree.children:
    if child.bounds.overlaps(rect): child.intersect(rect, dest, group, including)
  
  tree.elems.query(dest, group, including)

## Returns a list of all objects that intersect this rectangle. Allocates a new sequence.
proc intersect*[E: Quadable, G: Group](tree: Quadtree[E, G], rect: Rect, group = -1, including: static[bool] = false): seq[E] =
  var s = newSeq[E]()
  tree.intersect(rect, s, group, including)
  return s

## has to be called to drop the tree because of reference cycles
proc destroy*[E: Quadable, G: Group](tree: Quadtree[E, G]) =
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
  proc visualize[E: Quadable, G: Group](tree: Quadtree[E, G], tabs = 0) =
    var dest: seq[E]
    tree.elems.query(dest, -1, false)
    echo "  ".repeat(tabs), dest
    for c in tree.children:
      c.visualize(tabs + 1)

  let q = newQuadtree[int, int](rect(0, 0, 1000, 1000))
  
  var addresses: seq[Quadtree[int, int]]

  for i in 0..100:
    addresses.add q.insert(rect(1, 1, 0, 0), i, 0)
  
  q.visualize() # nodes are populated

  for i in countdown(100, 0):
    addresses[i] = addresses[i].update(rect(999, 999, 0, 0), i, 0)
  
  q.visualize() # all objects moved

  for i in countdown(100, 0):
    addresses[i] = addresses[i].update(rect(999, 1, 0, 0), i, 0)
  
  q.visualize() # There should be lot of empty unclosed nodes because of order in witch
  # objects were removed. This is a perfect scenario though. The closing rules are not so
  # strict to prioritize performance. 

  for i, a in addresses:
    doAssert a.remove(i, 0)
  
  q.visualize() # tree is empty
