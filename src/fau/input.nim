import globals, fmath

var 
  keysPressed*: array[KeyCode, bool]
  keysJustDown*: array[KeyCode, bool]
  keysJustUp*: array[KeyCode, bool]

proc down*(key: KeyCode): bool {.inline.} = keysPressed[key]
proc tapped*(key: KeyCode): bool {.inline.} = keysJustDown[key]
proc released*(key: KeyCode): bool {.inline.} = keysJustUp[key]

proc axis*(left, right: KeyCode): int = right.down.int - left.down.int
proc axis2*(left = keyA, right = keyD, bottom = keyS, top = keyW): Vec2 = vec2(axis(left, right).float32, axis(bottom, top).float32)

proc axisTap*(left, right: KeyCode): int = right.tapped.int - left.tapped.int
proc axisTap2*(left, right, bottom, top: KeyCode): Vec2 = vec2(axisTap(left, right).float32, axisTap(bottom, top).float32)