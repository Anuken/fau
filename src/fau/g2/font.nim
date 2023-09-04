import tables, unicode, packer, bitops
import math
import ../texture, ../patch, ../color, ../globals, ../util/util, ../draw, ../assets

from ../fmath import `+`, xy, wh, Align, asBot, asTop, asLeft, asRight, daCenter
from pixie import Image, draw, copy, newImage, typeset, getGlyphPath, scale, fillPath, lineHeight, ascent, descent, transform, computeBounds, parseSomePaint, `[]`, `[]=`, dataIndex
from vmath import x, y, `*`, `-`, `+`, isNaN, translate
from bumpy import xy
from chroma import nil

#Dynamic packer that writes its results to a GL texture.
type TexturePacker* = ref object
  texture*: Texture
  packer*: Packer
  image*: Image

# Creates a new texture packer limited by the specified width/height
proc newTexturePacker*(size: fmath.Vec2i): TexturePacker =
  TexturePacker(
    packer: newPacker(size.x, size.y),
    texture: newTexture(size),
    image: newImage(size.x, size.y)
  )

proc pack*(packer: TexturePacker, image: Image): Patch =
  let (x, y) = packer.packer.pack(image.width, image.height)
  packer.image.draw(image, vmath.translate(vmath.vec2(x.float32, y.float32)))
  return newPatch(packer.texture, x, y, image.width, image.height)

# Updates the texture of a texture packer. Call this when you're done packing.
proc update*(packer: TexturePacker) =
  packer.texture.load(fmath.vec2i(packer.image.width, packer.image.height), addr packer.image.data[0])

type 
  Font* = ref object
    font: pixie.Font
    patches: Table[Rune, Patch]
    offsets: Table[Rune, fmath.Vec2]
  GlyphProc* = proc(index: int, offset: var fmath.Vec2, color: var Color, draw: var bool)

proc toVAlign(align: Align): pixie.VerticalAlignment {.inline.} =
  return if asBot in align and asTop in align: pixie.MiddleAlign
  elif asBot in align: pixie.BottomAlign
  elif asTop in align: pixie.TopAlign
  else: pixie.MiddleAlign

proc toHAlign(align: Align): pixie.HorizontalAlignment {.inline.} =
  return if asLeft in align and asRight in align: pixie.CenterAlign
  elif asLeft in align: pixie.LeftAlign
  elif asRight in align: pixie.RightAlign
  else: pixie.CenterAlign

#TODO yikes, scary proc
proc outline(image: Image, color: chroma.ColorRGBA, diagonal: bool) =
  const
    d4 = @[(1, 0), (0, 1), (-1, 0), (0, -1)]
    d8 = @[(1, 0), (0, 1), (-1, 0), (0, -1), (1, 1), (-1, 1), (-1, -1), (1, -1)]

  let par = if diagonal.not: d4 else: d8

  let copy = image.copy()
  for x in 0..<copy.width:
    for y in 0..<copy.height:
      if copy[x, y].a < 128:
        var found = false
        for (dx, dy) in par:
          let 
            wx = x + dx
            wy = y + dy
          
          if wx >= 0 and wy >= 0 and wx < copy.width and wy < copy.height:
            if copy[wx, wy].a > 128:
              found = true
              break
        
        if found:
          image[x, y] = color

proc getGlyphImage(font: pixie.Font, r: Rune, outline: bool, outlineColor: Color, diagonalOutline: bool): (Image, fmath.Vec2) =
  var path = font.typeface.getGlyphPath(r)
  path.transform(vmath.scale(vmath.vec2(font.scale)))
  let bounds = path.computeBounds()
  #no path found
  if bounds.w < 1 or bounds.h < 1: return
  let bxy = -bounds.xy
  let sizeOffset = if outline: 4 else: 0
  result[0] = newImage(bounds.w.int + sizeOffset, bounds.h.int + sizeOffset)
  result[0].fillPath(path, chroma.rgba(255, 255, 255, 255), pixie.translate(bxy + vmath.vec2(if outline: sizeOffset.float32 / 2f else: 0f)))
  #TODO this method of outlining only works for pixel fonts. there's almost certainly a better way
  if outline: result[0].outline(cast[chroma.ColorRGBA](outlineColor), diagonalOutline)
  result[1] = fmath.vec2(bounds.xy) + fmath.vec2(if outline: -(sizeOffset.float32 / 2f) else: 0f)

proc `==`*(a, b: Rune): bool {.inline.} = a.int32 == b.int32

proc loadFont*(path: static[string], size: float32 = 16f, textureSize = 256, outline = false, outlineColor = colorBlack, diagonalOutline = true): Font =
  var font = pixie.newFont(pixie.parseTtf(assetReadStatic(path)))

  font.size = size

  result = Font(font: font, patches: initTable[Rune, Patch]())

  let packer = newTexturePacker(fmath.vec2i(textureSize, textureSize))

  #load standard latin characters
  for ch in 0x0020'u16..0x00FF'u16:
    let code = Rune(ch)

    let (image, offset) = font.getGlyphImage(code, outline, outlineColor, diagonalOutline)
    if image.isNil: continue

    let patch = packer.pack(image)
    result.patches[code] = patch
    result.offsets[code] = offset

  packer.update()

