import jsony, tables, ../color, parseutils, zippy, base64, ../fmath

type
  TilePropKind* = enum
    tpString, tpInt, tpFloat, tpBool, tpColor
  TileProp* = object
    case kind: TilePropKind
    of tpString: 
      strVal*: string
    of tpInt: 
      intVal*: int
    of tpFloat: 
      floatVal*: float
    of tpBool: 
      boolVal*: bool
    of tpColor:
      colorVal*: Color
  TiledProps* = Table[string, TileProp]
  TiledTile* = ref object
    id*: int #an ID of 0 indicates an empty tile
    imagewidth*, imageheight*: int
    x*, y*, width*, height*: int
    empty*: bool
    image*: string
    properties*: TiledProps
  TileCell* = object
    tile*: TiledTile
    flipx*, flipy*, flipdiag*: bool
  TiledObject* = ref object
    class*, name*: string
    id*: int
    rotation*: float32
    pos*, size*: Vec2
    visible*: bool
    ellipse*, point*: bool
    polygon*, polyline*: seq[Vec2]
    properties*: TiledProps
    tile*: TiledTile

    #internal
    gid: int
    x, y, width, height: float32
  Tileset* = ref object
    image*: string
    imagewidth*, imageheight*: string
    source*: string
    tiles*: seq[TiledTile]
    properties*: TiledProps

    #internal
    firstgid: int
  TileLayer* = ref object
    name*: string
    properties*: TiledProps
    width*, height*: int
    hasTiles*: bool
    tiles*: seq[TileCell]
    objects*: seq[TiledObject]

    #internal
    data: string
    encoding: string
    compression: string
  Tilemap* = ref object
    width*, height*: int
    tilewidth*, tileheight*: int
    layers*: seq[TileLayer]
    tilesets*: seq[Tileset]
    properties*: TiledProps

#internal type for parsing property entries, as they are in a list, not a map
type TilePropEntry = object
  name: string
  `type`: string
  value: string

proc parseHook*(s: string, i: var int, v: var TiledProps) =
  v = initTable[string, TileProp]()

  var entries: seq[TilePropEntry]

  parseHook(s, i, entries)

  for entry in entries:
    v[entry.name] = case entry.`type`:
    of "string", "": TileProp(kind: tpString, strVal: entry.value)
    of "int":
      var res = 0
      discard parseInt(entry.value, res)
      TileProp(kind: tpInt, intVal: res)
    of "float": 
      var res: float = 0f
      discard parseFloat(entry.value, res)
      TileProp(kind: tpFloat, floatVal: res)
    of "bool": 
      TileProp(kind: tpBool, boolVal: entry.value == "true")
    of "color":
      TileProp(kind: tpColor, colorVal: entry.value.parseColor)
    else:
      TileProp()

proc postHook*(map: var Tilemap) =
  var gidToTile = initTable[int, TiledTile]()

  #empty tile
  gidToTile[0] = TiledTile(empty: true)

  for tileset in map.tilesets:
    for tile in tileset.tiles:
      gidToTile[tile.id + tileset.firstgid] = tile

  #actually load tile data from layers in post
  for layer in map.layers:
    for obj in layer.objects:
      obj.tile = gidToTile[obj.gid]
      obj.pos = vec2(obj.x, map.height * map.tileheight - obj.y)
      obj.size = vec2(obj.width, obj.height)

    if layer.data != "":

      if layer.encoding != "base64":
        raise Exception.newException("Tilemaps must use base64 encoding instead of CSV, CSV tile data is massive (check map settings)")

      let 
        decoded = decode(layer.data)
        decompressed = if layer.compression == "": decoded else: uncompress(decoded)
        numTiles = decompressed.len div 4
        intData = cast[ptr UncheckedArray[uint32]](addr decompressed[0])
      
      layer.tiles = newSeq[TileCell](numTiles)

      for i in 0..<numTiles:
        let 
          packedGid = intData[i]
          flipHorizontal = (packedGid and 0x80000000'u32) != 0
          flipVertical = (packedGid and 0x40000000'u32) != 0
          flipDiag = (packedGid and 0x20000000'u32) != 0
          tileId = packedGid and (not 0xf0000000'u32)

          x = i mod layer.width
          y = i div layer.width

        layer.tiles[x + (layer.height - 1 - y) * layer.width] = TileCell(
          tile: gidToTile[tileId.int],
          flipx: flipHorizontal,
          flipy: flipVertical,
          flipdiag: flipDiag
        )

      #dealloc useless data
      layer.data = ""
    
    layer.hasTiles = layer.tiles.len > 0

proc getInt*(props: TiledProps, name: string): int =
  let p = props.getOrDefault(name, TileProp())
  if p.kind == tpInt: return p.intVal

proc getFloat*(props: TiledProps, name: string): float =
  let p = props.getOrDefault(name, TileProp())
  if p.kind == tpFloat: return p.floatVal

proc getString*(props: TiledProps, name: string): string =
  let p = props.getOrDefault(name, TileProp())
  if p.kind == tpString: return p.strVal

proc getBool*(props: TiledProps, name: string): bool =
  let p = props.getOrDefault(name, TileProp())
  if p.kind == tpBool: return p.boolVal

proc `[]`*(layer: TileLayer, x, y: int): TileCell =
  if x < 0 or y < 0 or x >= layer.width or y >= layer.height:
    raise IndexDefect.newException("Out of tile map bounds: " & $x & ", " & $y)

  layer.tiles[x + y * layer.width]

proc readTilemapFile*(file: string): Tilemap = file.readFile().fromJson(Tilemap)

proc readTilemapString*(str: string): Tilemap = str.fromJson(Tilemap)

when isMainModule:
  import print

  print readTilemapFile("/home/anuke/Projects/Inferno/core/assets/maps/map.tmj")