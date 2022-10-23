import streams, zippy

## Utility for reading Aseprite files - https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
## Does not support any advanced features whatoever, only the very basics.

type
  AseLayerFlags* = enum
    afVisible, afEditable, afLockMovement, afBackground, afPreferLinkedCels,
    afCollapsed, afReference
  AseLayerType* = enum
    alImage, alGroup, alTilemap
  #TODO ref, or not?
  AseFrame* = ref object
    duration*: int
    data*: string
  AseLayer* = ref object
    #I don't care about most layer info, just the name
    flags*: set[AseLayerFlags]
    name*: string
    opacity*: uint8
    width*, height*: int
    x*, y*: int
    frames*: seq[AseFrame]
    kind*: AseLayerType
  AseImage* = ref object
    layers*: seq[AseLayer]
    width*, height*: int
    colorDepth*: int

proc readAseStream*(s: Stream): AseImage =
  template error(msg: string) = raise newException(IOError, msg)
  template skip(len: int) = s.setPosition(s.getPosition() + len)

  discard s.readUint32() #file size

  if s.readUint16() != 0xA5E0'u16:
    error("Invalid header, not an ASE file?")
  
  let 
    frames = s.readUint16()
    width = s.readUint16()
    height = s.readUint16()
    colorDepth = s.readUint16()
    flags = s.readUint32()
    validOpacity = flags == 1

  if colorDepth != 32:
    error("Only RGBA (32-bit, non-indexed) aseprite files are supported.")
  
  discard s.readUint16() #speed, deprecated
  discard s.readUint32() #0
  discard s.readUint32() #0
  discard s.readUint32() #transparent color index (first byte) + 3 extras

  discard s.readUint16() #color number
  discard s.readUint8() #width of a pixel
  discard s.readUint8() #height of apixel
  discard s.readInt16() #grid X
  discard s.readInt16() #grid Y
  discard s.readUint16() #grid width
  discard s.readUint16() #grid height
  
  #header padding
  skip(84)

  var layerData: seq[AseLayer]

  for frameid in 0..<frames.int:
    discard s.readUint32() #frame total bytes

    if s.readUint16() != 0xF1FA'u16:
      error("Invalid frame magic (corrupt file?)")

    let
      chunksOld = s.readUint16()
      durationMs = s.readUint16()
    
    #unused
    discard s.readUint16()

    let 
      chunksNew = s.readUint32()
      chunks = if chunksNew == 0: chunksOld.uint32 else: chunksNew

    for chunkId in 0..<chunks.int:
      let 
        chunkSize = s.readUint32()
        chunkType = s.readUint16()
      
      if chunkType == 0x2004'u16: #layer
        let
          flags = s.readUint16()
          layerType = s.readUint16()
        
        discard s.readUint16() #child level, ignored
        discard s.readUint32() #width/height, ignored
        discard s.readUint16() #blend mode, ignored

        let opacity = s.readUint8()

        #skip 3 bytes, unused
        skip(3)

        #name
        let nameLen = s.readUint16().int
        var name = newString(nameLen)
        discard s.readData(addr name[0], nameLen)

        if layerType == 2:
          #tileset index, don't care
          discard s.readUint32()
        
        layerData.add AseLayer(opacity: if validOpacity: opacity else: 255'u8, name: name, flags: cast[set[AseLayerFlags]](flags), kind: layerType.AseLayerType)
      elif chunkType == 0x2005'u16: #cel (image data)
        let 
          layerIndex = s.readUint16()
          x = s.readInt16()
          y = s.readInt16()
          
        discard s.readUInt8() #what's the difference between this and layer opacity???
          
        let celType = s.readUint16()
        
        skip(7) #reserved
        
        #TODO figure out links later
        if celType != 2:
          error("Only compressed image data is allowed - tilemaps, links and raw images are not supported.")
        else:
          let
            pixWidth = s.readUint16()
            pixHeight = s.readUint16()

          #base size - 6 byte header - 2 byte index - 4 bytes xy - 1 byte opacity - 2 bytes type - 4 bytes size - 7 bytes padding
          var compressedLength = chunkSize.int - 6 - 2 - 4 - 1 - 2 - 4 - 7

          var compressedData = newSeqUninitialized[uint8](compressedLength)

          discard s.readData(addr compressedData[0], compressedLength.int)
          
          #instead of frames containing layers, it's layers containing frames (more intuitive to me)
          var layer = layerData[layerIndex]
          layer.x = x.int
          layer.y = y.int
          layer.width = pixWidth.int
          layer.height = pixHeight.int

          layer.frames.add AseFrame(data: uncompress(addr compressedData[0], compressedLength.int, dataFormat = dfZlib), duration: durationMs.int)

      else: #unknown chunk, skipping - I don't support indexed colors, so palettes do not matter
        skip(chunkSize.int - 6)
    
  return AseImage(layers: layerData, width: width.int, height: height.int, colorDepth: colorDepth.int)

proc readAseFile*(path: string): AseImage = readAseStream(newFileStream(path, bufSize = 512))   

when isMainModule:
  discard readAseFile("/home/anuke/Projects/Eterne/assets-raw/sprites/characters/makiru/makiru.aseprite")