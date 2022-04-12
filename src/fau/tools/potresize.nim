import pixie, os, math, vmath

proc resize(file: string) =
  let 
    padding = 2
    img = readImage(file)
  
  var
    absx = 0
    absy = 0
  
  for x in 0..<img.width:
    for y in 0..<img.height:
      let col = img[x, y]
      if col.a > 0:
        absx = max(absx, abs(x - img.width div 2) + padding)
        absy = max(absy, abs(y - img.height div 2) + padding)
  
  let target = newImage((absx * 2).nextPowerOfTwo, (absy * 2).nextPowerOfTwo)
  if target.width != img.width or target.height != img.height:
    target.draw(img, translate(vec2((target.width - img.width)/2, (target.height - img.height)/2)))
    target.writeFile(file)

let params = commandLineParams()
if params.len == 0:
  echo "Incorrect usage. First parameter must be a path to a folder."
else:
  for folder in params:
    for file in walkDir(folder):
      if file.kind == pcFile and file.path.splitFile.ext == ".png":
        resize(file.path)
