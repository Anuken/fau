import gl, strutils, gltypes, nimPNG, tables, gmath
export gltypes, gmath

#RENDERING

#basic camera
type Cam* = ref object
    pos*: Vec2
    w*, h*: float32
    mat*, inv: Mat

proc newCam*(): Cam = Cam(pos: vec2(0.0, 0.0), w: 10, h: 10)

proc update*(cam: Cam) = 
    cam.mat = ortho(cam.pos.x - cam.w/2, cam.pos.y - cam.h/2, cam.w, cam.h)
    cam.inv = cam.mat.inv()

proc resize*(cam: Cam, w, h: float32) = 
    cam.w = w
    cam.h = h
    cam.update()

proc unproject*(cam: Cam, vec: Vec2): Vec2 = 
    vec2((2 * (vec.x - cam.pos.x)) / cam.w - 1, (2 * (vec.y - cam.pos.y)) / cam.h - 1) * cam.inv

proc project*(cam: Cam, vec: Vec2): Vec2 = 
    let pro = vec * cam.mat
    return vec2(cam.w * (cam.pos.x + 1) / 2 + pro.x, cam.h * (cam.pos.y + 1) / 2 + pro.y)

#defines a color
type Color* = object
    r*, g*, b*, a*: float32 #TODO should be floats

proc rgba*(r: float32, g: float32, b: float32, a: float32 = 1.0): Color =
    result = Color(r: r, g: g, b: b, a: a)

#convert a color to a ABGR float representation; result may be NaN (?)
proc toFloat*(color: Color): float32 = 
    cast[float32](((255 * color.a).int shl 24) or ((255 * color.b).int shl 16) or ((255 * color.g).int shl 8) or ((255 * color.r).int))

#converts a hex string to a color
export parseHexInt
template `%`*(str: string): Color =
    Color(r: str[0..1].parseHexInt().uint8 / 255.0, g: str[2..3].parseHexInt().uint8 / 255.0, b: str[4..5].parseHexInt().uint8 / 255.0, a: 255)

#types of blending
type Blending* = object
    src*: GLenum
    dst*: Glenum

const blendNormal* = Blending(src: GlSrcAlpha, dst: GlOneMinusSrcAlpha)
const blendAdditive* = Blending(src: GlSrcAlpha, dst: GlOne)
const blendDisabled* = Blending(src: GlSrcAlpha, dst: GlOneMinusSrcAlpha)

#activate a blending function
proc use*(blend: Blending) = 
    if blend == blendDisabled:
        glDisable(GLBlend)
    else:
        glEnable(GlBlend)
        glBlendFunc(blend.src, blend.dst)

#UTILITIES

proc clearScreen*(col: Color) =
    glClearColor(col.r, col.g, col.b, col.a)
    glClear(GlColorBufferBit)

#TEXTURE

#an openGL image
type Texture* = ref object
    handle: Gluint
    uwrap, vwrap: Glenum
    minfilter, magfilter: Glenum
    target: Glenum
    width*, height*: int

#binds the texture
proc use*(texture: Texture, unit: GLenum = GlTexture0) =
    glActiveTexture(unit)
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

proc `filterMin=`*(texture: Texture, filter: Glenum) =
    texture.minfilter = filter
    texture.use()
    glTexParameteri(texture.target, GlTextureMinFilter, texture.minfilter.GLint)

proc `filterMag=`*(texture: Texture, filter: Glenum) =
    texture.magfilter = filter
    texture.use()
    glTexParameteri(texture.target, GlTextureMagFilter, texture.magfilter.GLint)

proc `wrapU=`*(texture: Texture, wrap: Glenum) =
    texture.uwrap = wrap
    texture.use()
    glTexParameteri(texture.target, GlTextureWrapS, texture.uwrap.GLint)

proc `wrapV=`*(texture: Texture, wrap: Glenum) =
    texture.vwrap = wrap
    texture.use()
    glTexParameteri(texture.target, GlTextureWrapT, texture.vwrap.GLint)

#loads texture data; the texture must be bound for this to work.
proc load(texture: Texture, width: int, height: int, pixels: var openArray[uint8]) =
    #bind texture
    texture.use()
    glPixelStorei(GlUnpackAlignment, 1)
    glTexImage2D(texture.target, 0, GlRGBA.Glint, width.GLsizei, height.GLsizei, 0, GlRGBA, GlUnsignedByte, addr pixels)
    texture.width = width
    texture.height = height

#creates a base texture with no data uploaded
proc newTexture(): Texture = 
    result = Texture(handle: glGenTexture(), uwrap: GlClampToEdge, vwrap: GlClampToEdge, minfilter: GlNearest, magfilter: GlNearest, target: GlTexture2D)
    result.use()

    #set parameters
    glTexParameteri(result.target, GlTextureMinFilter, result.minfilter.GLint)
    glTexParameteri(result.target, GlTextureMagFilter, result.magfilter.GLint)
    glTexParameteri(result.target, GlTextureWrapS, result.uwrap.GLint)
    glTexParameteri(result.target, GlTextureWrapT, result.vwrap.GLint)

