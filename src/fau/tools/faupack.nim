import ../g2/packer, ../util/[aseprite, tiled]
import std/[os, algorithm, strformat, tables, math, streams, times, strutils]
import pkg/[pixie, jsony, chroma]

type FolderSettings = object
  outlineColor: ColorRGBA
  pad: int = -1
  bleed: int = -1
  minSize: int = -1
  maxSize: int = -1
  separate: bool = false

  #private state
  imageIndex: int
  packer: Packer

type PackEntry = tuple[
  image: Image, 
  file: string, 
  pos: tuple[x, y: int], 
  splits: array[4, int], 
  duration: int, 
  settings: FolderSettings
]

from vmath import nil

proc parseHook*(s: string, i: var int, v: var ColorRGBA) =
  var str: string
  parseHook(s, i, str)
  v = str.parseHex.rgba

proc fail(reason: string) = raise Exception.newException(reason)

proc outline(image: Image, color: ColorRGBA) =
  let copy = image.copy()
  for x in 0..<copy.width:
    for y in 0..<copy.height:
      if copy[x, y].a == 0:
        var found = false
        for (dx, dy) in [(1, 0), (0, 1), (-1, 0), (0, -1)]:
          let 
            wx = x + dx
            wy = y + dy
          
          if wx >= 0 and wy >= 0 and wx < copy.width and wy < copy.height:
            let other = copy[wx, wy]
            if other.a != 0 and other != color:
              found = true
              break
        
        if found:
          image[x, y] = color

proc getImageSize(file: string): tuple[w: int, h: int] =
  var bytes: array[24, uint8]
  var outp: seq[uint8]

  #TODO must be a better way to read an int from a file
  let f = open(file)
  discard readBytes(f, bytes, 0, bytes.len)
  close(f)

  if file.splitFile.ext == ".png":
    outp = bytes[16..19]
    reverse(outp)
    let w = cast[ptr int32](addr outp[0])[]
    outp = bytes[20..23]
    reverse(outp)
    let h = cast[ptr int32](addr outp[0])[]
    return (w.int, h.int)
  elif file.splitFile.ext == ".aseprite":
    outp = bytes[8..9]
    let w = cast[ptr uint16](addr outp[0])[]
    outp = bytes[10..11]
    let h = cast[ptr uint16](addr outp[0])[]
    return (w.int, h.int)

