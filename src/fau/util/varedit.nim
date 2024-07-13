## Requires --d:debugVarEdit to function.

import macros

var
  allFields {.compileTime.}: seq[NimNode]

macro editable*(sec) =

  when defined(debugVarEdit):
    result = newVarStmt(sec[0][0], sec[0][2])

    allFields.add sec[0][0]
  else:
    #with the editor disabled, it stays as-is
    result = sec

when defined(debugVarEdit):
  import ../g2/imgui
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
          #TODO: use entityedit system for this.
          if (searchText == "" or `name`.toLowerAscii.contains(searchText.toLowerAscii)):

            when `node` is float32:
              igInputFloat(`name`, `node`.addr)
            elif `node` is int:
              var i32v: int32 = (`node`).int32
              igInputInt(`name`, i32v.addr)
              `node` = i32v
            elif `node` is bool:
              igCheckbox(`name`, `node`.addr)
            elif `node` is Vec2:
              igInputFloat2(`name`, `node`)
            elif `node` is Color:
              igColorEdit4(`name`, `node`)
            else:
              echo "Unknown type for editing for field: ", name

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
    proc imguiInitFau*(useCursor = true, appName: string = "") = discard
    proc imguiLoadFont*(path: static string, size: float32) = discard

  proc showVarEditor*() = discard