import globals, fmath

const controllerDeadzone = 0.2

var 
  keysPressed*: array[KeyCode, bool]
  keysJustDown*: array[KeyCode, bool]
  keysJustUp*: array[KeyCode, bool]

#keyboard

proc down*(key: KeyCode): bool {.inline.} = keysPressed[key]
proc tapped*(key: KeyCode): bool {.inline.} = keysJustDown[key]
proc released*(key: KeyCode): bool {.inline.} = keysJustUp[key]

proc axis*(left, right: KeyCode): int = right.down.int - left.down.int
proc axis2*(left = keyA, right = keyD, bottom = keyS, top = keyW): Vec2 = vec2(axis(left, right).float32, axis(bottom, top).float32)

proc axisTap*(left, right: KeyCode): int = right.tapped.int - left.tapped.int
proc axisTap2*(left, right, bottom, top: KeyCode): Vec2 = vec2(axisTap(left, right).float32, axisTap(bottom, top).float32)

#gamepad (indexed)

proc down*(pad: Gamepad, button: GamepadButton): bool {.inline.} = pad.buttons[button]
proc tapped*(pad: Gamepad, button: GamepadButton): bool {.inline.} = pad.buttonsJustDown[button]
proc released*(pad: Gamepad, button: GamepadButton): bool {.inline.} = pad.buttonsJustUp[button]

#TODO: deadzones

proc axis*(pad: Gamepad, axis: GamepadAxis): float32 {.inline.} = pad.axes[axis].float32
proc axis2*(pad: Gamepad, axes: GamepadAxis2): Vec2 {.inline.} =
  if axes == left: result = vec2(pad.axis(leftX), pad.axis(leftY))
  elif axes == right: result = vec2(pad.axis(rightX), pad.axis(rightY))
  else: result = vec2()

  if result.len < controllerDeadzone:
    result = vec2()

#gamepad (for singleplayer, any gamepad will work)

proc gamepadDown*(button: GamepadButton): bool =
  for pad in fau.gamepads:
    if pad.down(button): return true

proc gamepadTapped*(button: GamepadButton): bool =
  for pad in fau.gamepads:
    if pad.tapped(button): return true

proc gamepadTapped*(buttons: varargs[GamepadButton]): bool =
  for button in buttons:
    if gamepadTapped(button):
      return true

proc gamepadReleased*(button: GamepadButton): bool =
  for pad in fau.gamepads:
    if pad.released(button): return true

proc gamepadAxis*(axis: GamepadAxis): float32 =
  for pad in fau.gamepads:
    let val = pad.axis(axis)
    if val != 0: return val

proc gamepadAxis2*(axes: GamepadAxis2): Vec2 =
  for pad in fau.gamepads:
    let val = pad.axis2(axes)
    if not val.zero: return val