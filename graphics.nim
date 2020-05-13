import core, gl, strutils

#basic camera
type Camera* = ref object
    x, y, w, h: float

#defines a texture region type
type Tex* = object
    x, y, w, h: int #TODO add reference to a texture

#defines a color
type Col* = object
    r*, g*, b*, a*: uint8 #TODO should be floats

#converts a hex string to a color
export parseHexInt
template `%`*(str: string): Col =
    Col(r: str[0..1].parseHexInt().uint8, g: str[2..3].parseHexInt().uint8, b: str[4..5].parseHexInt().uint8, a: 255)

# TODO move to other graphics file
#[

#graphics

proc `color=`*(core: Core, value: Col) {.inline.} =
    core.renderer.setDrawColor(value.r, value.g, value.b, value.a)

#returns a texture region by name
proc `$`*(core: Core, name: string): Tex = 
    return core.atlas.getOrDefault(name, core.atlas["error"])


#parse an atlas from a string
proc loadAtlas(atlas: string): Table[string, tuple[x: int, y: int, w: int, h: int]] =
    result = initTable[string, tuple[x: int, y: int, w: int, h: int]]()
    let lines = splitLines(atlas)
    var index = 6

    while index < lines.len - 1:
        #name of region
        var key = lines[index]
        index += 2
        #xy
        var numbers = lines[index]
        var x, y : int
        var xyoffset = "  xy: ".len
        xyoffset += numbers.parseInt(x, xyoffset)
        discard numbers.parseInt(y, xyoffset + 2)
        index += 1

        #size
        var sizes = lines[index]
        var width, height : int
        var sizeoffset = "  size: ".len
        sizeoffset += sizes.parseInt(width, sizeoffset)
        discard sizes.parseInt(height, sizeoffset + 2)
        index += 4

        result[key] = (x, y, width, height)

#loads 'sprites.atlas' into the core
#TODO: remove and load implicitly
proc createAtlas*(core: Core) =
    let atlasTex = core.renderer.loadTextureRW(staticReadRW(assetsFolder & "sprites.png"), freesrc = 1)
    let map = loadAtlas(staticReadString(assetsFolder & "sprites.atlas"))
    core.atlas = initTable[string, Tex]()
    for key, val in map.pairs:
        core.atlas[key] = Tex(texture: atlasTex, region: rect(val.x.cint, val.y.cint, val.w.cint, val.h.cint)) ]#