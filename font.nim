import tables, unicode, packer
import math

import fcore except vec2

from fmath import nil
from pixie import Image, draw, newImage, #[getGlyphImageOffset, getGlyphImage,]# typeset, getGlyphPath, commandsToShapes, scale, fillPath, lineHeight, ascent, descent
from vmath import x, y, `*`, `-`
from bumpy import xy
from chroma import nil

#Dynamic packer that writes its results to a GL texture.
type TexturePacker* = ref object
  texture*: Texture
  packer*: Packer
  image*: Image

# Creates a new texture packer limited by the specified width/height
proc newTexturePacker*(width, height: int): TexturePacker =
  TexturePacker(
    packer: newPacker(width, height),
    texture: newTexture(width, height),
    image: newImage(width, height)
  )

proc pack*(packer: TexturePacker, image: Image): Patch =
  let (x, y) = packer.packer.pack(image.width, image.height)
  packer.image.draw(image, vmath.vec2(x.float32, y.float32))
  return newPatch(packer.texture, x, y, image.width, image.height)

# Updates the texture of a texture packer. Call this when you're done packing.
proc update*(packer: TexturePacker) =
  packer.texture.load(packer.image.width, packer.image.height, addr packer.image.data[0])

type
  Font* = ref object
    font: pixie.Font
    patches: Table[Rune, Patch]
    offsets: Table[Rune, Vec2]

proc toVAlign(align: int): pixie.VAlignMode {.inline.} =
  return if (align and daBot) != 0 and (align and daTop) != 0: pixie.vaMiddle
  elif (align and daBot) != 0: pixie.vaBottom
  elif (align and daTop) != 0: pixie.vaTop
  else: pixie.vaMiddle

proc toHAlign(align: int): pixie.HAlignMode {.inline.} =
  return if (align and daLeft) != 0 and (align and daRight) != 0: pixie.haCenter
  elif (align and daLeft) != 0: pixie.haLeft
  elif (align and daRight) != 0: pixie.haRight
  else: pixie.haCenter

#TODO use the pixie exposed methods when they become public
proc computeBounds(shapes: seq[seq[vmath.Vec2]]): bumpy.Rect =
  var
    xMin = float32.high
    xMax = float32.low
    yMin = float32.high
    yMax = float32.low
  for shape in shapes:
    for pos in shape:
      xMin = min(xMin, pos.x)
      xMax = max(xMax, pos.x)
      yMin = min(yMin, pos.y)
      yMax = max(yMax, pos.y)

  xMin = floor(xMin)
  xMax = ceil(xMax)
  yMin = floor(yMin)
  yMax = ceil(yMax)

  result.x = xMin
  result.y = yMin
  result.w = xMax - xMin
  result.h = yMax - yMin

proc transform(shapes: var seq[seq[vmath.Vec2]], transform: vmath.Mat3) =
  for shape in shapes.mitems:
    for segment in shape.mitems:
      segment = transform * segment

proc getGlyphImage(font: pixie.Font, r: Rune): (Image, Vec2) =
  let path = font.typeface.getGlyphPath(r)
  var shapes = path.commandsToShapes()
  if shapes.len == 0:
    return
  shapes.transform(vmath.scale(vmath.vec2(font.scale)))
  let bounds = computeBounds(shapes)
  let bxy = -bounds.xy
  result[0] = newImage(bounds.w.int, bounds.h.int)
  result[0].fillPath(shapes, chroma.rgba(255, 255, 255, 255), bxy)
  result[1] = fmath.vec2(bounds.xy)

proc `==`*(a, b: Rune): bool {.inline.} = a.int32 == b.int32

proc loadFont*(path: static[string], size: float32 = 16f, textureSize = 128): Font =
  when not defined(emscripten):
    const str = staticReadString(path)
    var font = pixie.parseTtf(str)
  else:
    var font = pixie.parseTtf(readFile("assets/" & path))

  font.size = size

  result = Font(font: font, patches: initTable[Rune, Patch]())

  let packer = newTexturePacker(textureSize, textureSize)

  for ch in 0x0020'u16..0x00FF'u16:
    let code = Rune(ch)

    let (image, offset) = font.getGlyphImage(code)
    if image.isNil: continue

    let patch = packer.pack(image)
    result.patches[code] = patch
    result.offsets[code] = offset

  packer.update()

proc draw*(font: Font, text: string, pos: Vec2, scale: float32 = fau.pixelScl, bounds = fmath.vec2(0, 0), color: Color = rgba(1, 1, 1, 1), align: int = daCenter, z: float32 = 0.0) =

  let arrangement = font.font.typeset(text, hAlign = align.toHAlign, vAlign = align.toVAlign, bounds = vmath.vec2(bounds.x / scale, bounds.y / scale))

  for i, rune in arrangement.runes:
    let ch = arrangement.selectionRects[i]
    let p = arrangement.positions[i]

    if font.patches.hasKey(rune):
      let offset = font.offsets[rune]
      let patch = font.patches[rune]
      drawRect(patch,
        (p.x + offset.x) * scale + pos.x,
        (bounds.y/scale - 1 - p.y - offset.y - patch.heightf) * scale + pos.y,
        patch.widthf*scale, patch.heightf*scale, color = color, z = z
      )
