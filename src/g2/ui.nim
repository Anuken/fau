## Basic implementation of immediate-mode elements rendered at specific positions. No layout is implemented here.

import fcore

type 
  ButtonStyle* = object
    downColor*, upColor*, overColor*: Color
    iconUpColor*, iconDownColor*: Color
    up*, down*, over*: Patch9
    font*: Font
  TextStyle* = object
    font*: Font
    upColor*, overColor*, downColor*: Color
  SliderStyle* = object
    back*, up*, over*, down*: Patch9
    backColor*, upColor*, overColor*, downColor*: Color
    sliderWidth*: float32

#hover styles only work on PC, disable them on mobile
when defined(Android):
  const canHover = false
else:
  const canHover = true

var
  uiPatchScale* = 1f
  uiFontScale* = 1f
  uiScale* = 1f

  defaultFont*: Font
  defaultButtonStyle* = ButtonStyle()
  defaultTextStyle* = TextStyle()
  defaultSliderStyle* = SliderStyle(sliderWidth: 20f)

proc uis*(val: float32): float32 {.inline.} = uiScale * val

proc button*(bounds: Rect, text = "", style = defaultButtonStyle, icon = Patch(), toggled = false, iconSize = if icon.valid: uiPatchScale * icon.widthf else: 0f): bool =
  var 
    col = style.upColor
    down = toggled
    patch = style.up
    font = if style.font.isNil: defaultFont else: style.font

  if bounds.contains(fau.mouse):
    if canHover and style.over.valid: patch = style.over
    if canHover: col = style.overColor

    if keyMouseLeft.down:
      down = true
      result = keyMouseLeft.tapped

  if down:
    col = style.downColor
    if style.down.valid: patch = style.down

  draw(if patch.valid: patch else: fau.white.patch9, bounds, mixColor = col, scale = uiPatchScale)

  if text.len != 0 and not font.isNil:
    font.draw(text,
      vec2(bounds.x, bounds.y) + vec2(patch.left, patch.bot) * uiPatchScale,
      bounds = vec2(bounds.w, bounds.h) - vec2(patch.left + patch.right, patch.bot - patch.top) * uiPatchScale,
      scale = uiFontScale, align = daCenter
    )

  if icon.valid:
    draw(icon, bounds.center, iconSize.vec2, mixColor = if down: style.iconDownColor else: style.iconUpColor)

proc slider*(bounds: Rect, min, max: float32, value: var float32, style = defaultSliderStyle) =
  #TODO vertical padding would be nice?
  if style.back.valid:
    draw(style.back, bounds, scale = uiPatchScale, mixColor = style.backColor)
  
  let
    pad = style.sliderWidth.uis
    clamped = (value - min) / (max - min) * (bounds.w - pad) + bounds.x + pad/2f
  var 
    patch = style.up
    col = style.upColor

  if bounds.contains(fau.mouse):
    if canHover and style.over.valid: patch = style.over
    if canHover: col = style.overColor

    if keyMouseLeft.down:
      value = clamp((fau.mouse.x - (bounds.x)) / (bounds.w - pad) * (max - min) + min, min, max)
      col = style.downColor
      if style.down.valid: patch = style.down

  if patch.valid:
    draw(patch, rect(clamped - pad/2f, bounds.y, pad, bounds.h), mixColor = col, scale = uiPatchScale)

proc text*(bounds: Rect, text: string, style = defaultTextStyle, align = daCenter) =
  var font = if style.font.isNil: defaultFont else: style.font

  if text.len != 0 and not font.isNil:
    font.draw(text,
      bounds.pos,
      bounds = bounds.size,
      scale = uiFontScale, align = align
    )