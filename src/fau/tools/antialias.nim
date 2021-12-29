import pixie, chroma, os, algorithm

# This file contains an implementation of an antialiasing algorithm.
# It's not very fast, but definitely faster than my previous Groovy version.
# Possible optimizations include SIMD and multithreading pixel processing

proc lerp*(color: var Color, target: Color, t: float32) {.inline.} =
  color.r += t * (target.r - color.r)
  color.g += t * (target.g - color.g)
  color.b += t * (target.b - color.b)
  color.a += t * (target.a - color.a)

proc `*=`(color: var Color, val: float32) {.inline.} =
  color.r *= val
  color.g *= val
  color.b *= val
  color.a *= val

proc antialias*(file: string) =
  let 
    image = readImage(file)
    output = readImage(file)

  template getRGB(ix, iy: int): ColorRGBA = image[max(min(ix, image.width - 1), 0), max(min(iy, image.height - 1), 0)]

  var p: array[9, ColorRGBA]

  for x in 0..<image.width:
    for y in 0..<image.height:

      #perform scale3x algorithm
      let 
        A = getRGB(x - 1, y + 1)
        B = getRGB(x, y + 1)
        C = getRGB(x + 1, y + 1)
        D = getRGB(x - 1, y)
        E = getRGB(x, y)
        F = getRGB(x + 1, y)
        G = getRGB(x - 1, y - 1)
        H = getRGB(x, y - 1)
        I = getRGB(x + 1, y - 1)
      
      p.fill(E)

      if D == B and D != H and B != F: p[0] = D
      if (D == B and D != H and B != F and E != C) or (B == F and B != D and F != H and E != A): p[1] = B
      if B == F and B != D and F != H: p[2] = F
      if (H == D and H != F and D != B and E != A) or (D == B and D != H and B != F and E != G): p[3] = D
      if (B == F and B != D and F != H and E != I) or (F == H and F != B and H != D and E != C): p[5] = F
      if H == D and H != F and D != B: p[6] = D
      if (F == H and F != B and H != D and E != G) or (H == D and H != F and D != B and E != I): p[7] = H
      if F == H and F != B and H != D: p[8] = F

      #sum the colors produced by scale3x
      var suma = Color()

      for val in p:
        let color = val.color
        suma.r += color.r * color.a
        suma.g += color.g * color.a
        suma.b += color.b * color.a
        suma.a += color.a

      var fm = if suma.a <= 0.001f: 0f else: (1f / suma.a)
      suma *= fm

      var total = 0f
      var sum = Color()

      for val in p:
        var color = val.color
        let a = color.a

        color.lerp(suma, 1f - a)

        sum.r += color.r
        sum.g += color.g
        sum.b += color.b
        sum.a += a
        total += 1f

      fm = 1f / total
      sum *= fm

      output[x, y] = sum.rgba
    
  output.writeFile(file)

let params = commandLineParams()
if params.len == 0:
  echo "Incorrect usage. First parameter must be a path to a file."
else:
  for img in params:
    antialias(img)
