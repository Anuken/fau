
import strformat, tables, texture, patch, assets, streams, fmath, color, util/misc, threading

#A single-texture atlas.
type Atlas* = ref object
  patches*: Table[string, Patch]
  patches9*: Table[string, Patch9]
  durations*: Table[string, int]
  textures*: seq[Texture]
  error*: Patch
  error9*: Patch9

proc newEmptyAtlas*(): Atlas =
  result = Atlas(textures: @[newTexture(vec2i(1))])

  let color = colorWhite
  result.textures[0].load(vec2i(1), addr color)
  
  result.error = newPatch(result.textures[0], 0, 0, 1, 1)
  result.error9 = newPatch9(result.error, 0, 0, 0, 0)
  result.patches["white"] = result.error

proc getImageCount*(path: static[string]): int {.compileTime.} =
  #TODO: horribly inefficient. I only need to read a single byte!
  const dataPath = "assets/" & path & ".dat"
  const data = readFile(dataPath)
  result = cast[uint8](data[0]).int

#Loads an atlas from static resources.
proc loadAtlas*(path: static[string]): Atlas =
  result = Atlas()
  
  const imageCountConst = getImageCount(path)

  let stream = assetStaticStream(path & ".dat")

  #number of images - ignored because it's read at compile time
  discard stream.readUint8()

  var 
    dataPointers: array[imageCountConst, RawImage]
    exec = createMaster()
  
  exec.awaitAll:
    var img = 0 #this is awful and pointless but the compiler yells at me if I don't put it here. it gets shadowed anyway
    unroll(0..<imageCountConst, img):
      
      let 
        amount = stream.readInt32()
        #TODO: add later
        texWidth = stream.readInt16()
        texHeight = stream.readInt16()
      
      let texture = newTexture(vec2i(texWidth.int, texHeight.int))
      result.textures.add texture
      
      for i in 0..<amount:
        let 
          nameLen = stream.readInt16()
          name = stream.readStr(nameLen)
          x = stream.readInt16()
          y = stream.readInt16()
          width = stream.readInt16()
          height = stream.readInt16()
          hasSplit = stream.readBool()
          patch = newPatch(texture, x, y, width, height)

        if hasSplit:
          let
            left = stream.readInt16()
            right = stream.readInt16()
            top = stream.readInt16()
            bot = stream.readInt16()

          result.patches9[name] = newPatch9(patch, left, right, top, bot)
        
        let duration = stream.readUint16()

        if duration != 0'u16:
          result.durations[name] = duration.int

        result.patches[name] = patch
      
      const imgPath = path & $img & ".png"
      exec.spawn loadRawImage(imgPath) -> dataPointers[img]

  stream.close()

  for i, texture in result.textures:
    texture.load(texture.size, dataPointers[i].data)
    freeRawImage(dataPointers[i])

  result.error = result.patches["error"]
  result.error9 = newPatch9(result.patches["error"], 0, 0, 0, 0)

# accesses a region from an atlas
proc `[]`*(atlas: Atlas, name: string): Patch {.inline.} = atlas.patches.getOrDefault(name, atlas.error)

# get frame duration in ms
proc getDuration*(atlas: Atlas, name: string): int {.inline.} = atlas.durations.getOrDefault(name, 0)

