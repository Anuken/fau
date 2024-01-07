## components for rendering effects

import ../../core, ../util/util, basic
import std/strutils
import pkg/polymorph

type
  EffectId* = distinct int
  EffectState* = object
    pos*: Vec2
    time*, lifetime*, rotation*, size*: float32
    color*: Color
    id*: int
  EffectProc* = proc(e: EffectState)

registerComponents(defaultComponentOptions):
  type
    Effect* = object
      ide*: EffectId
      rotation*, sizef*: float32
      color*: Color

## Defines several effects. Requires makeEffectsSystem() to be called somewhere to function properly.
## 
## Usage:
## 
## defineEffects:
##   circle:
##     fillCircle(e.x, e.y, 0.1)
## 
## Instantiating the effect:
## 
## effectCircle(x, y)
macro defineEffects*(body: untyped) =
  body.expectKind nnkStmtList

  result = newStmtList()
  
  result.add quote do:
    proc rendererNone*(e: EffectState) {.inject.} = discard

    onEcsBuilt:
      proc createEffect*(eid: EffectId, pos: Vec2, rotation: float32 = 0, color: Color = colorWhite, life: float32 = 0.2, size = 0f, parent = NoEntityRef) =
        if eid.int < 0: return

        let res = newEntityWith(Pos(vec: pos), Timed(lifetime: life), Effect(ide: eid, rotation: rotation, color: color, sizef: size))
        
        addParent(res, pos, parent)

  let brackets = newNimNode(nnkBracket)
  
  brackets.add quote do:
    rendererNone.EffectProc

  var curid = 1

  for child in body:
    child.expectKind nnkCall
    let 
      name = child[0].repr
      capped = name.capitalizeAscii
      effectBody = child.last
      procName = ident "renderer" & capped
      templName = ident "effect" & capped
      idName = ident "effectId" & capped
      id = newLit curid
    
    var
      lifeVal = newLit(1)
    
    inc curid

    for node in child[1..<(child.len-1)]:
      if node.kind == nnkExprEqExpr:
        let name = node[0].repr
        if name == "lifetime":
          lifeVal = node[1]
    
    result.add quote do:
      const `idName`* {.inject.}: EffectId = `id`.EffectId

      proc `procName`(e {.inject.}: EffectState) =
        `effectBody`
      
      onEcsBuilt:
        template `templName`*(pos: Vec2, rotation: float32 = 0, color: Color = colorWhite, life: float32 = `lifeVal`, size = 0f, parent = NoEntityRef) =
          createEffect(`id`.EffectId, pos, rotation, color, life, size, parent)
    
    brackets.add quote do:
      `procName`.EffectProc
  
  let count = newLit(1 + body.len)
  
  result.add quote do:
    const 
      allEffects* {.inject.}: array[`count`, EffectProc] = `brackets`
      effectNone* {.inject.} = -1.EffectId
      effectIdNone* {.inject.} = effectNone

## Creates the effect entity system for rendering.
template makeEffectsSystem*() =
  makeSystem("drawEffects", [Pos, Effect, Timed]):
    all:
      allEffects[effect.ide.int](EffectState(pos: item.pos.vec, time: timed.time, lifetime: timed.lifetime, color: effect.color, size: effect.sizef, rotation: effect.rotation, id: entity.entityId.int))