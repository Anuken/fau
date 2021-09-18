import globals

var 
  keysPressed*: array[KeyCode, bool]
  keysJustDown*: array[KeyCode, bool]
  keysJustUp*: array[KeyCode, bool]

proc down*(key: KeyCode): bool {.inline.} = keysPressed[key]
proc tapped*(key: KeyCode): bool {.inline.} = keysJustDown[key]
proc released*(key: KeyCode): bool {.inline.} = keysJustUp[key]
proc axis*(left, right: KeyCode): int = right.down.int - left.down.int