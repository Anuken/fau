import ../fmath

## WIP
## Taken from https://gist.github.com/jorisbontje/c6275e448df3916a6d8fab687d9a9189

type
  RGBoxType* = enum
    Horizontal
    Vertical

  RGBox* = ref object
    prev: RGBox
    lastChild: RGBox
    rectangle*: Rect
    boxType: RGBoxType
    weight: int
    minWidth*: int
    minHeight*: int
    paddingTop*: float
    paddingRight*: float
    paddingBottom*: float
    paddingLeft*: float
    hasParent: bool

proc newRootRGBox*(boxType: RGBoxType, width, height: int): RGBox = RGBox(boxType: boxType, minWidth: width, minHeight: height)

proc newRGBox*(parent: RGBox, boxType: RGBoxType, minWidth, minHeight, weight: int, paddingTop = 0.0, paddingRight = 0.0, paddingBottom = 0.0, paddingLeft = 0.0): RGBox =
  parent.lastChild = RGBox(
    prev: parent.lastChild,
    hasParent: true,
    boxType: boxType,
    weight: weight,
    minWidth: minWidth,
    minHeight: minHeight,
    paddingTop: paddingTop,
    paddingRight: paddingRight,
    paddingBottom: paddingBottom,
    paddingLeft: paddingLeft
  )
  return parent.lastChild

proc hBox*(parent: RGBox, minWidth = 0, minHeight = 0, weight = 0): RGBox =
  parent.newRGBox(Horizontal, minWidth, minHeight, weight)

proc vBox*(parent: RGBox, minWidth = 0, minHeight = 0, weight = 0): RGBox =
  parent.newRGBox(Vertical, minWidth, minHeight, weight)

proc getMinSize(self: RGBox): tuple[minWidth, minHeight: int] =
  var
    w = 0
    h = 0
    child = self.lastChild
  while child != nil:
    let (w2, h2) = getMinSize(child)
    if self.boxType == Horizontal:
      w += w2
      h = max(h, h2)
    else:
      h += h2
      w = max(w, w2)
    child = child.prev

  result.minWidth = max(self.minWidth, w)
  result.minHeight = max(self.minHeight, h)

proc layout*(self: RGBox) =
  var weightSum: int

  if not self.hasParent:
    self.rectangle = rect(0f, 0f, self.minWidth.float, self.minHeight.float)

  # Get weight sum
  var child = self.lastChild
  while child != nil:
    weightSum += child.weight
    child = child.prev

  # Get dynamic space
  let
    ds = if weightSum > 0: 1.0 / weightSum.float else: 0.0
    size = if self.boxType == Horizontal: self.rectangle.w else: self.rectangle.h
  var
    dynSpace = size
    startPos = size

  child = self.lastChild
  while child != nil:
    let
      (minW, minH) = getMinSize(child)
      childSize = (child.weight.float * ds) * size
      minSize = (if self.boxType == Horizontal: minW else: minH).float

    dynSpace -= (if childSize < minSize: minSize else: 0.0)
    startPos -= (if weightSum == 0: (if childSize < minSize: minSize else: childSize) else: 0.0)

    child = child.prev

  # Layout children
  startPos = if weightSum == 0: startPos else: 0.0
  let pos0 = if self.boxType == Horizontal: self.rectangle.y else: self.rectangle.x
  var pos = if self.boxType == Horizontal: self.rectangle.x + self.rectangle.w else: self.rectangle.y + self.rectangle.h

  child = self.lastChild
  while child != nil:
    let
      (minW, minH) = getMinSize(child)
      childSize = (child.weight.float * ds) * dynSpace
      paddingX = child.paddingLeft + child.paddingRight
      paddingY = child.paddingTop + child.paddingBottom

    if self.boxType == Horizontal:
      let minSize = minW.float
      if childSize < minSize:
        child.rectangle = rect(pos - minSize + child.paddingLeft - startPos, pos0 + child.paddingTop, minSize - paddingX, self.rectangle.h - paddingY)
      else:
        child.rectangle = rect(pos - childSize + child.paddingLeft - startPos, pos0 + child.paddingTop, childSize - paddingX, self.rectangle.h - paddingY)
      pos -= child.rectangle.w + paddingX
    else:
      let minSize = minH.float
      if childSize < minSize:
        child.rectangle =
          (pos0 + child.paddingLeft, pos - minSize + child.paddingTop - startPos, self.rectangle.w - paddingX, minSize - paddingY)
      else:
        child.rectangle = rect(pos0 + child.paddingLeft, pos - childSize + child.paddingTop - startPos, self.rectangle.w - paddingX, childSize - paddingY)
      pos -= child.rectangle.h + paddingY

    layout(child)
    child = child.prev