import jsony, parseutils, tables, zippy, base64, ../fmath, ../assets, ../color

type
  TilePropKind* = enum
    tpString, tpInt, tpFloat, tpBool, tpColor

  TileProp* = object
    case kind*: TilePropKind
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
      
  TiledProps* = TableRef[string, TileProp]

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
    image*, name*: string
    imagewidth*, imageheight*: int
    tilewidth*, tileheight*, columns*, margin*, spacing*: int
    tiles*: seq[TiledTile]
    properties*: TiledProps
    #internal
    firstgid: int
    source: string
    tilecount: int

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
    emptyTile*: TiledTile

proc parseHook*(s: string, i: var int, v: var TiledProps) =
  #internal type for parsing property entries, as they are in a list, not a map
  type TilePropEntry = object
    name: string
    `type`: string
    value: RawJson

  var entries: seq[TilePropEntry]

  parseHook(s, i, entries)

  v = newTable[string, TileProp]()

  proc parseInt(s: string): int =
    var i: int
    discard parseInt(s, i)
    return i

  proc parseFloat(s: string): float =
    var i: float
    discard parseFloat(s, i)
    return i
  
  for i, entry in entries:
    let str = entry.value.string
    
    v[entry.name] = case entry.`type`:
    of "string", "file", "": TileProp(kind: tpString, strVal: str[1..^2])
    of "int": TileProp(kind: tpInt, intVal: str.parseInt())
    of "float": TileProp(kind: tpFloat, floatVal: str.parseFloat())
    of "bool": TileProp(kind: tpBool, boolVal: str == "true")
    of "color":
      var color = str[1..^2].parseColor
      let a = color.rv
      color.rv = color.gv
      color.gv = color.bv
      color.bv = color.av
      color.av = a
      #what the hell, tiled? who stores hex colors in #AARRGGBB format?
      TileProp(kind: tpColor, colorVal: color)
    else: TileProp()
  
proc postHook*(map: var Tilemap) =
  var gidToTile = initTable[int, TiledTile]()

  #empty tile
  gidToTile[0] = TiledTile(empty: true)
  map.emptyTile = gidToTile[0]

  for tileset in map.tilesets:
    if tileset.source != "":
      raise Exception.newException("Tilesets must be embedded in the file, not external (" & tileset.source & ")")
    
    #import tiles by splitting image
    if tileset.columns > 0 and tileset.imagewidth > 0:
      var idToTile = initTable[int, TiledTile]()

      for prevTile in tileset.tiles:
        idToTile[prevTile.id] = prevTile
      
      #clear old tiles (parsed with properties)
      tileset.tiles.setLen(0)

      var curId = 0
      let tilesY = (tileset.imageheight - tileset.margin * 2) div (tileset.tileheight + tileset.spacing)

      for gridY in 0..<tilesY:
        for gridX in 0..<tileset.columns:

          var tile = TiledTile(
            id: curId,
            imagewidth: tileset.imagewidth,
            imageheight: tileset.imageheight,
            x: gridX * (tileset.tilewidth + tileset.spacing),
            y: gridY * (tileset.tileheight + tileset.spacing),
            width: tileset.tilewidth,
            height: tileset.tileheight,
            image: tileset.image, #TODO is this necessary...?
          )

          #inherit properties
          idToTile.withValue(curId, oldTile):
            tile.properties = oldTile.properties

          tileset.tiles.add(tile)

          curId.inc
    
    for tile in tileset.tiles:
      tile.id += tileset.firstgid
      gidToTile[tile.id] = tile

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

# TiledProps CAN BE NIL. Why? Because ensuring that it isn't, or making it a Table (non-ref) crashes emscripten.

proc contains*(props: TiledProps, key: string): bool = not props.isNil and props.hasKey(key)

proc getInt*(props: TiledProps, name: string, def = 0): int =
  if props.isNil: return def
  let p = props.getOrDefault(name, TileProp(kind: tpInt, intVal: def))
  result = def
  if p.kind == tpInt: return p.intVal

proc getFloat*(props: TiledProps, name: string, def = 0f): float =
  if props.isNil: return def
  let p = props.getOrDefault(name, TileProp(kind: tpFloat, floatVal: def))
  result = def
  if p.kind == tpFloat: return p.floatVal

proc getString*(props: TiledProps, name: string, def = ""): string =
  if props.isNil: return def
  let p = props.getOrDefault(name, TileProp(kind: tpString, strVal: def))
  result = def
  if p.kind == tpString: return p.strVal

proc getBool*(props: TiledProps, name: string, def = false): bool =
  if props.isNil: return def
  let p = props.getOrDefault(name, TileProp(kind: tpBool, boolVal: def))
  result = def
  if p.kind == tpBool: return p.boolVal

proc getColor*(props: TiledProps, name: string, def = colorWhite): Color =
  if props.isNil: return def
  let p = props.getOrDefault(name, TileProp(kind: tpColor, colorVal: def))
  result = def
  if p.kind == tpColor: return p.colorVal

proc contains*(layer: TileLayer, x, y: int): bool =
  return not(x < 0 or y < 0 or x >= layer.width or y >= layer.height)

proc contains*(layer: TileLayer, xy: Vec2i): bool {.inline.} = contains(layer, xy.x, xy.y)

proc `[]=`*(layer: TileLayer, x, y: int, tile: TiledTile) {.inline.} =
  if not layer.contains(x, y): return

  layer.tiles[x + y * layer.width].tile = tile

proc `[]=`*(layer: TileLayer, pos: Vec2i, tile: TiledTile) {.inline.} =
  layer[pos.x, pos.y] = tile

proc `[]`*(layer: TileLayer, x, y: int): TileCell {.inline.} =
  if not layer.contains(x, y):
    raise IndexDefect.newException("Out of tile map bounds: " & $x & ", " & $y)

  layer.tiles[x + y * layer.width]

proc `[]`*(layer: TileLayer, pos: Vec2i): TileCell {.inline.} = layer[pos.x, pos.y]

proc hasLayer*(map: Tilemap, name: string): bool =
  for layer in map.layers:
    if layer.name == name:
      return true
  return false

proc findLayer*(map: Tilemap, name: string): TileLayer =
  for layer in map.layers:
    if layer.name == name:
      return layer
  #TODO how
  raise Defect.newException("Layer not found: " & $name)

proc size*(map: Tilemap): Vec2i = vec2i(map.width, map.height)

proc readTilemapString*(str: string): Tilemap = str.fromJson(Tilemap)

proc readTilemapFile*(file: string): Tilemap = file.readFile().readTilemapString()

proc readTilemapAsset*(file: static string): Tilemap = assetReadStatic(file).readTilemapString()

when isMainModule:
  import print

  print readTilemapFile("/home/anuke/Projects/Inferno/core/assets/maps/map.tmj")