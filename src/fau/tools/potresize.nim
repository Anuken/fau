import pixie, os, math, vmath

proc resize(file: string) =
  let 
    img = readImage(file)
    target = newImage(img.width.nextPowerOfTwo, img.height.nextPowerOfTwo)
  
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
