## basic components, such as position

import ../../core, strutils
import pkg/polymorph

register(defaultComponentOptions):
  type
    Pos* = object
      vec*: Vec2
    Timed* = object
      time*, lifetime*: float32
    Parent* = object
      parent*: EntityRef
      offset*: Vec2
      deleteOnDeath*: bool

template makeEntity*(components: varargs[untyped]) = discard newEntityWith(components)

macro whenComp*(entity: EntityRef, t: typedesc, body: untyped) =
  ## Runs the body with the specified lowerCase type when this entity has this component
  let varName = t.repr.toLowerAscii.ident
  result = quote do:
    if `entity`.alive:
      let `varName` {.inject.} = `entity`.fetch `t`
      if `varName`.valid:
        `body`

onEcsBuilt:
  template x*(pos: PosInstance): float32 = pos.vec.x
  template y*(pos: PosInstance): float32 = pos.vec.y

  template `x=`*(pos: PosInstance, val: float32): float32 = pos.vec.x = val
  template `y=`*(pos: PosInstance, val: float32): float32 = pos.vec.y = val

  converter toVec*(pos: PosInstance): Vec2 {.inline} = pos.vec

  proc addParent*(entity: EntityRef, pos: Vec2, parent: EntityRef, deleteOnDeath = false) =
    if parent != NoEntityRef and parent.alive:
      let ppos = parent.fetch(Pos)
      if ppos.valid:
        entity.add Parent(parent: parent, offset: pos - ppos.vec, deleteOnDeath: deleteOnDeath)

template makeTimedSystem*() =
  makeSystem("timed", [Timed]):
    all:
      item.timed.time += fau.delta
      if item.timed.time >= item.timed.lifetime:
        item.timed.time = item.timed.lifetime
        item.entity.delete()

template makeParentSystem*() =
  makeSystem("parent", [Parent, Pos]):
    all:
      #TODO: delete component if not valid?
      if item.parent.parent.alive:
        let opos = item.parent.parent.fetch(Pos)
        if opos.valid:
          item.pos.vec = opos.vec + item.parent.offset
      elif item.parent.deleteOnDeath:
        sys.deleteList.add entity