#load texture from bytes
proc loadTexture*(bytes: openArray[uint8]): Texture =
    result = newTexture()

    #creates a base texture
    let data = decodePNG32(bytes)

    if data.isOk:
        result.load(data.value.width, data.value.height, data.value.data)
    else:
        raise newException(IOError, data.error)

#load texture from path
proc loadTexture*(path: string): Texture =
    let f = open(path)
    var bytes = newSeq[uint8](f.getFileSize())
    discard f.readBytes(bytes, 0, bytes.len)

    return loadTexture(bytes)

#region of a texture
type Patch* = object
    texture*: Texture
    u*, v*, u2*, v2*: float32

converter toPatch*(texture: Texture): Patch = Patch(texture: texture, u: 0.0, v: 0.0, u2: 1.0, v2: 1.0)

#SHADER

type ShaderAttr* = object
    name*: string
    gltype*: GLenum
    size*: GLint
    length*: Glsizei
    location*: GLint

type Shader* = ref object
    handle, vertHandle, fragHandle: GLuint
    compileLog: string
    compiled: bool
    uniforms: Table[string, int]
    attributes: Table[string, ShaderAttr]

proc loadSource(shader: Shader, shaderType: GLenum, source: string): GLuint =
    result = glCreateShader(shaderType)
    if result == 0: return 0.GLuint

    #attach source
    glShaderSource(result, source)
    glCompileShader(result)

    #check compiled status
    let compiled = glGetShaderiv(result, GL_COMPILE_STATUS)

    if compiled == 0:
        shader.compiled = false
        shader.compileLog &= ("[" & (if shaderType == GL_FRAGMENT_SHADER: "fragment shader" else: "vertex shader") & "]\n")
        let infoLen = glGetShaderiv(result, GL_INFO_LOG_LENGTH)
        if infoLen > 1:
            let infoLog = glGetShaderInfoLog(result)
            shader.compileLog &= infoLog #append reason to log
        glDeleteShader(result)

proc dispose*(shader: Shader) = 
    glUseProgram(0)
    glDeleteShader(shader.vertHandle)
    glDeleteShader(shader.fragHandle)
    glDeleteProgram(shader.handle)

proc use*(shader: Shader) =
    glUseProgram(shader.handle)

proc preprocess(source: string, fragment: bool): string =
    #disallow gles qualifiers
    if source.contains("#ifdef GL_ES"):
        raise newException(GlError, "Shader contains GL_ES specific code; this should be handled by the preprocessor. Code: \n" & source);
    
    #disallow explicit versions
    if source.contains("#version"):
        raise newException(GlError, "Shader contains explicit version requirement; this should be handled by the preprocessor. Code: \n" & source)

    #add GL_ES precision qualifiers
    if fragment: 
        return """

        #ifdef GL_ES
        precision mediump float;
        precision mediump int;
        #else
        #define lowp  
        #define mediump 
        #define highp 
        #endif

        """ & source
    else:
        #strip away precision qualifiers
        return """

        #ifndef GL_ES
        #define lowp  
        #define mediump 
        #define highp 
        #endif

        """ & source

proc newShader*(vertexSource, fragmentSource: string): Shader =
    result = Shader()
    result.uniforms = initTable[string, int]()
    result.compiled = true
    result.vertHandle = loadSource(result, GL_VERTEX_SHADER, preprocess(vertexSource, false))
    result.fragHandle = loadSource(result, GL_FRAGMENT_SHADER, preprocess(fragmentSource, true))

    if not result.compiled:
        raise Exception.newException("Failed to compile shader: \n" & result.compileLog)

    var program = glCreateProgram()
    glAttachShader(program, result.vertHandle)
    glAttachShader(program, result.fragHandle)
    glLinkProgram(program)

    let status = glGetProgramiv(program, GL_LINK_STATUS)

    if status == 0:
        let infoLen = glGetProgramiv(program, GL_INFO_LOG_LENGTH)
        if infoLen > 1:
            let infoLog = glGetProgramInfoLog(program)
            result.compileLog &= infoLog #append reason to log
            result.compiled = false
        raise Exception.newException("Failed to link shader: " & result.compileLog) 

    result.handle = program

    #fetch attributes for shader
    let numAttrs = glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES)
    for i in 0..<numAttrs:
        var alen: GLsizei
        var asize: GLint
        var atype: GLenum
        var aname: string
        glGetActiveAttrib(program, i.GLuint, alen, asize, atype, aname)
        let aloc = glGetAttribLocation(program, aname)

        result.attributes[aname] = ShaderAttr(name: aname, size: asize, length: alen, gltype: atype, location: aloc)

#attribute functions

proc getAttributeLoc*(shader: Shader, alias: string): int = 
    if not shader.attributes.hasKey(alias): return -1
    return shader.attributes[alias].location

