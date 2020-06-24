import gl, strutils, gltypes, nimPNG, tables, options, strformat
export gl

#basic camera
type Camera* = ref object
    x*, y*, w*, h*: float

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

#activate a blending function
proc use*(blend: Blending) = 
    if blend == blendDisabled:
        glDisable(GLBlend)
    else:
        glEnable(GlBlend)
        glBlendFunc(blend.src, blend.dst)

#TEXTURE

#an openGL image
type Texture* = ref object
    handle: Gluint
    uwrap, vwrap: Glenum
    minfilter, magfilter: Glenum
    target: Glenum
    width*, height*: int

#binds the texture
proc use*(texture: Texture) =
    #TODO only texture2D can be bound to
    glBindTexture(texture.target, texture.handle)
    #glActiveTexture(GlTexture0) #TODO necessary, or not?

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
type TexReg* = object
    texture: Texture
    u, v, u2, v2: float32

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

proc newShader*(vertexSource, fragmentSource: string): Shader =
    result = Shader()
    result.uniforms = initTable[string, int]()
    result.compiled = true
    result.vertHandle = loadSource(result, GL_VERTEX_SHADER, vertexSource)
    result.fragHandle = loadSource(result, GL_FRAGMENT_SHADER, fragmentSource)

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

        #TODO remove
        when not defined(release):
            echo fmt"shader attribute name={aname} size={asize} type={atype} len={alen}"

        result.attributes[aname] = ShaderAttr(name: aname, size: asize, length: alen, gltype: atype, location: aloc)


#attribute functions

proc getAttributeLoc*(shader: Shader, alias: string): int = 
    if not shader.attributes.hasKey(alias): return -1
    return shader.attributes[alias].location

proc getAttribute*(shader: Shader, alias: string): Option[ShaderAttr] = 
    if not shader.attributes.hasKey(alias): return none(ShaderAttr)
    return some(shader.attributes[alias])

proc enableAttribute*(shader: Shader, location: GLuint, size: GLint, gltype: Glenum, normalize: GLboolean, stride: GLsizei, offset: int) = 
    glEnableVertexAttribArray(location)
    glVertexAttribPointer(location, size, gltype, normalize, stride, cast[pointer](offset));

proc disableAttribute*(shader: Shader, alias: string) = 
    if shader.attributes.hasKey(alias):
        glDisableVertexAttribArray(shader.attributes[alias].location.GLuint)

#uniform setting functions

proc findUniform(shader: Shader, name: string): int =
    if shader.uniforms.hasKey(name):
        return shader.uniforms[name]
    let location = glGetUniformLocation(shader.handle, name)
    shader.uniforms[name] = location
    return location

proc seti*(shader: Shader, name: string, value: int) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform1i(loc.GLint, value.GLint)

proc setf*(shader: Shader, name: string, value: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform1f(loc.GLint, value.GLfloat)

proc setf*(shader: Shader, name: string, value1, value2: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform2f(loc.GLint, value1.GLfloat, value2.GLfloat)

proc setf*(shader: Shader, name: string, value1, value2, value3: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform3f(loc.GLint, value1.GLfloat, value2.GLfloat, value3.GLfloat)

proc setf*(shader: Shader, name: string, value1, value2, value3, value4: float) =
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
        of cGL_FLOAT, cGL_FIXED: 4 * attr.components
        of GL_UNSIGNED_BYTE, cGL_BYTE: attr.components
        of GL_UNSIGNED_SHORT, cGL_SHORT: 2 * attr.components
        else: 0

#standard attributes
const attribPos* = VertexAttribute(componentType: cGlFloat, components: 2, alias: "a_position")
const attribPos3* = VertexAttribute(componentType: cGlFloat, components: 3, alias: "a_position")
const attribNormal* = VertexAttribute(componentType: cGlFloat, components: 3, alias: "a_normal")
const attribTexCoords* = VertexAttribute(componentType: cGlFloat, components: 2, alias: "a_tex")
const attribColor* = VertexAttribute(componentType: GlUnsignedByte, components: 4, alias: "a_color", normalized: true)

type Mesh* = ref object
    vertices: seq[GLfloat]
    indices: seq[GLShort]
    attributes: seq[VertexAttribute]
    isStatic: bool
    primitiveType*: GLenum
    vertexSize: Glsizei

proc newMesh*(attrs: seq[VertexAttribute], isStatic: bool = false, primitiveType: Glenum = GlTriangles): Mesh = 
    result = Mesh(isStatic: isStatic, attributes: attrs, primitiveType: primitiveType)

    #calculate total vertex size
    for attr in result.attributes.mitems:
        #calculate vertex offset
        attr.offset = result.vertexSize
        result.vertexSize += attr.size().GLsizei

proc `vertices=`*(mesh: Mesh, verts: var seq[GLfloat]) =
    mesh.vertices = verts

proc beginBind(mesh: Mesh, shader: Shader) =
    
    for attrib in mesh.attributes:
        let sato = shader.getAttribute(attrib.alias)
        if sato.isSome:
            let sat = sato.get()

            glEnableVertexAttribArray(sat.location.GLuint)
            glVertexAttribPointer(sat.location.GLuint, attrib.components, attrib.componentType, attrib.normalized, mesh.vertexSize, 
                cast[pointer](cast[int](mesh.vertices[0].addr) + attrib.offset));

proc endBind(mesh: Mesh, shader: Shader) =

    for attrib in mesh.attributes:
        shader.disableAttribute(attrib.alias)

proc render*(mesh: Mesh, shader: Shader) =
    beginBind(mesh, shader)
    
    glDrawArrays(mesh.primitiveType, 0.GLint, mesh.vertices.len.GLint)

    endBind(mesh, shader)
