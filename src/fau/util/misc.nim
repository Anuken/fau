import std/[macros, tables, strutils, parseutils, os, times]

# Utility macros, templates & sugar.

proc parseFloat32*(str: openArray[char], val: var float32): int {.discardable.} =
  ## Variant for parsing 32-bit floats, for convenience.

  var v = val.float
  result = parseFloat(str, v)
  val = v.float32

proc capitalize*(str: openArray[char], spaces = false, camel = false): string =
  ## Converts a snake_case or kebab-case string to UpperCase, optionally inserting spaces between words.

  result = newStringOfCap(str.len)
  for i in 0..<str.len:
    let c = str[i]
    if c in {'-', '_'}:
      if spaces:
        result.add(' ')
    elif (i == 0 and not camel) or (i > 0 and str[i - 1] in {'-', '_'}):
      result.add(c.toUpperAscii)
    else:
      if i > 0 and spaces and c.isUpperAscii and str[i - 1].isLowerAscii:
        result.add ' '
      result.add(c)


iterator walkDirRec2*(dir: string,
                     yieldFilter = {pcFile}, followFilter = {pcDir},
                     relative = false, checkDir = false, skipSpecial = false):
                    string {.tags: [ReadDirEffect].} =
  ## walkDirRec implementation that actually works when cross-compiling (avoids usage of the `/` proc)
  var stack = @[""]
  var checkDir = checkDir
  while stack.len > 0:
    let d = stack.pop()
    for k, p in walkDir(dir & "/" & d, relative = true, checkDir = checkDir,
                        skipSpecial = skipSpecial):
      let rel = d & "/" & p
      if k in {pcDir, pcLinkToDir} and k in followFilter:
        stack.add rel
      if k in yieldFilter:
        yield if relative: rel else: dir & (if rel.startsWith("/"): "" else: "/") & rel
    checkDir = false

template findResult*[T](list: openArray[T], body: untyped): T =
  var result = default(T)
  for i, it {.inject.} in list:
    if body:
      result = it
      break
  
  result

template findIt*[T](list: openArray[T], body: untyped): int =
  var result = -1
  for i, it {.inject.} in list:
    if body:
      result = i
      break
  
  result

#ordered version
template deleteAll*[T](list: var seq[T], body: untyped) =
  var i = 0
  while i < list.len:
    let it {.inject.} = list[i]
    if body:
      list.delete(i)
    else:
      i.inc

#unordered version
template delAll*[T](list: var seq[T], body: untyped) =
  var i = 0
  while i < list.len:
    let it {.inject.} = list[i]
    if body:
      list.delete(i)
    else:
      i.inc

template findItBlock*[T](list: openArray[T], body: untyped, calledBlock: untyped) =
  for i {.inject.}, it {.inject.} in list:
    if body:
      calledBlock
      break

template incTimer*(value: untyped, increment: float32, body: untyped): untyped =
  `value` += `increment`
  if `value` >= 1f:
    `value` = 0f
    `body`

template findMinIndex*[T](list: openArray[T], op: untyped): int =
  var minValue = float32.high
  var result = -1
  for i, it {.inject.} in list:
    let newMin = op
    if newMin < minValue:
      minValue = newMin
      result = i
  result

template findMin*[T](list: openArray[T], op: untyped): untyped =
  var minValue = float32.high
  var result: T
  for it {.inject.} in list:
    let newMin = op
    if newMin < minValue:
      minValue = newMin
      result = it
  result

template findMin*[T](list: openArray[T], op: untyped, predicate: untyped): untyped =
  var minValue = float32.high
  var result: T
  for it {.inject.} in list:
    if predicate:
      let newMin = op
      if newMin < minValue:
        minValue = newMin
        result = it
  result

macro minsert*(dest: untyped, index: int, data: untyped): untyped =
  ## copies an array into a seq, element by element.
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

macro exportAll*(body: untyped) =
  ## exports all types/variables in the macro body
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

template importAll*(): untyped =
  ## macro to import all files in the current directory non-recursively
  macro importAllDef(filename: static[string]): untyped =
    result = newNimNode(nnkImportStmt)
    
    for f in walkDir("src", true):
      if f.kind == pcFile :
        let split = f.path.splitFile()
        if split.ext == ".nim" and split.name != filename[0..^5]: result.add ident(split.name)
  
  importAllDef(instantiationInfo().filename)

#https://forum.nim-lang.org/t/9504
template unroll*(iter, name0, body0: untyped): untyped =
  macro unrollImpl(name, body) =
    result = newStmtList()
    for a in iter:
      result.add(newBlockStmt(newStmtList(
        newConstStmt(name, newLit(a)),
        copy body
      )))
  unrollImpl(name0, body0)


export cpuTime, formatFloat

template printTime*(label: string, body: untyped): untyped =
  var startTime0 = cpuTime()
  body
  let elapsed0 = ((cpuTime() - startTime0) * 1000.0)
  echo label, ": ", elapsed0.formatFloat(format = ffDecimal, precision = 2)

when defined(windows):
  import std/winlean

  proc getUserNameImpl(lpBuffer: WideCString, pcbBuffer: ptr int32): int32
    {.importc: "GetUserNameW", dynlib: "advapi32.dll", stdcall.}

  proc getUserName*(): string =
    var
      size: int32 = 256
      buf = newWideCString("", size.int)
    if getUserNameImpl(buf, addr size) != 0:
      result = $buf
    else:
      #fallback if the WinAPI call fails for some reason
      result = getEnv("USERNAME")
      if result.len == 0:
        result = getEnv("USER")

else: #linux/macOS
  import std/posix

  proc getUserName*(): string =
    when nimvm:
      result = getEnv("USER")
      if result.len == 0:
        result = getEnv("USERNAME")
      if result.len == 0:
        when defined(windows):
          result = gorgeEx("cmd /c echo %USERNAME%").output.strip()
        else:
          result = gorgeEx("whoami").output.strip()
    else:
      
      let pw = getpwuid(getuid())
      if pw != nil:
        result = $pw.pw_name
      else:
        result = getEnv("USER")
        if result.len == 0:
          result = getEnv("LOGNAME")