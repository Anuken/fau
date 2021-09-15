
import strformat

#Loads an atlas from static resources.
proc loadAtlasStatic*(path: static[string]): Atlas =
  result = Atlas()

  const dataPath = path & ".dat"
  const pngPath = path & ".png"
  
  result.texture = loadTextureStatic(pngPath)

  let stream = staticReadStream(dataPath)

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
      patch = newPatch(result.texture, x, y, width, height)

    if hasSplit:
      let
        left = stream.readInt16()
        right = stream.readInt16()
        top = stream.readInt16()
        bot = stream.readInt16()

      result.patches9[name] = newPatch9(patch, left, right, top, bot)

    result.patches[name] = patch

  stream.close()

  result.error = result.patches["error"]
  result.error9 = newPatch9(result.patches["error"], 0, 0, 0, 0)

# accesses a region from an atlas
proc `[]`*(atlas: Atlas, name: string): Patch {.inline.} = atlas.patches.getOrDefault(name, atlas.error)

proc patch*(name: string): Patch {.inline.} = fau.atlas[name]

proc patch9*(name: string): Patch9 {.inline.} = fau.atlas.patches9.getOrDefault(name, fau.atlas.error9)