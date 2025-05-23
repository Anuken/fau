import texture, fmath, math

#region of a texture
type Patch* = object
  texture*: Texture
  u*, v*, u2*, v2*: float32

#a grid of 9 patches of a texture, used for rendering UI elements
type Patch9* = object
  texture*: Texture
  left*, right*, top*, bot*, width*, height*: int
  #the 9 patches, arranged in left to right, then bottom to top order
  patches*: array[9, Patch]

#creates a patch based on pixel coordinates of a texture
#TODO should be initPatch?
proc newPatch*(texture: Texture, x, y, width, height: int): Patch = 
  Patch(texture: texture, u: x / texture.size.x, v: y / texture.size.y, u2: (x + width) / texture.size.x, v2: (y + height) / texture.size.y)

proc initPatch*(texture: Texture, u, v, u2, v2: float32): Patch = Patch(texture: texture, u: u, v: v, u2: u2, v2: v2)
proc initPatch*(texture: Texture, uv, uv2: Vec2): Patch = initPatch(texture, uv.x, uv.y, uv2.x, uv2.y)

#properties that calculate size of a patch in pixels
proc x*(patch: Patch): int {.inline.} = (patch.u * patch.texture.size.x.float32).int
proc y*(patch: Patch): int {.inline.} = (patch.v * patch.texture.size.y.float32).int
proc width*(patch: Patch): int {.inline.} = ((patch.u2 - patch.u) * patch.texture.size.x.float32).round.abs.int
proc height*(patch: Patch): int {.inline.} = ((patch.v2 - patch.v) * patch.texture.size.y.float32).round.abs.int
#TODO: these are not rounded. should they be?
proc widthf*(patch: Patch): float32 {.inline.} = ((patch.u2 - patch.u) * patch.texture.size.x.float32).abs
proc heightf*(patch: Patch): float32 {.inline.} = ((patch.v2 - patch.v) * patch.texture.size.y.float32).abs
proc ratio*(patch: Patch): float32 = patch.widthf / patch.heightf
proc size*(patch: Patch): Vec2 {.inline.} = vec2(patch.widthf, patch.heightf)
proc sizei*(patch: Patch): Vec2i {.inline.} = vec2i(patch.width, patch.height)
proc uv*(patch: Patch): Vec2 {.inline.} = vec2(patch.u, patch.v)
proc uv2*(patch: Patch): Vec2 {.inline.} = vec2(patch.u2, patch.v2)
template exists*(patch: Patch): bool = patch != fau.atlas.error
template found*(patch: Patch): bool = patch != fau.atlas.error
proc valid*(patch: Patch): bool {.inline.} = not patch.texture.isNil

proc flipped*(patch: Patch): Patch = Patch(texture: patch.texture, u: patch.u, v: patch.v2, u2: patch.u2, v2: patch.v)

proc scroll*(patch: var Patch, u, v: float32) =
  patch.u += u
  patch.v += v
  patch.u2 += u
  patch.v2 += v

proc scroll*(patch: var Patch, uv: Vec2) = patch.scroll(uv.x, uv.y)

proc split*(patch: Patch, size: Vec2i): seq[seq[Patch]] =
  var
    dim = patch.sizei div size
    y = patch.y
    startX = patch.x
    cy = 0
  
  result.setLen(dim.x)

  while cy < dim.x:
    var 
      x = startX
      cx = 0

    while cx < dim.x:
      result[cx].setLen(dim.y)
      result[cx][cy] = newPatch(patch.texture, x, y, size.x, size.y)
      
      cx += 1
      x += size.x
      
    cy += 1
    y += size.y

proc splitHorizontal*(patch: Patch, width: int): seq[Patch] =
  var
    dimx = patch.width div width
    cx = 0
    x = patch.x
  
  result.setLen(dimx)

  while cx < dimx:
    result[cx] = newPatch(patch.texture, x, patch.y, width, patch.height)
      
    cx += 1
    x += width

converter toPatch*(texture: Texture): Patch {.inline.} = Patch(texture: texture, u: 0.0, v: 0.0, u2: 1.0, v2: 1.0)

proc newPatch9*(patch: Patch, left, right, top, bot: int): Patch9 =
  let
    midx = patch.width - left - right
    midy = patch.height - top - bot

  return Patch9(
    patches: [
     #bot left
     newPatch(patch.texture, patch.x, patch.y + midy + top, left, bot),
     #bot
     newPatch(patch.texture, patch.x + left, patch.y + midy + top, midx, bot),
     #bot right
     newPatch(patch.texture, patch.x + left + midx, patch.y + midy + top, right, bot),
     #mid left
     newPatch(patch.texture, patch.x, patch.y + top, left, midy),
     #mid
     newPatch(patch.texture, patch.x + left, patch.y + top, midx, midy),
     #mid right
     newPatch(patch.texture, patch.x + left + midx, patch.y + top, right, midy),
     #top left
     newPatch(patch.texture, patch.x, patch.y, left, top),
     #top mid
     newPatch(patch.texture, patch.x + left, patch.y, midx, top),
     #top right
     newPatch(patch.texture, patch.x + left + midx, patch.y, right, top),
   ],
   texture: patch.texture,
   top: top,
   bot: bot,
   left: left,
   right: right,
   width: patch.width,
   height: patch.height
  )

#Converts a patch into an empty patch9
proc patch9*(patch: Patch): Patch9 = Patch9(
  patches: [patch, patch, patch, patch, patch, patch, patch, patch, patch],
  texture: patch.texture,
  width: patch.width,
  height: patch.height
)

proc valid*(patch: Patch9): bool {.inline.} = not patch.patches[0].texture.isNil
