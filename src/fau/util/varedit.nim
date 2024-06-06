## Requires --d:debugVarEdit to function.

when defined(debugVarEdit):
  import ../g2/imgui
  export imgui

  var showDemo = true

  proc showVarEditor*() =
    
    igShowDemoWindow(showDemo.addr)
else:
  if not declared(imguiInitFau):
    proc imguiInitFau*(useCursor = true) = discard
    proc imguiHasMouse*(): bool = false
    proc imguiHasKeyboard*(): bool = false

  proc showVarEditor*() = discard