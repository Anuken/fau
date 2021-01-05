import macros

## copies an array into a seq, element by element.
macro minsert*(dest: untyped, index: int, data: untyped): untyped =
  result = newStmtList()
  
  if data.kind == nnkBracket:
    for i in 0..<data.len:
      result.add newAssignment(newNimNode(nnkBracketExpr).add(dest).add(infix(index, "+", newIntLitNode(i))), data[i])
  else:
    error("Insertion data must be array!", data)