import streams, flippy, common, tables, unicode

from typography import getGlyphImageOffset, getGlyphImage, typeset

type 
  Font* = ref object
    font: typography.Font
    patches: Table[string, Patch]
    offsets: Table[string, Vec2]
  Align* = object
    h: typography.HAlignMode
    v: typography.VAlignMode

const 
  alignCenter* = Align(h: typography.Center, v: typography.Middle)
  alignTop* = Align(h: typography.Center, v: typography.Top)
  alignBot* = Align(h: typography.Center, v: typography.Bottom)
  alignLeft* = Align(h: typography.Left, v: typography.Middle)
  alignRight* = Align(h: typography.Right, v: typography.Middle)

  alignTopLeft* = Align(h: typography.Left, v: typography.Top)
  alignTopRight* = Align(h: typography.Right, v: typography.Top)
  alignBotLeft* = Align(h: typography.Left, v: typography.Bottom)
  alignBotRight* = Align(h: typography.Right, v: typography.Bottom)

proc loadFont*(path: static[string], size: float32 = 16'f32, textureSize = 128): Font =
  const data = staticRead(path)
  let str = newStringStream(data)

  let font = typography.readFontTtf(str)
  font.size = size

  result = Font(font: font, patches: initTable[string, Patch]())

  let packer = newTexturePacker(textureSize, textureSize)

  for ch in 0x0020'u16..0x00FF'u16:
    let code = $char(ch)
    if not font.glyphs.hasKey(code): continue

    let offset = font.getGlyphImageOffset(font.glyphs[code])
    let image = font.getGlyphImage(code)
    let patch = packer.pack(image)
    result.patches[code] = patch
    result.offsets[code] = vec2(offset.x, offset.y)

  packer.update()

proc draw*(font: Font, pos: Vec2, text: string, color: Color = rgba(1, 1, 1, 1), align: Align = alignCenter) =
  let layout = font.font.typeset(text, hAlign = align.h, vAlign = align.v)
  let col = color.toFloat()

  for ch in layout:
    if font.patches.hasKey(ch.character):
      let offset = font.offsets[ch.character]
      drawRect(font.patches[ch.character], ch.rect.x + pos.x + offset.x, ch.rect.y + pos.y - ch.rect.h - offset.y, ch.rect.w, ch.rect.h, color = col)