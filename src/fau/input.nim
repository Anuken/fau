import globals, fmath

const gamepadDeadzone* = 0.2

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

#modifier

proc shiftTapped*: bool {.inline.} = keyLShift.tapped or keyRShift.tapped
proc ctrlTapped*: bool {.inline.} = keyLCtrl.tapped or keyRCtrl.tapped

proc shiftDown*: bool {.inline.} = keyLShift.down or keyRShift.down
proc ctrlDown*: bool {.inline.} = keyLCtrl.down or keyRCtrl.down

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

  if result.len < gamepadDeadzone:
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

proc gamepadDpadTap*(): Vec2 = 
  vec2(
    GamepadButton.dpadRight.gamepadTapped.float32 - GamepadButton.dpadLeft.gamepadTapped.float32,
    GamepadButton.dpadUp.gamepadTapped.float32 - GamepadButton.dpadDown.gamepadTapped.float32
  )

proc rumble*(gamepad: Gamepad, slowIntensity, fastIntensity: float32, duration: float32 = 0.3f) =
  gamepad.rumbleDuration = max(gamepad.rumbleDuration, duration)
  gamepad.rumbleDurationMax = max(gamepad.rumbleDurationMax, duration)
  
  gamepad.rumbleIntensityFast = max(gamepad.rumbleIntensityFast, slowIntensity)
  gamepad.rumbleIntensitySlow = max(gamepad.rumbleIntensitySlow, fastIntensity)

proc gamepadRumble*(slowIntensity, fastIntensity: float32, duration = 0.3f) =
  for pad in fau.gamepads:
    pad.rumble(slowIntensity, fastIntensity, duration)

proc name*(button: GamepadButton): string =
  return case button
  of a: "A"
  of b: "B"
  of x: "X"
  of y: "Y"
  of leftBumper: "Left Bumper"
  of rightBumper: "Right Bumper"
  of back: "Back"
  of start: "Start"
  of guide: "Guide" 
  of leftThumb: "Left Thumbstick"
  of rightThumb: "Right Thumbstick"
  of dpadUp: "D-Pad Up"
  of dpadDown: "D-Pad Down"
  of dpadLeft: "D-Pad Left"
  of dpadRight: "D-Pad Right"
  of leftTrigger: "Left Trigger"
  of rightTrigger: "Right Trigger"
  of unset: "Unset"