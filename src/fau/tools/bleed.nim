import pixie, chroma, os

const offsets = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]

proc bleedFull(image: Image, maxIterations = 5) =
  let 
    w = image.width
    h = image.height
    total = w * h

  var
    data = newSeq[bool](total)
    pending = newSeq[int](total)
    changing = newSeq[int](total)
    pendingSize = 0
    changingSize = 0
    iterations = 0
    lastPending = -1
  
  for i in 0..<total:
    if image.data[i].a == 0:
      pending[pendingSize] = i
      pendingSize.inc
    else:
      data[i] = true

  while pendingSize > 0 and pendingSize != lastPending and iterations < maxIterations:
    lastPending = pendingSize
    var index = 0
    while index < pendingSize:
      let 
        pixelIndex = pending[index]
        x = pixelIndex mod w
        y = pixelIndex div w
      index.inc

      var
        r = 0
        g = 0
        b = 0
        count = 0
      
      for (px, py) in offsets:
        let
          nx = x + px
          ny = y + py
        
        if nx < 0 or nx >= w or ny < 0 or ny >= h:
          continue
          
        let currentPixelIndex = ny * w + nx
        if data[currentPixelIndex]:
          let col = image.data[currentPixelIndex]
          r += col.r.int
          g += col.g.int
          b += col.b.int
          count.inc
        
      if count != 0:
        image.data[pixelIndex] = rgbx(uint8(r / count), uint8(g / count), uint8(b / count), image.data[pixelIndex].a)

        index.dec
        let value = pending[index]
        pendingSize.dec
        pending[index] = pending[pendingSize]
        changing[changingSize] = value
        changingSize.inc
    
    for i in 0..<changingSize:
      data[changing[i]] = true
    
    changingSize = 0
    iterations.inc

let params = commandLineParams()
if params.len == 0:
  echo "Incorrect usage. First parameter must be a path to a file."
else:
  for file in params:
    let img = readImage(file)
    bleedFull(img)
    img.writeFile(file)
