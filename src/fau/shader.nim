
import tables, gl/[glproc, gltypes], strutils, fmath, color, macros, texture, framebuffer

#Internal shader attribute.
type ShaderAttr* = object
  name*: string
  gltype*: GLenum
  size*: GLint
  length*: Glsizei
  location*: GLint

#OpenGL Shader program.
type ShaderObj* = object
  handle, vertHandle, fragHandle: GLuint
  compileLog: string
  compiled: bool
  uniforms: Table[string, int]
  attributes: Table[string, ShaderAttr]
type Shader* = ref ShaderObj

type Sampler* = object
  texture*: Texture
  index*: int

const screenspaceVertex* = """
attribute vec4 a_pos;
attribute vec2 a_uv;
varying vec2 v_uv;

void main(){
    v_uv = a_uv;
    gl_Position = a_pos;
}
"""

const screenspaceFragment* = """
uniform sampler2D u_texture;
varying vec2 v_uv;

void main(){
  gl_FragColor = texture2D(u_texture, v_uv);
}
"""

proc `=destroy`*(shader: var ShaderObj) =
  `=destroy`(shader.compileLog)
  `=destroy`(shader.uniforms)
  `=destroy`(shader.attributes)

  if shader.handle != 0 and glInitialized:
    glDeleteProgram(shader.handle)
    if shader.vertHandle != 0: glDeleteShader(shader.vertHandle)
    if shader.fragHandle != 0: glDeleteShader(shader.fragHandle)

    shader.handle = 0
    shader.vertHandle = 0
    shader.fragHandle = 0

proc loadSource(shader: Shader, shaderType: GLenum, source: string): GLuint =
  result = glCreateShader(shaderType)
  if result == 0: return 0.GLuint

  #attach source
  glShaderSource(result, source)
  glCompileShader(result)

  #check compiled status
  let compiled = glGetShaderiv(result, GlCompileStatus)

  if compiled == 0:
    shader.compiled = false
    shader.compileLog &= ("[" & (if shaderType == GlFragmentShader: "fragment shader" else: "vertex shader") & "]\n")
    let infoLen = glGetShaderiv(result, GlInfoLogLength)
    if infoLen > 1:
      let infoLog = glGetShaderInfoLog(result)
      shader.compileLog &= infoLog #append reason to log
    glDeleteShader(result)

#returns the unique ID of the shader - currently this is just the GL handle
proc id*(shader: Shader): int {.inline.} = shader.handle.int

#internal use only!
proc use*(shader: Shader) =
  glUseProgram(shader.handle)

#TODO better preprocessor.
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
  
  result.vertHandle = loadSource(result, GlVertexShader, preprocess(vertexSource, false))
  result.fragHandle = loadSource(result, GlFragmentShader, preprocess(fragmentSource, true))

  if not result.compiled:
    raise newException(GLerror, "Failed to compile shader: \n" & result.compileLog)

  var program = glCreateProgram()
  glAttachShader(program, result.vertHandle)
  glAttachShader(program, result.fragHandle)
  glLinkProgram(program)

  let status = glGetProgramiv(program, GlLinkStatus)

  if status == 0:
    let infoLen = glGetProgramiv(program, GlInfoLogLength)
    if infoLen > 1:
      let infoLog = glGetProgramInfoLog(program)
      result.compileLog &= infoLog #append reason to log
      result.compiled = false
    raise Exception.newException("Failed to link shader: " & result.compileLog) 

  result.handle = program

  #fetch attributes for shader
  let numAttrs = glGetProgramiv(program, GlActiveAttributes)
  for i in 0..<numAttrs:
    var alen: GLsizei
    var asize: GLint
    var atype: GLenum
    var aname: string
    glGetActiveAttrib(program, i.GLuint, alen, asize, atype, aname)
    let aloc = glGetAttribLocation(program, aname.cstring)

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

proc sampler*(tex: Texture, index = 0): Sampler = Sampler(texture: tex, index: index)
proc sampler*(buf: Framebuffer, index = 0): Sampler = Sampler(texture: buf.texture, index: index)

#TODO all of these functions should not be exported

template withUniform(shader: Shader, name: string, body: untyped) =
  shader.use()
  let loc {.inject.} = shader.findUniform(name)
  if loc != -1:
    body

proc uniform*(shader: Shader, name: string, value: Sampler) =
  shader.withUniform(name): 
    value.texture.use(value.index)
    glUniform1i(loc.GLint, value.index.GLint)

proc uniform*(shader: Shader, name: string, value: int) =
  shader.withUniform(name): glUniform1i(loc.GLint, value.GLint)

#converts a 2D matrix to 3D and sets it
proc uniform*(shader: Shader, name: string, value: Mat) =
  shader.withUniform(name): glUniformMatrix4fv(loc.GLint, 1, false, value.toMat4())

#sets a 3D matrix; the input value should be a 4x4 matrix
proc uniform*(shader: Shader, name: string, value: array[16, float32]) =
  shader.withUniform(name): glUniformMatrix4fv(loc.GLint, 1, false, value)

proc uniform*(shader: Shader, name: string, value: float32) =
  shader.withUniform(name): glUniform1f(loc.GLint, value)

proc uniform*(shader: Shader, name: string, value: Vec2) =
  shader.withUniform(name): glUniform2f(loc.GLint, value.x, value.y)

proc uniform*(shader: Shader, name: string, value: Vec3) =
  shader.withUniform(name): glUniform3f(loc.GLint, value.x, value.y, value.z)

proc uniform*(shader: Shader, name: string, col: Color) =
  shader.withUniform(name): glUniform4f(loc.GLint, col.r, col.g, col.b, col.a)

#TODO internal use only?
macro uniforms*(shader: Shader, body: untyped): untyped =
  result = newStmtList()

  for a in body:
    let uname = ("u_" & a[0].strVal)
    let ucall = a[1]
    result.add quote do:
      `shader`.uniform(`uname`, `ucall`)