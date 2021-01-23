import ../packer, os, pixie, strformat, tables, math, streams, times, chroma, strutils

from vmath import nil

proc fail(reason: string) = raise Exception.newException(reason)

proc packImages(path: string, output: string = "atlas", min = 64, max = 1024, padding = 0, bleeding = 2, verbose = false) =
  let packer = newPacker(min, min)
  var positions = initTable[string, tuple[image: Image, file: string, pos: tuple[x, y: int]]]()

  let time = cpuTime()
  let totalPad = padding + bleeding

  proc packFile(file: string, image: Image) =
    let name = file.splitFile.name

    if verbose: echo &"Packing image {name}..."

    if positions.hasKey(name): 
      fail &"Duplicate image names: '{file}' and '{positions[name].file}'"

    if image.width >= max or image.height >= max:
      fail &"Image '{file}' is too large to fit in this atlas ({image.width}x{image.height}). Increase the max atlas size."
    
    var pos: tuple[x, y: int] = (-1, -1)

    #keep trying to pack and resize until packer runs out of space.
    while pos == (-1, -1):
      pos = packer.pack(image.width, image.height, padding = totalPad)
      if pos == (-1, -1):
        let increaseWidth = packer.w <= packer.h

        if packer.w >= max and increaseWidth:
          fail &"Failed to fit images into {max}x{max} texture. Last image packed: {file}"
        
        if increaseWidth:
          packer.resize((packer.w + 1).nextPowerOfTwo, packer.h)
        else:
          packer.resize(packer.w, (packer.h + 1).nextPowerOfTwo)
    
    positions[name] = (image, file, pos)

  #pack every file in directory
  for file in walkDirRec(path):
    if file.splitFile.ext == ".png":
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

  var stream = openFileStream(&"{output}.dat", fmWrite)
  var image = newImage(packer.w, packer.h)

  stream.write positions.len.int32

  echo &"Saving {positions.len} images..."

  #blit packed images and write them to the stream
  for region in positions.values:
    image.draw(region.image, vmath.vec2(region.pos.x.float32, region.pos.y.float32))

    #apply bleeding/gutters
    if bleeding > 0:
      let
        ix = region.pos.x
        iy = region.pos.y
        iw = region.image.width
        ih = region.image.height
      
      for i in 0..<region.image.height:
        for s in 1..bleeding:
          #left
          image[ix - s, iy + i] = region.image[0, i]
          #right
          image[ix + s + iw - 1, iy + i] = region.image[iw - 1, i]
      
      for i in 0..<region.image.width:
        for s in 1..bleeding:
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
  
  stream.close()
  image.writeFile(&"{output}.png")

  echo &"Done in {(cpuTime() - time).formatFloat(ffDecimal, 2)}s."
  
  
when isMainModule:
  import cligen

  dispatch(packImages, help = {
    "min": "minimum texture size",
    "max": "maximum texture size",
    "path": "path of images to pack",
    "output": "name of output file(s)"
  })