import pkg/zippy/ziparchives, pkg/nimlzf, std/[streams, xmlparser, xmltree, strutils, tables]

## Utility for reading Krita files - Guidance taken from https://krita-artists.org/t/what-image-format-do-kra-files-use-for-layers/91242/3 and https://invent.kde.org/documentation/docs-krita-org/-/merge_requests/105/diffs
## Currently only supports reading Krita files from disk due to zippy limitations (https://github.com/guzba/zippy/issues/56)
## To get around this, I would need to port it to: https://github.com/status-im/nim-zlib
## It's probably not too important because you shouldn't be using krita files in your assets anyway, they aren't exactly the most straightforward way of storing images.

type KritaLayerKind* = enum
  klImage, klGroup, klClone

type KritaLayer* = ref object
  opacity*: float32 = 1f #0..1
  visible*: bool
  passthrough*: bool
  locked*: bool
  collapsed*: bool
  name*: string
  blend*: string
  alphaClip*: bool
  x*, y*: int32
  id*: string
  
  case kind*: KritaLayerKind
  of klImage:
    width*, height*: int32
    data*: seq[uint8]
  of klGroup:
    children*: seq[KritaLayer]
  of klClone:
    #layer that is being cloned
    clone*: KritaLayer
    cloneId*: string

type KritaDocument* = ref object
  width*, height*: int32
  layers*: seq[KritaLayer]

proc readLineAt(data: string, pos: var int): string =
  ## reads a '\n'-terminated text line from `data` starting at `pos`, advances `pos` past the newline, and returns the line without it.
  let start = pos
  var p = start
  while p < data.len and data[p] != '\n':
    inc p
  result = data[start ..< p]
  pos = p + 1 #skip the '\n'
 
proc readImageData(data: string, offsetX, offsetY, width, height: int32): seq[uint8] =
  ## should return data as RGBA 4-byte pixel values (OpenGL RGBA8)
  var pos = 0
 
  let versionLine = readLineAt(data, pos)
  doAssert versionLine.startsWith("VERSION"), "Unexpected header: " & versionLine
 
  let tileWidth  = readLineAt(data, pos).split(' ')[1].parseInt()
  let tileHeight = readLineAt(data, pos).split(' ')[1].parseInt()
  let pixelSize  = readLineAt(data, pos).split(' ')[1].parseInt()
  let numTiles   = readLineAt(data, pos).split(' ')[1].parseInt()
 
  doAssert pixelSize == 4, "Only 4-byte (RGBA8/BGRA8) pixels are supported"
 
  let w = width.int
  let h = height.int
  result = newSeq[uint8](w * h * 4)
 
  let planePixels = tileWidth * tileHeight
 
  for t in 0 ..< numTiles:
    #tile header: "<x>,<y>,LZF,<length>\n"
    let tileHeader = readLineAt(data, pos)
    let parts = tileHeader.split(',')
    doAssert parts.len == 4, "Unexpected tile header: " & tileHeader
 
    let tileX = parts[0].parseInt()
    let tileY = parts[1].parseInt()
    let length = parts[3].parseInt()
 
    doAssert pos + length <= data.len, "Tile data runs past end of buffer"
 
    let tileBlock = data[pos ..< pos + length]
    pos += length
 
    doAssert tileBlock.len >= 1, "Empty tile data block"
    let compressionFlag = tileBlock[0].uint8
    let payload = tileBlock[1 ..< tileBlock.len]
 
    let uncompressedSize = planePixels * pixelSize
 
    var plane: string
    case compressionFlag
    of 0x00'u8:
      doAssert payload.len == uncompressedSize, "Uncompressed tile payload size mismatch"
      plane = payload
    of 0x01'u8:
      plane = lzfDecompress(payload, uncompressedSize)
      doAssert plane.len == uncompressedSize, "Decompressed tile size mismatch"
    else:
      raiseAssert "Unknown tile compression flag: " & $compressionFlag
 
    let bPlaneOff = 0 * planePixels
    let gPlaneOff = 1 * planePixels
    let rPlaneOff = 2 * planePixels
    let aPlaneOff = 3 * planePixels
 
    #blit tile onto buffer with clipping
    for ly in 0 ..< tileHeight:
      let gy = tileY + ly + offsetY
      if gy < 0 or gy >= h:
        continue
      let rowLocalBase = ly * tileWidth
      let rowOutBase = gy * w
      for lx in 0 ..< tileWidth:
        let gx = tileX + lx + offsetX
        if gx < 0 or gx >= w:
          continue
        let localIdx = rowLocalBase + lx
        let outIdx = (rowOutBase + gx) * 4
 
        result[outIdx + 0] = plane[rPlaneOff + localIdx].uint8 # R
        result[outIdx + 1] = plane[gPlaneOff + localIdx].uint8 # G
        result[outIdx + 2] = plane[bPlaneOff + localIdx].uint8 # B
        result[outIdx + 3] = plane[aPlaneOff + localIdx].uint8 # A

proc readKritaFile*(path: string): KritaDocument =
  result = KritaDocument()

  var archive = openZipArchive(path)
  let
    doc = parseXml(archive.extractFile("maindoc.xml"))
    image = doc.child("IMAGE")
    layers = image.child("layers")
    docWidth = parseInt(image.attr("width")).int32
    docHeight= parseInt(image.attr("height")).int32
  
  result.width = docWidth
  result.height = docHeight
  
  let folderName = image.attr("name")
  
  var
    clonesToResolve: seq[KritaLayer]
    idToLayer: Table[string, KritaLayer]
  
  proc parseLayer(node: XmlNode): KritaLayer =
    
    let
      ntype = node.attr("nodetype")
      channelFlags = node.attr("channelflags")
      filename = node.attr("filename")
    
    if ntype == "grouplayer":
      var layers: seq[KritaLayer]
      let children = node.child("layers")
      for child in children:
        let res = parseLayer(child)
        if res != nil: layers.add(res)
        
      result = KritaLayer(kind: klGroup, children: layers)
    elif ntype == "paintlayer":
      let
        layerPath = folderName & "/layers/" & filename
        x = node.attr("x").parseInt.int32
        y = node.attr("y").parseInt.int32
        data = readImageData(archive.extractFile(layerPath), x, y, docWidth, docHeight)
      
      result = KritaLayer(kind: klImage, data: data, width: docWidth, height: docHeight)
    elif ntype == "clonelayer":
        let
          cloneId = node.attr("clonefromuuid")
          x = node.attr("x").parseInt.int32
          y = node.attr("y").parseInt.int32
        
        result = KritaLayer(kind: klClone, cloneId: cloneId, x: x, y: y)
        #resolve clone target based on ID later
        clonesToResolve.add result
    
    if result != nil:
      result.opacity = if node.attr("opacity") == "": 1f else: parseInt(node.attr("opacity")).float32 / 255f
      result.visible = node.attr("visible") == "1"
      result.collapsed = node.attr("collapsed") == "1"
      result.locked = node.attr("locked") == "1"
      result.passthrough = node.attr("passthrough") == "1"
      result.name = node.attr("name")
      result.blend = node.attr("compositeop")
      result.alphaClip = channelFlags.len > 0 and channelFlags[^1] == '0'
      result.id = node.attr("uuid")
      
      idToLayer[result.id] = result
    
  for layer in layers:
    let res = parseLayer(layer)
    if res != nil:
      result.layers.add(res)
  
  for layer in clonesToResolve:
    if layer.kind == klClone:
      layer.clone = idToLayer[layer.cloneId]
      if layer.clone == nil:
        echo "Unresolved clone ID! name=", layer.name, " targetid=", layer.cloneId