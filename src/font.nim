import typography, streams, flippy, packer, common, tables, unicode

type Gfont* = ref object
  font: Font
  patches: Table[string, Patch]
  offsets: Table[string, Vec2]

proc loadFont*(path: static[string], size: float32 = 16'f32, textureSize = 128): Gfont =
  const data = staticRead(path)
  let str = newStringStream(data)

  let font = readFontTtf(str)
  font.size = size

  result = Gfont(font: font, patches: initTable[string, Patch]())

  let packer = newTexturePacker(textureSize, textureSize)

  for ch in 0x0020'u16..0x00FF'u16:
    let code = $char(ch)
    if not font.glyphs.hasKey(code): continue

    let offset = font.getGlyphImageOffset(font.glyphs[code])
    let image = font.getGlyphImage(code)
    let patch = packer.pack(code, image)
    result.patches[code] = patch
    result.offsets[code] = vec2(offset.x, offset.y)

  packer.update()

proc draw*(font: Gfont, pos: Vec2, text: string, color: Color = rgba(1, 1, 1, 1), alignH: HAlignMode = Left, alignV: VAlignMode = Top) =
  let layout = font.font.typeset(text, hAlign = alignH, vAlign = alignV)
  let col = color.toInt()

  for ch in layout:
    if font.patches.hasKey(ch.character):
      let offset = font.offsets[ch.character]
      drawRect(font.patches[ch.character], ch.rect.x + pos.x + offset.x, ch.rect.y + pos.y - ch.rect.h - offset.y, ch.rect.w, ch.rect.h, color = col)