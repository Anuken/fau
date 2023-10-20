import macros, tables, strutils

# Utility macros, templates & sugar.

var eventHandlers* {.compileTime} = newTable[string, seq[NimNode]]()

template findIt*[T](list: seq[T], body: untyped): int =
  var result = -1
  for i, it {.inject.} in list:
    if body:
      result = i
      break
  
  result

template incTimer*(value: untyped, increment: float32, body: untyped): untyped =
  `value` += `increment`
  if `value` >= 1f:
    `value` = 0f
    `body`

template findMin*[T](list: seq[T], op: untyped): untyped =
  var minValue = float32.high
  var result: T
  for it {.inject.} in list:
    let newMin = op
    if newMin < minValue:
      minValue = newMin
      result = it
  result

template findMin*[T](list: seq[T], op: untyped, predicate: untyped): untyped =
  var minValue = float32.high
  var result: T
  for it {.inject.} in list:
    if predicate:
      let newMin = op
      if newMin < minValue:
        minValue = newMin
        result = it
  result

## copies an array into a seq, element by element.
macro minsert*(dest: untyped, index: int, data: untyped): untyped =
  result = newStmtList()
  
  if data.kind == nnkBracket:
    for i in 0..<data.len:
      result.add newAssignment(newNimNode(nnkBracketExpr).add(dest).add(infix(index, "+", newIntLitNode(i))), data[i])
  else:
    error("Insertion data must be array!", data)

macro loadProc*(varType: typedesc, name: untyped, body: untyped) =
  result = newStmtList()
  result.add(newNimNode(nnkVarSection))
  result[0].add(newNimNode(nnkIdentDefs))

  for varName in body:
    result[0][0].add(postfix(varName[0], "*"))

  result[0][0].add(ident($varType))
  result[0][0].add(newEmptyNode())

  result.add quote do:
    proc `name`*() =
      `body`

## exports all types/variables in the macro body
macro exportAll*(body: untyped) =
  proc traverse(parent: NimNode) =
    if parent.kind == nnkTypeDef:
      if parent[0].kind == nnkIdent:
        parent[0] = postfix(parent[0], "*")
    
    if parent.kind in [nnkProcDef, nnkTemplateDef, nnkMacroDef]:
      if parent[0].kind == nnkIdent:
        parent[0] = postfix(parent[0], "*")

    if parent.kind in [nnkVarSection, nnkLetSection, nnkConstSection, nnkRecList]:
      for defs in parent:
        for (index, node) in defs.pairs:
          if node.kind == nnkIdent and index < defs.len - 2:
            defs[index] = postfix(node, "*")

    for node in parent:
      traverse(node)

  traverse(body)

  result = body

## macro to import all files in the current directory non-recursively
template importAll*(): untyped =
  macro importAllDef(filename: static[string]): untyped =
    result = newNimNode(nnkImportStmt)
    
    for f in walkDir("src", true):
      if f.kind == pcFile :
        let split = f.path.splitFile()
        if split.ext == ".nim" and split.name != filename[0..^5]: result.add ident(split.name)
  
  importAllDef(instantiationInfo().filename)

#this was kind of a bad idea...
#[
## registers an event to be handled with `onEventName:`
macro event*(tname: untyped, args: varargs[untyped]): untyped =
  result = newStmtList()

  let td = quote do:
    type `tname`* = object

  let rec = newNimNode(nnkRecList)
  td[0][2][2] = rec

  for arg in args:
    rec.add(newIdentDefs(postfix(arg[0], "*"), arg[1], newEmptyNode()))
  
  result.add td

  let
    namestr = newLit(tname.repr)
    listenName = ident($tname.repr & "Proc")
    handleName = ident("on" & $tname.repr)
    fireName = ident("fire" & $tname.repr)

  result.add quote do:
    type `listenName`* = proc(event: `tname`)
    var `fireName`*: `listenName` = proc(event: `tname`) = discard
    proc fire*(event: `tname`) = `fireName`(event)
    macro `handleName`*(body: untyped) =
      eventHandlers.mgetOrPut(`namestr`, newSeq[NimNode]()).add(body)
  
## finishes building events - this must be called before any events are used!
macro buildEvents*() =
  result = newStmtList()
  for key, val in eventHandlers.pairs:
    let 
      fireName = ident("fire" & key)
      tname = ident(key)
    var sts = newStmtList()
    for node in val:
      sts.add quote do:
        block:
          `node`

    result.add quote do:
      `fireName` = proc(event {.inject.}: `tname`) =
        `sts`
]#

