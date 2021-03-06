## components for rendering effects

import ../ecs, strutils, basic

exportAll:
  type
    EffectId = distinct int
    EffectState = object
      x, y, time, lifetime, rotation: float32
      color: Color
      id: int
    EffectProc = proc(e: EffectState)

  registerComponents(defaultComponentOptions):
    type
      Effect = object
        id: EffectId
        rotation: float32
        color: Color

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
      
      template `templName`*(xp, yp: float32, rot: float32 = 0, col: Color = colorWhite, life: float32 = `lifeVal`) =
        discard newEntityWith(Pos(x: xp, y: yp), Timed(lifetime: life), Effect(id: `id`.EffectId, rotation: rot, color: col))
    
    brackets.add quote do:
      `procName`.EffectProc
  
  let count = newLit(1 + body.len)
  
  result.add quote do:
    const allEffects* {.inject.}: array[`count`, EffectProc] = `brackets`

    template createEffect*(eid: EffectId, xp, yp: float32, rot: float32 = 0, col: Color = colorWhite, life: float32 = 0.2) =
      discard newEntityWith(Pos(x: xp, y: yp), Timed(lifetime: life), Effect(id: eid, rotation: rot, color: col))

## Creates the effect entity system for rendering.
template makeEffectsSystem*() =
  sys("drawEffects", [Pos, Effect, Timed]):
    all:
      allEffects[item.effect.id.int](EffectState(x: item.pos.x, y: item.pos.y, time: item.timed.time, lifetime: item.timed.lifetime, color: item.effect.color, rotation: item.effect.rotation, id: item.entity.instance.int))