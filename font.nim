import fcore, tables, unicode, packer

from pixie import Image, draw, newImage
from typography import getGlyphImageOffset, getGlyphImage, typeset
from vmath import nil

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
    font: typography.Font
    patches: Table[string, Patch]
    offsets: Table[string, Vec2]
  Align* = object
    h: typography.HAlignMode
    v: typography.VAlignMode

const 
  faCenter* = Align(h: typography.Center, v: typography.Middle)
  faTop* = Align(h: typography.Center, v: typography.Top)
  faBot* = Align(h: typography.Center, v: typography.Bottom)
  faLeft* = Align(h: typography.Left, v: typography.Middle)
  faRight* = Align(h: typography.Right, v: typography.Middle)

  faTopLeft* = Align(h: typography.Left, v: typography.Top)
  faTopRight* = Align(h: typography.Right, v: typography.Top)
  faBotLeft* = Align(h: typography.Left, v: typography.Bottom)
  faBotRight* = Align(h: typography.Right, v: typography.Bottom)

proc loadFont*(path: static[string], size: float32 = 16f, textureSize = 128): Font =
  when not defined(emscripten):
    const str = staticReadString(path)
    let font = typography.parseOtf(str)
  else:
    let font = typography.readFontTtf("assets/" & path)
  
  font.size = size

  result = Font(font: font, patches: initTable[string, Patch]())

  let packer = newTexturePacker(textureSize, textureSize)

  for ch in 0x0020'u16..0x00FF'u16:
    let code = $char(ch)
    if not font.typeface.glyphs.hasKey(code): continue

    let offset = font.getGlyphImageOffset(font.typeface.glyphs[code])
    let image = font.getGlyphImage(code)
    let patch = packer.pack(image)
    result.patches[code] = patch
    result.offsets[code] = vec2(offset.x, offset.y)

  packer.update()

proc draw*(font: Font, text: string, pos: Vec2, scale: float32 = fau.pixelScl, color: Color = rgba(1, 1, 1, 1), align: Align = faCenter, z: float32 = 0.0) =
  let layout = font.font.typeset(text, hAlign = align.h, vAlign = align.v)

  for ch in layout:
    if font.patches.hasKey(ch.character):
      let offset = font.offsets[ch.character]
      drawRect(font.patches[ch.character], (ch.rect.x + offset.x) * scale + pos.x, (ch.rect.y - ch.rect.h - offset.y) * scale + pos.y, ch.rect.w*scale, ch.rect.h*scale, color = color, z = z)