#TODO: should be in pack.json, not parameters
proc packImages(path: string, output: string = "atlas", tilemapFolder = "", verbose = false, silent = false) =
  let 
    time = cpuTime()
    #packer = newPacker(min, min)
    blackRgba = rgba(0, 0, 0, 255)
  
  var 
    #page index -> packer
    packers: seq[Packer]
    #maps image name -> pack data
    positions = initTable[string, PackEntry]()
    #maps image index -> list of entries of that image
    positionsByImage: seq[seq[PackEntry]]
    #maps folder name -> settings
    settings = initTable[string, FolderSettings]()
    #this is overwritten by a call later on, but the default values are still used once
    defaultSettings = FolderSettings(minSize: 64, maxSize: 2048, pad: 0, bleed: 2)
  
  proc applyDefaults(settings: var FolderSettings) =
    if settings.bleed < 0: settings.bleed = defaultSettings.bleed
    if settings.pad < 0: settings.pad = defaultSettings.pad
    if settings.minSize < 0: settings.minSize = defaultSettings.minSize
    if settings.maxSize < 0: settings.maxSize = defaultSettings.maxSize

    if settings.separate:
      #separate image, make a new packer
      settings.packer = newPacker(settings.minSize, settings.minSize)
      settings.imageIndex = packers.len
      packers.add settings.packer
    elif settings.packer == nil: #unassigned (default) packer
      if packers.len == 0:
        #initialize the first packer, special case
        settings.packer = newPacker(settings.minSize, settings.minSize)
        packers.add settings.packer
      else:
        #use the first main packer
        settings.packer = packers[0]
  
  proc getSettings(file: string): FolderSettings =
    let parent = file.parentDir
    
    settings.withValue(parent, value):
      return value[]
    do:
      let settingsFile = parent / "folder.json"
      if settingsFile.fileExists:
        try:
          var res = settingsFile.readFile.fromJson(FolderSettings)
          applyDefaults(res)
          settings[parent] = res
          return res
        except CatchableError as e:
          echo "Error reading settings file ", settingsFile, " ", e.msg
      elif parent != path and parent != "" and parent != ".": #recursively fetch settings of parent directory until path is reached
        let parentSettings = getSettings(parent)
        settings[parent] = parentSettings
        return parentSettings
      
      #default value
      result = FolderSettings()
      applyDefaults(result)
      settings[parent] = result

  #this MUST be called before any packing is done, as it reads the settings file in the main folder and creates a packer for it
  defaultSettings = getSettings(path / "pointless.png")

  proc packFile(file: string, image: Image, splits = [-1, -1, -1, -1], duration = 0, realFile = file) =
    let 
      settings = getSettings(realFile)
      name = file.splitFile.name
      bleed = settings.bleed
      pad = settings.pad
      packer = settings.packer

    if settings.outlineColor.a > 0:
      outline(image, settings.outlineColor)

    if verbose: echo &"Packing image {name}..."

    if positions.hasKey(name): 
      fail &"Duplicate image names: '{file}' and '{positions[name].file}'"

    if image.width >= settings.maxSize or image.height >= settings.maxSize:
      fail &"Image '{file}' is too large to fit in this atlas ({image.width}x{image.height}). Increase the max atlas size."
    
    var pos: tuple[x, y: int] = (-1, -1)

    #keep trying to pack and resize until packer runs out of space.
    while pos == (-1, -1):
      pos = packer.pack(image.width, image.height, padding = bleed + pad)
      if pos == (-1, -1):
        let increaseWidth = packer.w <= packer.h

        if packer.w >= settings.maxSize and increaseWidth:
          fail &"Failed to fit images into {settings.maxSize}x{settings.maxSize} texture. Last image packed: {file}"
        
        if increaseWidth:
          packer.resize((packer.w + 1).nextPowerOfTwo, packer.h)
        else:
          packer.resize(packer.w, (packer.h + 1).nextPowerOfTwo)
    
    if positionsByImage.len <= settings.imageIndex:
      positionsByImage.setLen(max(positionsByImage.len, settings.imageIndex + 1))
    
    let entry = (image, file, pos, splits, duration, settings)
    positions[name] = entry
    positionsByImage[settings.imageIndex].add entry

  type PackEntry = tuple[file: string, size: int]
  var toPack: seq[PackEntry]

  #pack tilemap tiles
  if tilemapFolder != "":
    for file in walkDirRec(tilemapFolder):
      let split = file.splitFile
      if split.ext == ".tmj":
        try:
          let tilemap = readTilemapFile(file)
          for tileset in tilemap.tilesets:
            var images: Table[string, Image]
            if tileset.properties.getBool("pack", true):
              for tile in tileset.tiles:
                var tileImageName = tileset.name & $tile.id
                
                #some maps share tilesets.
                if not positions.hasKey(tileImageName):
                  if not images.hasKey(tile.image):
                    images[tile.image] = readImage(file / "../" / tile.image)
                  
                  var 
                    cropped = images[tile.image]
                  
                  if tile.width > 0 and tile.height > 0:
                    cropped = cropped.subImage(tile.x, tile.y, tile.width, tile.height)
                  
                  if not cropped.isTransparent:
                    packFile(file / tileImageName, cropped)
        except:
          echo "Failed to parse tilemap file ", file, ": ", getCurrentExceptionMsg()

  #grab and sort files in order of size for more deterministic packing
  for file in walkDirRec(path):
    let split = file.splitFile
    if split.ext == ".png" or split.ext == ".aseprite":

      let size = getImageSize(file)

      toPack.add (file, max(size.w, size.h).int)

  toPack.sort do (a, b: PackEntry) -> int: -cmp(a.size, b.size)

  #pack every file in directory
  for (file, size) in toPack:
    let split = file.splitFile
    #check for 9patches!
    if split.name.endsWith(".9"):
      let
        img = readImage(file)
        cropped = img.subImage(1, 1, img.width - 2, img.height - 2)

      #find all the split points for the patch
      var
        top = -1
        left = -1
        bot = -1
        right = -1

      for i in 1..<img.width:
        if img[i, 0].a == 255:
          left = i - 1
          break

      for i in left+1..<img.width:
        if img[i, 0].a == 0:
          right = img.width - 1 - i
          break

      for i in 1..<img.height:
        if img[0, i].a == 255:
          top = i - 1
          break

      for i in top+1..<img.height:
        if img[0, i].a == 0:
          bot = img.height - 1 - i
          break

      #only save the cropped variant.
      packFile(split.name, cropped, [left, right, top, bot], realFile = file)
    elif split.ext == ".aseprite":
      try:
        let aseFile = readAseFile(file)

        #standard ase file
        for layer in aseFile.layers:
          let 
            centerX = layer.userData == "centerX"
            crop = layer.userData == "crop"

          #skip locked layers; I do not want to skip 'invisible' layers for convenience, so locked is used as the flag here instead
          if layer.kind == alImage and layer.frames.len > 0 and afEditable in layer.flags:
            #single-layer aseprite files default to file name only
            let name = if aseFile.layers.len == 1: "" else: layer.name

            let imageName = 
              if name.len == 0: split.name
              elif name[0] == '#' or name[0] == '@': layer.name[1..^1] #prefix layer name with @ or # to name it 'raw' without prefix
              else: split.name & "" & layer.name.capitalizeAscii #otherwise, use camel case concatenation

            for i, frame in layer.frames:
              #if there is 1 frame, don't add a suffix, otherwise use 0-indexing
              let frameName = if layer.frames.len == 1: imageName else: imageName & $i

              #copy layer RGBA data into new image
              let image = newImage(frame.width, frame.height)
              copyMem(addr image.data[0], addr frame.data[0], frame.width * frame.height * 4)
              
              #aseprite layers are "cropped", so each layer needs to have a new image made with the uncropped version
              let full = 
                if crop: 
                  image #it's pre-cropped, whee
                elif centerX:
                  #needs to be cropped to the X axis (centered)
                  let 
                    padding = min(frame.x, aseFile.width - (frame.x + frame.width))
                    r = newImage(aseFile.width - padding * 2, aseFile.height)
                  
                  r.draw(image, translate(vec2((r.width/2f-image.width/2f).int, frame.y.float32)))
                  r

                else:
                  let r = newImage(aseFile.width, aseFile.height)
                  r.draw(image, translate(vec2(frame.x.float32, frame.y.float32)))
                  r

              if frame.opacity != 255'u8 or layer.opacity != 255'u8:
                full.applyOpacity(frame.opacity.float32 / 255f * layer.opacity.float32 / 255f)

              if layer.userData == "outline" or layer.userData == "outlined":
                outline(full, if layer.userColor == 0'u32: blackRgba else: cast[ColorRGBA](layer.userColor))

              packFile(file / frameName, full, duration = frame.duration, realFile = file)
      
      except CatchableError:
        echo "Failed to read file ", file, ": ", getCurrentExceptionMsg()

    else:
      packFile(file, readImage(file))

  #save a white image
  if not positions.hasKey("white"):
    let img = newImage(1, 1)
    img[0, 0] = ColorRGBA(r: 255, g: 255, b: 255, a: 255)
    packFile("white.png", img)
  
  #save an error image if it's not present
  if not positions.hasKey("error"):
    let img = newImage(1, 1)
    img[0, 0] = ColorRGBA(r: 255, g: 0, b: 255, a: 255)
    packFile("error.png", img)
    
  output.parentDir.createDir()

  #delete old sprite files
  var deleteIndex = 0
  var toDelete = ""

  while toDelete == "" or toDelete.fileExists:
    if toDelete != "":
      toDelete.removeFile()
      
    toDelete = &"{output}{deleteIndex}.png"
    deleteIndex.inc
    
  var stream = openFileStream(&"{output}.dat", fmWrite)

  stream.write(positionsByImage.len.uint8)

  if not silent:
    echo &"Saving {positions.len} images..."

  #blit packed images and write them to the stream
  for imageIndex, entries in positionsByImage:
    var image = newImage(packers[imageIndex].w, packers[imageIndex].h)

    stream.write(entries.len.int32)

    for region in entries:

      image.draw(region.image, vmath.translate(vmath.vec2(region.pos.x.float32, region.pos.y.float32)))

      let bleed = region.settings.bleed

      #apply bleeding/gutters
      if bleed > 0:
        let
          ix = region.pos.x
          iy = region.pos.y
          iw = region.image.width
          ih = region.image.height
        
        for i in 0..<region.image.height:
          for s in 1..bleed:
            #left
            image[ix - s, iy + i] = region.image[0, i]
            #right
            image[ix + s + iw - 1, iy + i] = region.image[iw - 1, i]
        
        for i in 0..<region.image.width:
          for s in 1..bleed:
            #bottom
            image[ix + i, iy - s] = region.image[i, 0]
            #top
            image[ix + i, iy + s + ih - 1] = region.image[i, ih - 1]

      stream.write region.file.splitFile.name.len.int16
      stream.write region.file.splitFile.name
      stream.write region.pos.x.int16
      stream.write region.pos.y.int16
      stream.write region.image.width.int16
      stream.write region.image.height.int16

      #write splits if present (-1 considered invalid value)
      if region.splits[0] != -1:
        stream.write true
        for val in region.splits:
          stream.write val.int16
      else:
        stream.write false
      
      stream.write region.duration.uint16
    
    image.writeFile(&"{output}{imageIndex}.png")
  
  stream.close()

  if not silent:
    echo &"Done in {(cpuTime() - time).formatFloat(ffDecimal, 2)}s."
  
when isMainModule:
  import cligen

  dispatch(packImages, help = {
    "path": "path of images to pack",
    "output": "name of output file(s)"
  })
