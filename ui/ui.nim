## Basic implementation of immediate-mode elements rendered at specific positions. No layout is implemented here.

import fcore

type ButtonStyle* = object
  downColor*, upColor*, overColor*: Color
  up*, down*, over*: Patch9
  font*: Font

var
  uiPatchScale* = 1f
  uiFontScale* = 1f

  defaultFont*: Font
  defaultButtonStyle* = ButtonStyle()

proc button*(bounds: Rect, text = "", style = defaultButtonStyle): bool =
  var col = style.upColor
  var patch = style.up
  var font = if style.font.isNil: defaultFont else: style.font

  if bounds.contains(mouse()):
    if style.over.valid: patch = style.over

    col = style.overColor
    if keyMouseLeft.down:
      col = style.downColor
      result = keyMouseLeft.tapped
      if style.down.valid: patch = style.down

  if patch.valid:
    draw(patch, bounds.x, bounds.y, bounds.w, bounds.h, mixColor = col, scale = uiPatchScale)

  if text.len != 0 and not font.isNil:
    font.draw(text,
      vec2(bounds.x, bounds.y) + vec2(patch.left, patch.bot) * uiPatchScale,
      bounds = vec2(bounds.w, bounds.h) - vec2(patch.left + patch.right, patch.bot - patch.top) * uiPatchScale,
      scale = uiFontScale, align = daCenter
    )
