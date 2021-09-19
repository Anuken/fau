
import fmath, math, strutils

#defines a RGBA color
type Color* = object
  rv*, gv*, bv*, av*: uint8

#just incase something gets messed up somewhere
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

func rgba*(r: float32, g: float32, b: float32, a: float32 = 1.0): Color {.inline.} = Color(rv: (clamp(r.float32) * 255f).uint8, gv: (clamp(g) * 255f).uint8, bv: (clamp(b) * 255f).uint8, av: (clamp(a) * 255f).uint8)

func rgb*(r: float32, g: float32, b: float32): Color {.inline.} = rgba(r, g, b, 1f)

func rgb*(rgba: float32): Color {.inline.} = rgb(rgba, rgba, rgba)

func alpha*(a: float32): Color {.inline.} = rgba(1.0, 1.0, 1.0, a)

#H, S, V are all floats from 0 to 1
func hsv*(h, s, v: float32, a = 1f): Color =
  let 
    x = (h * 60f + 6f).mod(6f)
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

func `/`*(a, b: Color): Color {.inline.} = rgba(a.r / b.r, a.g / b.g, a.b / b.b, a.a / b.a)
func `/`*(a: Color, b: float32): Color {.inline.} = rgba(a.r / b, a.g / b, a.b / b, a.a)

func `*`*(a, b: Color): Color {.inline.} = rgba(a.r * b.r, a.g * b.g, a.b * b.b, a.a * b.a)
func `*`*(a: Color, b: float32): Color {.inline.} = rgba(a.r * b, a.g * b, a.b * b, a.a)

func `+`*(a, b: Color): Color {.inline.} = rgba(a.r + b.r, a.g + b.g, a.b + b.b, a.a + b.a)
func `+`*(a: Color, b: float32): Color {.inline.} = rgba(a.r + b, a.g + b, a.b + b, a.a)

proc mix*(color: Color, other: Color, alpha: float32): Color =
  let inv = 1.0 - alpha
  return rgba(color.r*inv + other.r*alpha, color.g*inv + other.g*alpha, color.b*inv + other.b*alpha, color.a*inv + other.a*alpha)

#converts a hex string to a color at compile-time; no overhead
export parseHexInt
template `%`*(str: static[string]): Color =
  const ret = Color(rv: str[0..1].parseHexInt.uint8, gv: str[2..3].parseHexInt.uint8, bv: str[4..5].parseHexInt.uint8, av: if str.len > 6: str[6..7].parseHexInt.uint8 else: 255'u8)
  ret

const
  colorClear* = rgba(0, 0, 0, 0)
  colorWhite* = rgb(1, 1, 1)
  colorBlack* = rgba(0, 0, 0)
  colorRoyal* = %"4169e1"
  colorCoral* = %"ff7f50"
  colorRed* = rgb(1, 0, 0)
  colorGreen* = rgb(0, 1, 0)
  colorBlue* = rgb(0, 0, 1)