proc enableAttribute*(shader: Shader, location: GLuint, size: GLint, gltype: Glenum, normalize: GLboolean, stride: GLsizei, offset: int) = 
    glEnableVertexAttribArray(location)
    glVertexAttribPointer(location, size, gltype, normalize, stride, cast[pointer](offset));

#uniform setting functions
#note that all of these bind the shader; this is optimized away later

proc findUniform(shader: Shader, name: string): int =
    if shader.uniforms.hasKey(name):
        return shader.uniforms[name]
    let location = glGetUniformLocation(shader.handle, name)
    shader.uniforms[name] = location
    return location

proc seti*(shader: Shader, name: string, value: int) =
    shader.use()
    let loc = shader.findUniform(name)
    if loc != -1: glUniform1i(loc.GLint, value.GLint)

proc setmat4*(shader: Shader, name: string, value: Mat) =
    shader.use()
    let loc = shader.findUniform(name)
    if loc != -1: glUniformMatrix4fv(loc.GLint, 1, false, value.toMat4())

proc setf*(shader: Shader, name: string, value: float) =
    shader.use()
    let loc = shader.findUniform(name)
    if loc != -1: glUniform1f(loc.GLint, value.GLfloat)

proc setf*(shader: Shader, name: string, value1, value2: float) =
    shader.use()
    let loc = shader.findUniform(name)
    if loc != -1: glUniform2f(loc.GLint, value1.GLfloat, value2.GLfloat)

proc setf*(shader: Shader, name: string, value1, value2, value3: float) =
    shader.use()
    let loc = shader.findUniform(name)
    if loc != -1: glUniform3f(loc.GLint, value1.GLfloat, value2.GLfloat, value3.GLfloat)

proc setf*(shader: Shader, name: string, value1, value2, value3, value4: float) =
    shader.use()
    let loc = shader.findUniform(name)
    if loc != -1: glUniform4f(loc.GLint, value1.GLfloat, value2.GLfloat, value3.GLfloat, value4.GLfloat)

#MESH

type VertexAttribute* = object
    componentType: Glenum
    components: GLint
    normalized: bool
    offset: int
    alias: string

#returns the size of avertex attribute in bytes
proc size(attr: VertexAttribute): int =
    return case attr.componentType:
        of cGlFloat, cGlFixed: 4 * attr.components
        of GlUnsignedByte, cGlByte: attr.components
        of GlUnsignedShort, cGlShort: 2 * attr.components
        else: 0

#standard attributes
const attribPos* = VertexAttribute(componentType: cGlFloat, components: 2, alias: "a_position")
const attribPos3* = VertexAttribute(componentType: cGlFloat, components: 3, alias: "a_position")
const attribNormal* = VertexAttribute(componentType: cGlFloat, components: 3, alias: "a_normal")
const attribTexCoords* = VertexAttribute(componentType: cGlFloat, components: 2, alias: "a_texc")
const attribColor* = VertexAttribute(componentType: GlUnsignedByte, components: 4, alias: "a_color", normalized: true)
const attribMixColor* = VertexAttribute(componentType: GlUnsignedByte, components: 4, alias: "a_mixcolor", normalized: true)

type Mesh* = ref object
    vertices*: seq[GLfloat]
    indices*: seq[GLshort]
    attributes: seq[VertexAttribute]
    isStatic: bool
    primitiveType*: GLenum
    vertexSize: Glsizei

#creates a mesh with a set of attributes
proc newMesh*(attrs: seq[VertexAttribute], isStatic: bool = false, primitiveType: Glenum = GlTriangles): Mesh = 
    result = Mesh(isStatic: isStatic, attributes: attrs, primitiveType: primitiveType)

    #calculate total vertex size
    for attr in result.attributes.mitems:
        #calculate vertex offset
        attr.offset = result.vertexSize
        result.vertexSize += attr.size().GLsizei

proc beginBind(mesh: Mesh, shader: Shader) =
    for attrib in mesh.attributes:
        let loc = shader.getAttributeLoc(attrib.alias)
        if loc != -1:
            glEnableVertexAttribArray(loc.GLuint)
            glVertexAttribPointer(loc.GLuint, attrib.components, attrib.componentType, attrib.normalized, mesh.vertexSize, 
                cast[pointer](cast[uint64](mesh.vertices[0].addr) + attrib.offset.uint64));

proc endBind(mesh: Mesh, shader: Shader) =
    for attrib in mesh.attributes:
        if shader.attributes.hasKey(attrib.alias):
            glDisableVertexAttribArray(shader.attributes[attrib.alias].location.GLuint)

proc render*(mesh: Mesh, shader: Shader, count: int = -1) =
    shader.use() #binds the shader if it isn't already bound
    
    let amount = if count < 0: mesh.vertices.len div 4 else: count div 4

    beginBind(mesh, shader)

    if mesh.indices.len == 0:
        glDrawArrays(mesh.primitiveType, 0.GLint, amount.Glint)
    else:
        glDrawElements(mesh.primitiveType,  amount.Glint, GlUnsignedShort, mesh.indices[0].addr)
    
    endBind(mesh, shader)
