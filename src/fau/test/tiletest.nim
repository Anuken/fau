import ../util/tiled, ../../core, tables, os

const
  speed = 2000f

var 
  map: Tilemap
  pos: Vec2
  zoom = 2f
  realZoom = zoom
  images: Table[string, Patch]
  path = "/home/anuke/Projects/Inferno/core/assets/maps"

proc img(tile: TiledTile): Patch = images[tile.image]

proc run =
  if keyEscape.tapped:
    quitApp()
  
  pos += axis2().nor() * fau.delta * speed
  zoom = clamp(zoom + fau.scroll.y * 0.1f * zoom, 0.2f, 5f)

  fau.cam.pos.lerp(pos, 10f * fau.delta)
  realZoom = realZoom.lerp(zoom, 20f * fau.delta)

  fau.cam.use(fau.size / realZoom)

  let size = vec2(map.tilewidth, map.tileheight)

  if fau.frameId mod 10 == 0:
    setWindowTitle($fau.fps & " FPS")

  for layer in map.layers:
    if layer.hasTiles:
      for x in 0..<map.width:
        for y in 0..<map.height:
          let tile = layer[x, y]
          if not tile.tile.empty:
            draw(tile.tile.img, vec2(x, y) * size, size = size * -vec2(tile.flipx.sign, tile.flipy.sign), rotation = 90f.rad * tile.flipDiag.float32)

    for obj in layer.objects:
      if not obj.tile.empty:
        draw(obj.tile.img, obj.pos + obj.size/2f, size = obj.size)

proc init =
  map = readTilemapFile(path / "map.tmj")
  for tileset in map.tilesets:
    for tile in tileset.tiles:
      if not images.hasKey(tile.image):
        images[tile.image] = loadTextureFile(path / tile.image)

initFau(run, init, initParams(title = "Tiled Test"))