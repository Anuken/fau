import streams, zippy

## Utility for reading Aseprite files - https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
## Does not support any advanced features whatsoever, only the very basics. Indexed colors, palettes and tilemaps are not supported.

type
  AseLayerFlags* = enum
    afVisible, afEditable, afLockMovement, afBackground, 
    afPreferLinkedCels, afCollapsed, afReference
  AseLayerType* = enum
    alImage, alGroup, alTilemap
  AseLoopDirection* = enum
    alForward, alReverse, alPingPong, alPingPongReverse
  AseTag* = object
    frameFrom*, frameTo*: int
    direction*: AseLoopDirection
    repeat*: int
    name*: string
    userData*: string
    userColor*: uint32 #RGBA8888
  #TODO ref, or not?
  AseFrame* = ref object
    duration*: int
    data*: string
    width*, height*: int
    x*, y*: int
    opacity*: uint8
  AseLayer* = ref object
    flags*: set[AseLayerFlags]
    name*: string
    opacity*: uint8
    frames*: seq[AseFrame]
    kind*: AseLayerType
    userData*: string
    userColor*: uint32 #RGBA8888
  AseImage* = ref object
    layers*: seq[AseLayer]
    tags*: seq[AseTag]
    width*, height*: int
    colorDepth*: int

proc readAseStream*(s: Stream): AseImage =
  template error(msg: string) = raise newException(IOError, msg)
  template skip(len: int) = s.setPosition(s.getPosition() + len)
  template readString(): string =
    let slen = s.readUint16().int
    if slen == 0:
      ""
    else:
      var str = newString(slen)
      discard s.readData(addr str[0], slen)
      str

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

  var 
    layerData: seq[AseLayer]
    tags: seq[AseTag]
    justReadTags = false
    readTagIndex = 0

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

    var readImage = false

    for chunkId in 0..<chunks.int:
      let 
        chunkSize = s.readUint32()
        chunkType = s.readUint16()
      
      if chunkType == 0x2004'u16: #layer
        justReadTags = false

        let
          flags = s.readUint16()
          layerType = s.readUint16()
        
        discard s.readUint16() #child level, ignored
        discard s.readUint32() #width/height, ignored
        discard s.readUint16() #blend mode, ignored

        let opacity = s.readUint8()

        #skip 3 bytes, unused
        skip(3)

        let name = readString()

        if layerType == 2:
          #tileset index, don't care
          discard s.readUint32()
        
        layerData.add AseLayer(opacity: if validOpacity: opacity else: 255'u8, name: name, flags: cast[set[AseLayerFlags]](flags), kind: layerType.AseLayerType)
      
      elif chunkType == 0x2018'u16: #tags
        justReadTags = true

        let count = s.readUint16().int
        skip(8)
        for i in 0..<count:

          let 
            fromFrame = s.readUint16()
            toFrame = s.readUint16()
            loopDirection = s.readUint8()
            repeat = s.readUint16()
          
          skip(10) #unused

          let name = readString()

          tags.add(AseTag(frameFrom: fromFrame.int, frameTo: toFrame.int, direction: loopDirection.AseLoopDirection, repeat: repeat.int, name: name))
      elif chunkType == 0x2020'u16 and (layerData.len > 0 or justReadTags): #user data (horrible implementation)
        let flags = s.readUint32()

        if (flags and 1) == 1: #text
          let text = readString()
          if not justReadTags:
            layerData[^1].userData = text
          else:
            tags[readTagIndex].userData = text

        if (flags and 2) == 2: #color
          let color = s.readUint32()
          if not justReadTags:
            layerData[^1].userColor = color
          else:
            tags[readTagIndex].userColor = color
        
        #other flags not supported! will crash!
        
        if justReadTags:
          readTagIndex.inc

      elif chunkType == 0x2005'u16: #cel (image data)
        justReadTags = false
        readImage = true

        let 
          layerIndex = s.readUint16()
          x = s.readInt16()
          y = s.readInt16()
          opacity = s.readUInt8()
          
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
            compressedLength = chunkSize.int - 6 - 2 - 4 - 1 - 2 - 4 - 7
            compressedData = newSeqUninitialized[uint8](compressedLength)

          discard s.readData(addr compressedData[0], compressedLength.int)
          
          #instead of frames containing layers, it's layers containing frames (more intuitive to me)

          layerData[layerIndex].frames.add AseFrame(
            data: uncompress(addr compressedData[0], compressedLength.int, dataFormat = dfZlib), 
            duration: durationMs.int,
            x: x.int,
            y: y.int,
            width: pixWidth.int,
            height: pixHeight.int,
            opacity: opacity
          )

      else: #unknown chunk, skipping - I don't support indexed colors, so palettes do not matter
        skip(chunkSize.int - 6)
    
    if not readImage:

      #add dummy empty 0x0 frame
      for layerIndex in 0..<layerData.len:
        layerData[layerIndex].frames.add AseFrame(
          duration: durationMs.int,
          x: 0, y: 0, width: 0, height: 0, opacity: 255'u8
        )
    
  return AseImage(layers: layerData, width: width.int, height: height.int, colorDepth: colorDepth.int, tags: tags)

proc readAseFile*(path: string): AseImage = readAseStream(newFileStream(path, bufSize = 512))