import macros

## copies an array into a seq, element by element.
macro minsert*(dest: untyped, index: int, data: untyped): untyped =
  result = newStmtList()
  
  if data.kind == nnkBracket:
    for i in 0..<data.len:
      result.add newAssignment(newNimNode(nnkBracketExpr).add(dest).add(infix(index, "+", newIntLitNode(i))), data[i])
  else:
    error("Insertion data must be array!", data)

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