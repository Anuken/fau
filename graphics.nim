import gl, strutils, gltypes
export gl

#basic camera
type Camera* = ref object
    x, y, w, h: float

#defines a texture region type
type Tex* = object
    x, y, w, h: int #TODO add reference to a texture

#defines a color
type Col* = object
    r*, g*, b*, a*: float32 #TODO should be floats

#converts a hex string to a color
export parseHexInt
template `%`*(str: string): Col =
    Col(r: str[0..1].parseHexInt().uint8 / 255.0, g: str[2..3].parseHexInt().uint8 / 255.0, b: str[4..5].parseHexInt().uint8 / 255.0, a: 255)

#types of blending
type Blending* = object
    src*: GLenum
    dst*: Glenum

const blendNormal* = Blending(src: GlSrcAlpha, dst: GlOneMinusSrcAlpha)
const blendAdditive* = Blending(src: GlSrcAlpha, dst: GlOne)
const blendDisabled* = Blending(src: GlSrcAlpha, dst: GlOneMinusSrcAlpha)

#TEXTURE

#an openGL image
type Texture* = ref object
    handle: Gluint
    uwrap, vwrap: Glenum
    minfilter, magfilter: Glenum
    target: Glenum

#binds the texture
proc use*(texture: Texture) =
    #TODO only texture2D can be bound to
    glBindTexture(texture.target, texture.handle)

proc dispose*(texture: Texture) = 
    glDeleteTexture(texture.handle)

#assigns min and mag filters
proc `filter=`*(texture: Texture, filter: Glenum) =
    texture.minfilter = filter
    texture.magfilter = filter
    texture.use()
    glTexParameteri(texture.target, GlTextureMinFilter, texture.minfilter.GLint)
    glTexParameteri(texture.target, GlTextureMagFilter, texture.magfilter.GLint)

#assigns wrap modes for each axis
proc `wrap=`*(texture: Texture, wrap: Glenum) =
    texture.uwrap = wrap
    texture.vwrap = wrap
    texture.use()
    glTexParameteri(texture.target, GlTextureWrapS, texture.uwrap.GLint)
    glTexParameteri(texture.target, GlTextureWrapT, texture.vwrap.GLint)

proc newTexture*(): Texture = 
    result = Texture(handle: glGenTexture(), uwrap: GlClampToEdge, vwrap: GlClampToEdge, minfilter: GlNearest, magfilter: GlNearest, target: GlTexture2D)
    result.use()
    #set parameters
    glTexParameteri(result.target, GlTextureMinFilter, result.minfilter.GLint)
    glTexParameteri(result.target, GlTextureMagFilter, result.magfilter.GLint)
    glTexParameteri(result.target, GlTextureWrapS, result.uwrap.GLint)
    glTexParameteri(result.target, GlTextureWrapT, result.vwrap.GLint)

#loads texture data; the texture must be bound for this to work.
proc load(texture: Texture, width: int, height: int, pixels: var openArray[uint8]) =
    glPixelStorei(GlUnpackAlignment, 1)
    glTexImage2D(texture.target, 0, GlRGBA.Glint, width.GLsizei, height.GLsizei, 0, GlRGBA, GlUnsignedByte, addr pixels)

#region of a texture
type TexReg* = object
    texture: Texture
    u, v, u2, v2: float32
