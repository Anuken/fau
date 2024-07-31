
import tables, gl/[glproc, gltypes], strutils, fmath, color, macros, texture, framebuffer

#Internal shader attribute.
type ShaderAttr* = object
  name*: string
  gltype*: GLenum
  size*: GLint
  length*: Glsizei
  location*: GLint

type ShaderUniType = enum
  unil,
  u1f,
  u2f,
  u3f,
  u4f,
  ucolor,
  u1i,
  u2i,
  umat4,
  umat3conv

type ShaderUniform = object
  loc: int
  case kind: ShaderUniType
  of unil: 
    discard
  of u1f: 
    v1f: float32
  of u2f: 
    v2f: Vec2
  of u3f: 
    v3f: Vec3
  of ucolor: 
    vcolor: Color
  of u4f: 
    v4f: (float32, float32, float32, float32)
  of u1i:
    v1i: int
  of u2i:
    v2i: Vec2i
  of umat4:
    vmat4: array[16, float32]
  of umat3conv:
    mat: Mat

#OpenGL Shader program.
type ShaderObj* = object
  name*: string
  handle, vertHandle, fragHandle: GLuint
  compileLog: string
  compiled: bool
  uniforms: Table[string, ShaderUniform]
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
  `=destroy`(shader.name)
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
  let pre = if fragment: 
    """

    #ifdef GL_ES
    precision mediump float;
    precision mediump int;
    #else
    #define lowp  
    #define mediump 
    #define highp 
    #endif

    """
  else:
    #strip away precision qualifiers
    """

    #ifndef GL_ES
    #define lowp  
    #define mediump 
    #define highp 
    #endif

    """
  
  #GL 3.x requires a version qualifier for the core profile, at least on Mac - no reason to risk issues on other platforms
  if glVersionMajor >= 3 and defined(macosx):
    let version = "#version " & (if glVersionMajor == 3 and glVersionMinor < 2: "130" else: "150")
    result = 
      version & "\n" &
      pre &
      (if fragment: "out lowp vec4 fragColor;\n" else: "") &
      source
      .replace("varying", if fragment: "in" else: "out")
      .replace("attribute", "in")
      .replace("texture2D(", "texture(")
      .replace("textureCube(", "texture(")
      .replace("gl_FragColor", "fragColor")
  else:
    result = pre & source
    
proc newShader*(vertexSource, fragmentSource: string, name = "<unknown>"): Shader =
  result = Shader(name: name)
  result.uniforms = initTable[string, ShaderUniform]()
  result.compiled = true
  
  result.vertHandle = loadSource(result, GlVertexShader, preprocess(vertexSource, false))
  result.fragHandle = loadSource(result, GlFragmentShader, preprocess(fragmentSource, true))

  if not result.compiled:
    raise newException(GLerror, "Failed to compile shader (" & name & "): \n" & result.compileLog)

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

proc findUniform(shader: Shader, name: string): var ShaderUniform =
  if shader.uniforms.hasKey(name):
    return shader.uniforms[name]
  let 
    location = glGetUniformLocation(shader.handle, name)
    uni = ShaderUniform(loc: location)
  shader.uniforms[name] = uni
  return shader.uniforms[name]

proc sampler*(tex: Texture, index = 0): Sampler = Sampler(texture: tex, index: index)
proc sampler*(buf: Framebuffer, index = 0): Sampler = Sampler(texture: buf.texture, index: index)

#TODO all of these functions should not be exported

template withUniform(shader: Shader, name: string, body: untyped) =
  shader.use()
  var uni {.inject.} = shader.findUniform(name)
  let loc {.inject.} = uni.loc
  if loc != -1:
    body

proc uniform*(shader: Shader, name: string, value: Sampler) =
  shader.withUniform(name): 
    value.texture.use(value.index)

    if not (uni.kind == u1i and uni.v1i == value.index):
      glUniform1i(loc.GLint, value.index.GLint)
      shader.uniforms[name] = ShaderUniform(kind: u1i, v1i: value.index, loc: uni.loc)

proc uniform*(shader: Shader, name: string, value: int) =
  shader.withUniform(name): 
    if not (uni.kind == u1i and uni.v1i == value):
      glUniform1i(loc.GLint, value.GLint)
      shader.uniforms[name] = ShaderUniform(kind: u1i, v1i: value, loc: uni.loc)

proc uniform*(shader: Shader, name: string, value: Vec2i) =
  shader.withUniform(name): 
    if not (uni.kind == u2i and uni.v2i == value):
      glUniform2i(loc.GLint, value.x.GLint, value.y.GLint)
      shader.uniforms[name] = ShaderUniform(kind: u2i, v2i: value, loc: uni.loc)

#converts a 2D matrix to 3D and sets it
proc uniform*(shader: Shader, name: string, value: Mat) =
  shader.withUniform(name): 
    if not (uni.kind == umat3conv and uni.mat == value):
      glUniformMatrix4fv(loc.GLint, 1, false, value.toMat4())
      shader.uniforms[name] = ShaderUniform(kind: umat3conv, mat: value, loc: uni.loc)

#sets a 3D matrix; the input value should be a 4x4 matrix
proc uniform*(shader: Shader, name: string, value: array[16, float32]) =
  shader.withUniform(name): 
    if not (uni.kind == umat4 and uni.vmat4 == value):
      glUniformMatrix4fv(loc.GLint, 1, false, value)
      shader.uniforms[name] = ShaderUniform(kind: umat4, vmat4: value, loc: uni.loc)

proc uniform*(shader: Shader, name: string, value: float32) =
  shader.withUniform(name): 
    if not (uni.kind == u1f and uni.v1f == value):
      glUniform1f(loc.GLint, value)
      shader.uniforms[name] = ShaderUniform(kind: u1f, v1f: value, loc: uni.loc)

proc uniform*(shader: Shader, name: string, value: Vec2) =
  shader.withUniform(name): 
    if not (uni.kind == u2f and uni.v2f == value):
      glUniform2f(loc.GLint, value.x, value.y)
      shader.uniforms[name] = ShaderUniform(kind: u2f, v2f: value, loc: uni.loc)

proc uniform*(shader: Shader, name: string, value: Vec3) =
  shader.withUniform(name): 
    if not (uni.kind == u3f and uni.v3f == value):
      glUniform3f(loc.GLint, value.x, value.y, value.z)
      shader.uniforms[name] = ShaderUniform(kind: u3f, v3f: value, loc: uni.loc)

proc uniform*(shader: Shader, name: string, value: array[3, float32]) =
  uniform(shader, name, Vec3(x: value[0], y: value[1], z: value[2]))

proc uniform*(shader: Shader, name: string, value: Color) =
  shader.withUniform(name): 
    if not (uni.kind == ucolor and uni.vcolor == value):
      glUniform4f(loc.GLint, value.r, value.g, value.b, value.a)
      shader.uniforms[name] = ShaderUniform(kind: ucolor, vcolor: value, loc: uni.loc)

proc uniform*(shader: Shader, name: string, value: (float32, float32, float32, float32)) =
  shader.withUniform(name): 
    if not (uni.kind == u4f and uni.v4f == value):
      glUniform4f(loc.GLint, value[0], value[1], value[2], value[3])
      shader.uniforms[name] = ShaderUniform(kind: u4f, v4f: value, loc: uni.loc)

#TODO internal use only?
macro uniforms*(shader: Shader, body: untyped): untyped =
  result = newStmtList()

  for a in body:
    let uname = ("u_" & a[0].strVal)
    let ucall = a[1]
    result.add quote do:
      `shader`.uniform(`uname`, `ucall`)