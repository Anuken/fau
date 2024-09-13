
import fmath, math, strutils, endians

#defines a RGBA color
type Color* = object
  rv*, gv*, bv*, av*: uint8

#just in case something gets messed up somewhere
static: assert sizeof(Color) == 4, "Size of Color must be 4 bytes, but is " & $sizeof(Color)

#float accessors for colors
func r*(col: Color): float32 {.inline.} = col.rv.float32 / 255f
func g*(col: Color): float32 {.inline.} = col.gv.float32 / 255f
func b*(col: Color): float32 {.inline.} = col.bv.float32 / 255f
func a*(col: Color): float32 {.inline.} = col.av.float32 / 255f

#float setters for colors
func `r=`*(col: var Color, val: float32) {.inline.} = col.rv = clamp(val * 255f, 0, 255f).uint8
func `g=`*(col: var Color, val: float32) {.inline.} = col.gv = clamp(val * 255f, 0, 255f).uint8
func `b=`*(col: var Color, val: float32) {.inline.} = col.bv = clamp(val * 255f, 0, 255f).uint8
func `a=`*(col: var Color, val: float32) {.inline.} = col.av = clamp(val * 255f, 0, 255f).uint8

func withA*(col: Color, val: float32): Color {.inline.} =
  result = col
  result.a = val

func mulA*(col: Color, val: float32): Color {.inline.} =
  result = col
  result.a = result.a * val 

func rgba*(r: float32, g: float32, b: float32, a: float32 = 1.0): Color {.inline.} = Color(rv: (clamp(r.float32) * 255f).uint8, gv: (clamp(g) * 255f).uint8, bv: (clamp(b) * 255f).uint8, av: (clamp(a) * 255f).uint8)

func rgb*(r: float32, g: float32, b: float32): Color {.inline.} = rgba(r, g, b, 1f)

func rgb*(rgba: float32): Color {.inline.} = rgb(rgba, rgba, rgba)

func alpha*(a: float32): Color {.inline.} = rgba(1.0, 1.0, 1.0, a)

func gray*(g: float32): Color {.inline.} = rgb(g, g, g)

#H, S, V are all floats from 0 to 1
func hsv*(h, s, v: float32, a = 1f): Color =
  let 
    x = (h * 6f + 6f).mod(6f)
    i = x.floor
    f = x - i
    p = v * (1 - s)
    q = v * (1 - s * f)
    t = v * (1 - s * (1 - f))
  
  return case i
  of 0: rgba(v, t, p, a)
  of 1: rgba(q, v, p, a)
  of 2: rgba(p, v, t, a)
  of 3: rgba(p, q, v, a)
  of 4: rgba(t, p, v, a)
  else: rgba(v, p, q, a)

func toHsv(color: Color): tuple[h: float32, s: float32, v: float32] =
  let max = max(max(color.r, color.g), color.b)
  let min = min(min(color.r, color.g),color.b)
  let ran = max - min

  if ran == 0f:
    result[0] = 0f
  elif max == color.r:
    result[0] = (60f * (color.g - color.b) / ran + 360) mod 360f
  elif max == color.g:
    result[0] = 60f * (color.b - color.r) / ran + 120f
  else:
    result[0] = 60f * (color.r - color.g) / ran + 240f

  if max > 0:
    result[1] = 1 - min / max
  else:
    result[1] = 0;
  
  result[0] /= 360f
  
  result[2] = max

func shiftHsv*(color: Color, h = 0f, s = 0f, v = 0f): Color =
  var hsv = color.toHsv()
  hsv[0] = emod(hsv[0] + h, 1f)
  hsv[1] = clamp(hsv[1] + s)
  hsv[2] = clamp(hsv[2] + v)
  return hsv(hsv[0], hsv[1], hsv[2], color.a)

func `/`*(a, b: Color): Color {.inline.} = rgba(a.r / b.r, a.g / b.g, a.b / b.b, a.a / b.a)
func `/`*(a: Color, b: float32): Color {.inline.} = rgba(a.r / b, a.g / b, a.b / b, a.a)

func `*`*(a, b: Color): Color {.inline.} = rgba(a.r * b.r, a.g * b.g, a.b * b.b, a.a * b.a)
func `*`*(a: Color, b: float32): Color {.inline.} = rgba(a.r * b, a.g * b, a.b * b, a.a)

func `+`*(a, b: Color): Color {.inline.} = rgba(a.r + b.r, a.g + b.g, a.b + b.b, a.a + b.a)
func `+`*(a: Color, b: float32): Color {.inline.} = rgba(a.r + b, a.g + b, a.b + b, a.a)

proc rgbaToColor*(val: uint32): Color =
  var reversed = val
  swapEndian32(addr reversed, addr val)
  return cast[Color](reversed)

proc mix*(color: Color, other: Color, alpha: float32): Color =
  let inv = 1.0 - alpha
  return rgba(color.r*inv + other.r*alpha, color.g*inv + other.g*alpha, color.b*inv + other.b*alpha, color.a*inv + other.a*alpha)

#colors have limited precision, don't use this.
#proc mix*(color: var Color, other: Color, alpha: float32) = 
#  let inv = 1.0 - alpha
#  color = rgba(color.r*inv + other.r*alpha, color.g*inv + other.g*alpha, color.b*inv + other.b*alpha, color.a*inv + other.a*alpha)

#converts a hex string to a color at compile-time; no overhead
export parseHexInt
template `%`*(str: static[string]): Color =
  const ret = Color(rv: str[0..1].parseHexInt.uint8, gv: str[2..3].parseHexInt.uint8, bv: str[4..5].parseHexInt.uint8, av: if str.len > 6: str[6..7].parseHexInt.uint8 else: 255'u8)
  ret

proc parseColor*(str: string): Color =
  let offset = if str.len > 0 and str[0] == '#': 1 else: 0
  if str.len - offset < 6: return Color()

  Color(
    rv: str[(0+offset)..(1+offset)].parseHexInt.uint8, 
    gv: str[(2+offset)..(3+offset)].parseHexInt.uint8, 
    bv: str[(4+offset)..(5+offset)].parseHexInt.uint8, 
    av: if str.len > 6 + offset: str[(6+offset)..(7+offset)].parseHexInt.uint8 else: 255'u8
  )

proc `$`*(color: Color): string = toHex(cast[uint32]((color.rv.uint32 shl 24) or (color.gv.uint32 shl 16) or (color.bv.uint32 shl 8) or color.av))

const
  colorClear* = rgba(0, 0, 0, 0)
  colorClearWhite* = rgba(1f, 1f, 1f, 0f)
  colorWhite* = rgb(1, 1, 1)
  colorBlack* = rgba(0, 0, 0)
  colorGray* = rgb(0.5f, 0.5f, 0.5f)
  colorRoyal* = %"4169e1"
  colorCoral* = %"ff7f50"
  colorOrange* = %"ffa500"
  colorRed* = rgb(1, 0, 0)
  colorMagenta* = rgb(1, 0, 1)
  colorPurple* = %"a020f0"
  colorGreen* = rgb(0, 1, 0)
  colorBlue* = rgb(0, 0, 1)
  colorPink* = %"ff69b4"
  colorYellow* = %"ffff00"