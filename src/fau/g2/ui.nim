## Basic implementation of immediate-mode elements rendered at specific positions. No layout is implemented here.

import ../draw, ../globals, ../color, ../patch, ../fmath, ../input, font

type 
  ButtonStyle* = object
    downColor*, upColor*, overColor*, disabledColor*: Color
    iconUpColor*, iconDownColor*: Color
    up*, down*, over*: Patch9
    textUpColor*, textDisabledColor*, textOverColor*: Color = colorWhite
    font*: Font
  SliderStyle* = object
    back*, up*, over*, down*: Patch9
    backColor*, upColor*, overColor*, downColor*: Color
    sliderWidth*: float32

#hover styles only work on PC, disable them on mobile
when isMobile:
  const canHover = false
else:
  const canHover = true

var
  uiPatchScale* = 1f
  uiFontScale* = 1f
  uiScale* = 1f

  defaultFont*: Font
  defaultButtonStyle* = ButtonStyle(textUpColor: colorWhite, textDisabledColor: colorWhite)
  defaultSliderStyle* = SliderStyle(sliderWidth: 20f)

proc uis*(val: float32): float32 {.inline.} = uiScale * val

proc mouseUi(): Vec2 =
  fau.mouseWorld()

#TODO: inject some state for better button press handling.
proc button*(bounds: Rect, text = "", style = defaultButtonStyle, icon = Patch(), toggled = false, disabled = false, iconSize = if icon.valid: uiPatchScale * icon.widthf else: 0f, rotation = 0f, markup = false): bool =
  var 
    col = style.upColor
    textCol = style.textUpColor
    down = toggled
    patch = style.up
    over = bounds.contains(mouseUi()) and not disabled
    font = if style.font.isNil: defaultFont else: style.font
  
  if disabled:
    col = style.disabledColor
    textCol = style.textDisabledColor

  if over:
    if canHover and style.over.valid: patch = style.over
    if canHover: col = style.overColor
    textCol = style.textOverColor

    if keyMouseLeft.down:
      down = true
      result = keyMouseLeft.tapped

  if down:
    col = style.downColor
    if style.down.valid: patch = style.down

  draw(if patch.valid: patch else: fau.white.patch9, bounds, mixColor = col, scale = uiPatchScale)

  if text.len != 0 and not font.isNil:
    font.draw(text,
      vec2(bounds.x, bounds.y) + vec2(patch.left.float32, patch.bot.float32) * uiPatchScale,
      bounds = vec2(bounds.w, bounds.h) - vec2(patch.left.float32 + patch.right.float32, patch.bot.float32 + patch.top.float32) * uiPatchScale,
      scale = uiFontScale, align = daCenter,
      color = textCol, markup = markup
    )

  if icon.valid:
    draw(icon, bounds.center, iconSize.vec2, mixColor = if down: style.iconDownColor else: style.iconUpColor, rotation = rotation)

template slider*(bounds: Rect, min, max: float32, value: var float32, style = defaultSliderStyle, text = "") =
  ## Special slider template with automatic state injection.
  var down {.global.}: bool
  slider(bounds, min, max, down, value, style, text)

proc slider*(bounds: Rect, min, max: float32, wasDown: var bool, value: var float32, style = defaultSliderStyle, text = "", textScale = 1f) =
  #TODO vertical padding would be nice?
  if style.back.valid:
    draw(style.back, bounds, scale = uiPatchScale, mixColor = style.backColor)
  
  let
    pad = style.sliderWidth.uis
    clamped = (value - min) / (max - min)
    sliderx = clamped * (bounds.w - pad) + bounds.x + pad/2f
    mouse = mouseUi()
  var 
    patch = style.up
    col = style.upColor

  if bounds.contains(mouse) or wasDown:
    if canHover and style.over.valid: patch = style.over
    if canHover: col = style.overColor

    if keyMouseLeft.tapped or wasDown:
      wasDown = true
      value = clamp((mouse.x - (bounds.x + pad/2f)) / (bounds.w - pad) * (max - min) + min, min, max)
      col = style.downColor
      if style.down.valid: patch = style.down

  if keyMouseLeft.down.not:
    wasDown = false

  if patch.valid:
    draw(patch, rect(sliderx - pad/2f, bounds.y, pad, bounds.h), mixColor = col, scale = uiPatchScale)
  
  if text.len > 0:
    defaultFont.draw(text, bounds, scale = uiFontScale * textScale)

#TODO remove? this is striclty less useful
proc text*(bounds: Rect, text: string, align = daCenter, color = colorWhite, scale = 1f, modifier: GlyphProc = nil, markup = false, font = defaultFont) =
  font.draw(text,
    bounds,
    scale = uiFontScale * scale, align = align,
    color = color, modifier = modifier,
    markup = markup
  )