#return (color, length)
proc parseTag(text: string, start: int): (Color, int) =
  case text[start]:
  of ']': return (colorWhite, 1) #this means '[]', or the white color
  of '#': #color tag
    {.push checks: off}
    
    # Parse hex color RRGGBBAA where AA is optional and defaults to 0xFF if less than 6 chars are used.
    var colorInt = 0'u32;
    for i in (start + 1)..<text.len:
      let ch = text[i]

      if ch == ']':
        if i < start + 2 or i > start + 9 or i == start + 8: 
          break

        if i - start <= 7: # RRGGBB or fewer chars.
          var 
            ii = 0
            nn = 9 - (i - start)
          while ii < nn:
            colorInt = colorInt shl 4
            ii.inc

          colorInt = colorInt or 0xff
        
        return (colorInt.rgbaToColor, i - start + 1)
      
      if ch >= '0' and ch <= '9': colorInt = colorInt * 16 + (ch.uint32 - '0'.uint32)
      elif ch >= 'a' and ch <= 'f': colorInt = colorInt * 16 + (ch.uint32 - ('a'.uint32 - 10))
      elif ch >= 'A' and ch <= 'F': colorInt = colorInt * 16 + (ch.uint32 - ('A'.uint32 - 10))
      else: break #Unexpected character in hex color.
    
    return (colorWhite, -1)

    {.pop.}
  #invalid (custom color names not supported)
  else: return (colorWhite, -1)

#returns (displayed string, seq[(color, startPos)])
proc parseMarkup(text: string): (string, seq[(Color, int)]) =
  var 
    i = 0
    builder = newStringOfCap(text.len)
    tags: seq[(Color, int)]
    lastPos = -1

  while i < text.len:
    #parse tag
    if i < text.len - 1 and text[i] == '[' and text[i + 1] != '[' and (i == 0 or text[i - 1] != '['):
      let (color, len) = parseTag(text, i + 1)

      if len > 0:
        i += len + 1
        if lastPos != builder.len:
          tags.add (color, builder.len)
          lastPos = builder.len
        else:
          #special case: there are two tags right next to each other with no spacing, overwrite the head tag
          tags[^1] = (color, builder.len)
        continue
    
    builder &= text[i]
    i.inc
  
  return (builder, tags)

proc draw*(font: Font, text: string, pos: fmath.Vec2, scale: float32 = fau.pixelScl, bounds = fmath.vec2(0, 0), color: Color = rgba(1, 1, 1, 1), align: Align = daCenter, z: float32 = 0.0, modifier: GlyphProc = nil, markup = false) =
  var 
    plainText: string
    colors: seq[(Color, int)]

  if markup:
    (plainText, colors) = parseMarkup(text)
  else:
    plainText = text
  
  let arrangement = font.font.typeset(plainText, hAlign = align.toHAlign, vAlign = align.toVAlign, bounds = vmath.vec2(bounds.x / scale, bounds.y / scale))

  #for markup state
  var 
    currentColor = color
    markupIndex = 0

  #TODO this will break with non-ASCII text immediately due to the markup parsing using byte indices
  for i, rune in arrangement.runes:
    let ch = arrangement.selectionRects[i]
    let p = arrangement.positions[i]

    if font.patches.hasKey(rune):
      let offset = font.offsets[rune]
      let patch = font.patches[rune]

      if colors.len > 0 and markupIndex < colors.len:
        let next = colors[markupIndex]
        #encountered the next color
        if i >= next[1]:
          currentColor = next[0]
          currentColor.a = color.a * currentColor.a
          markupIndex.inc

      var
        glyphIndex = i
        glyphOffset = fmath.vec2()
        glyphColor = currentColor
        glyphDraw = true

      if modifier != nil:
        modifier(glyphIndex, glyphOffset, glyphColor, glyphDraw)

      if glyphDraw:
        drawRect(patch,
          (p.x + offset.x) * scale + pos.x + glyphOffset.x,
          (bounds.y/scale + 1 - p.y - offset.y - patch.heightf) * scale + pos.y + glyphOffset.y,
          patch.widthf*scale, patch.heightf*scale, color = glyphColor, z = z
        )

proc draw*(font: Font, text: string, bounds: fmath.Rect, scale: float32 = fau.pixelScl, color: Color = rgba(1, 1, 1, 1), align: Align = daCenter, z: float32 = 0.0, modifier: GlyphProc = nil, markup = false) =
  draw(font, text, bounds.xy, scale, bounds.wh, color, align, z, modifier, markup)