import globals, fmath

var 
  keysPressed*: array[KeyCode, bool]
  keysJustDown*: array[KeyCode, bool]
  keysJustUp*: array[KeyCode, bool]

proc down*(key: KeyCode): bool {.inline.} = keysPressed[key]
proc tapped*(key: KeyCode): bool {.inline.} = keysJustDown[key]
proc released*(key: KeyCode): bool {.inline.} = keysJustUp[key]

proc axis*(left, right: KeyCode): int = right.down.int - left.down.int
proc axis2*(left, right, bottom, top: KeyCode): Vec2 = vec2(axis(left, right), axis(bottom, top))

proc axisTap*(left, right: KeyCode): int = right.tapped.int - left.tapped.int
proc axisTap2*(left, right, bottom, top: KeyCode): Vec2 = vec2(axisTap(left, right), axisTap(bottom, top))