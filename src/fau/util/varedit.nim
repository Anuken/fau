## Requires --d:debugVarEdit to function.

import macros

var
  allFields {.compileTime.}: seq[NimNode]

template editFieldUi*(field: string, value: untyped): untyped =
  let fieldLabel {.used.} = field.cstring

  when value is int or value is int32:
    igInputInt(fieldLabel, addr value)
  elif value is float32:
    igInputFloat(fieldLabel, addr value)
  elif value is Vec2:
    igInputFloat2(fieldLabel, value)
  elif value is Vec2i:
    igInputInt2(fieldLabel, value)
  elif value is Rect:
    igInputFloat4(fieldLabel, value)
  elif value is Color:
    igColorEdit4(fieldLabel, value)
  elif value is bool:
    igCheckbox(fieldLabel, addr value)
  elif value is string:
    igInputText(fieldLabel, value)
  elif value is Patch:
    #unfortunately patches are read-only for now.
    var name = "error"
    for pname, patch in fau.atlas.patches.pairs:
      if patch == value:
        name = pname
    igText((field & ": " & $name).cstring)
  elif value is ref object:
    igText(($value[]).cstring)
  elif value is array or value is seq:
    if igTreeNode(fieldLabel):
      for i, arrayval in value.mpairs:
        editFieldUi($i, arrayval)
      
      igTreePop()
  elif value is object:
    if igTreeNode(fieldLabel):
      for ofield, ovalue in value.fieldpairs:
        editFieldUi(ofield, ovalue)
      igTreePop()
  elif compiles($value):
    igText((field & ": " & $value).cstring)
  else:
    when defined(EntityRef):
      if value is EntityRef:
        igText((field & " Entity#" & $value.entityId.int).cstring)
      else:
        igText(fieldLabel)
    else:
      igText(fieldLabel)

template listFieldsUi*(obj: untyped): untyped = 
  for field, value in obj.fieldpairs:
    editFieldUi(field, value)

macro editable*(sec) =

  when defined(debugVarEdit):
    result = newVarStmt(sec[0][0], sec[0][2])

    allFields.add sec[0][0]
  else:
    #with the editor disabled, it stays as-is
    result = sec

macro editableVars*(vars: untyped) =
  when defined(debugVarEdit):
    result = newStmtList()

    var newSec = newNimNode(nnkVarSection)

    for asgn in vars:
      asgn.expectKind(nnkAsgn)
      
      newSec.add newIdentDefs(asgn[0], newEmptyNode(), asgn[1])

      allFields.add asgn[0]
    
    result.add newSec

  else:
    result = newStmtList()

    for asgn in vars:
      asgn.expectKind(nnkAsgn)
      result.add newConstStmt(asgn[0], asgn[1])
    
when defined(debugVarEdit):
  import ../g2/imgui, strutils
  export imgui

  var 
    showDemo = true
    searchText: string = ""

  macro buildVarEditUi =
    result = newStmtList()

    for node in allFields:
      let name = node.repr
      result.add quote do:
        block:
          if (searchText == "" or `name`.toLowerAscii.contains(searchText.toLowerAscii)):
            editFieldUi(`name`, `node`)

  var showEditor = false

  template showVarEditor*() =
    if keyF1.tapped:
      showEditor = not showEditor

    if showEditor:
      igBegin("Variable Editor", addr showEditor)

      igInputTextWithHint("##Search", "Search", searchText)

      buildVarEditUi()

      igEnd()

else:
  if not declared(imguiInitFau):
    proc imguiInitFau(useCursor = true, appName: string = "") = discard
    proc imguiLoadFont(path: static string, size: float32) = discard

  proc showVarEditor() = discard