import ../gl, tables

type Shader* = ref object
    handle, vertHandle, fragHandle: GLuint
    compileLog: string
    compiled: bool
    uniforms: Table[string, int]
    attributes: Table[string, int]

proc loadSource(shader: Shader, shaderType: GLenum, source: string): GLuint =
    result = glCreateShader(shaderType)
    if result == 0: return 0.GLuint

    #attach source
    var srcArray = [source.cstring]
    glShaderSource(result, 1, cast[cstringArray](addr srcArray), nil)
    glCompileShader(result)

    #check compiled status
    var compiled: GLint
    glGetShaderiv(result, GL_COMPILE_STATUS, addr compiled)

    if compiled == 0:
        shader.compiled = false
        shader.compileLog &= ("[" & (if shaderType == GL_FRAGMENT_SHADER: "fragment shader" else: "vertex shader") & "]\n")
        var infoLen: GLint
        glGetShaderiv(result, GL_INFO_LOG_LENGTH, addr infoLen)
        if infoLen > 1:
            var infoLog : cstring = cast[cstring](alloc(infoLen + 1))
            glGetShaderInfoLog(result, infoLen, nil, infoLog)
            shader.compileLog &= infoLog #append reason to log
            dealloc(infoLog)
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

    var status: GLint
    glGetProgramiv(program, GL_LINK_STATUS, addr status)

    if status == 0:
        var infoLen: GLint
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, addr infoLen)
        if infoLen > 1:
            var infoLog : cstring = cast[cstring](alloc(infoLen + 1))
            glGetProgramInfoLog(program, infoLen, nil, infoLog)
            result.compileLog &= infoLog #append reason to log
            result.compiled = false
            dealloc(infoLog)
        raise Exception.newException("Failed to link shader: " & result.compileLog) 

    result.handle = program

    #fetch attributes for shader
    var numAttrs: GLint
    glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, addr numAttrs)
    for i in 0..<numAttrs:
        var alen: GLsizei
        var asize: GLint
        var atype: GLenum
        var aname: cstring = cast[cstring](alloc(256))
        glGetActiveAttrib(program, i.GLuint, 256.GLsizei, addr alen, addr asize, addr atype, aname)
        
        dealloc(aname)


#attribute functions

proc getAttributeLoc*(alias: string): int = 
    return -1

#uniform setting functions

proc findUniform(shader: Shader, name: string): int =
    if shader.uniforms.hasKey(name):
        return shader.uniforms[name]
    let location = glGetUniformLocation(shader.handle, name)
    shader.uniforms[name] = location
    return location

proc setf(shader: Shader, name: string, value: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform1f(loc.GLint, value.GLfloat)

proc setf(shader: Shader, name: string, value1, value2: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform2f(loc.GLint, value1.GLfloat, value2.GLfloat)

proc setf(shader: Shader, name: string, value1, value2, value3: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform3f(loc.GLint, value1.GLfloat, value2.GLfloat, value3.GLfloat)

proc setf(shader: Shader, name: string, value1, value2, value3, value4: float) =
    let loc = shader.findUniform(name)
    if loc != -1: glUniform4f(loc.GLint, value1.GLfloat, value2.GLfloat, value3.GLfloat, value4.GLfloat)
    