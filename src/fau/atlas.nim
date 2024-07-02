
import strformat, tables, texture, patch, assets, streams, fmath, color

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

#Loads an atlas from static resources.
proc loadAtlas*(path: static[string]): Atlas =
  result = Atlas()

  let mainTex = loadTexture(path & ".png")
  
  result.textures = @[mainTex]
  let stream = assetStaticStream(path & ".dat")

  let amount = stream.readInt32()
  for i in 0..<amount:
    let 
      nameLen = stream.readInt16()
      name = stream.readStr(nameLen)
      x = stream.readInt16()
      y = stream.readInt16()
      width = stream.readInt16()
      height = stream.readInt16()
      hasSplit = stream.readBool()
      patch = newPatch(mainTex, x, y, width, height)

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

  stream.close()

  result.error = result.patches["error"]
  result.error9 = newPatch9(result.patches["error"], 0, 0, 0, 0)

# accesses a region from an atlas
proc `[]`*(atlas: Atlas, name: string): Patch {.inline.} = atlas.patches.getOrDefault(name, atlas.error)

# get frame duration in ms
proc getDuration*(atlas: Atlas, name: string): int {.inline.} = atlas.durations.getOrDefault(name, 0)

