## Basic implementation of immediate-mode elements rendered at specific positions. No layout is implemented here.

import fcore

type Style = object

proc button*(bounds: Rect, region = fau.white): bool =
  var col = rgba(1, 1, 1, 0)

  if bounds.contains(mouse()):
    col = rgba(0, 1, 1, 0.3f)
    if keyMouseLeft.down:
      col = rgba(1, 0, 0, 0.3f)
      result = true

  draw(region, bounds.x, bounds.y, bounds.w, bounds.h, align = daBotLeft, mixColor = col)