## module for defining and storing 'content' ref objects: blocks, items, enemy archetypes, etc

import macros, strutils, sets, tables

#holds default values for fields of types
#maps type name, field name to initialization node
var defaultValues {.compileTime.}: Table[string, Table[string, NimNode]]

## base content class, should be extended
type Content* = ref object of RootObj
  name*: string
  id*: uint32

proc postStrVal(node: NimNode): string =
  if node.kind == nnkPostfix: node[1].strVal else: node.strVal

macro defineContentTypes*(body: untyped): untyped =
  result = body
  
  for typeSec in result:
    for typeD in typeSec:
      let name = typeD[0].postStrVal

      if typeD[2][0].kind != nnkEmpty:
        for i in typeD[2][0][2]:
          if i[2].kind != nnkEmpty:
            if not defaultValues.hasKey(name):
              defaultValues[name] = initTable[string, NimNode]()
            #save default value
            defaultValues[name][i[0].postStrVal] = i[2]

            i[2] = newEmptyNode()
      

## creates definition for a list of Content objects with IDs and names
macro makeContent*(body: untyped): untyped =
  result = newStmtList()
  
  var 
    letSec = newNimNode(nnkVarSection)
    id = 0
    initProc = quote do:
      template initContent*() =
        discard
    initBody = initProc[6]

  result.add letSec
  result.add initProc
  var usedNames: HashSet[string]

  result.add quote do:
    var contentList* {.inject.}: seq[Content]

  for n in body:
    if n.kind == nnkAsgn:
      var 
        nameIdent = $n[0] #name of content
        consn = n[1] #object constructor call
        typet = consn[0]
        typeName = $consn[0] #e.g. "Block"
        listName = ident(typeName.toLowerAscii & "List")
        resName = typeName.toLowerAscii & nameIdent.capitalizeAscii
      
      if typeName notin usedNames:
        result.add quote do:
          var `listName`* {.inject.}: seq[`typet`]
        usedNames.incl typeName
      
      #switch empty calls to constructors
      if consn.kind == nnkCall:
        consn = newNimNode(nnkObjConstr).add(ident(typeName))
      
      defaultValues.withValue(typeName, defs):
        for key, value in defs[].pairs:
          #only add default values that have not been defined already
          var found = false
          for par in consn:
            if par.kind == nnkExprColonExpr and par[0].strVal == key:
              found = true
              break
        
          if not found:
            consn.add(newNimNode(nnkExprColonExpr).add(ident(key)).add(value))

      #assign ID
      consn.add(newNimNode(nnkExprColonExpr).add(ident("id")).add(newIntLitNode(id)))
      #assign name
      consn.add(newNimNode(nnkExprColonExpr).add(ident("name")).add(newStrLitNode(nameIdent)))
      #declare the var
      letSec.add newIdentDefs(postfix(ident(resName), "*"), typet, newEmptyNode())
      #construct var
      initBody.add(newAssignment(ident(resName), consn))
      #add to list
      initBody.add newCall(newDotExpr(ident("contentList"), ident("add")), ident(resName))
      #add to other list
      initBody.add newCall(newDotExpr(listName, ident("add")), ident(resName))
      inc id
