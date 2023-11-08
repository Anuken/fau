# Wraps OpenGL and provides some basic optimizations to prevent unnecessary state changes.

import gltypes
export gltypes

import glad as wrap
export wrap.supportsVertexArrays, wrap.glVersionMinor, wrap.glVersionMajor

#Thrown when something goes wrong with openGL
type
  GlError* = object of CatchableError

#checks openGL calls for errors when not in release mode
template glCheck(body: untyped) =
  when not defined(release):
    body
    
    #check for errors
    var error = wrap.glGetError()

    if error != GlNoError:
      let message = case error:
        of GL_INVALID_VALUE: "Invalid value"
        of GL_INVALID_OPERATION: "Invalid operation"
        of GL_INVALID_FRAMEBUFFER_OPERATION: "Invalid framebuffer operation"
        of GL_INVALID_ENUM: "Invalid enum"
        of GL_OUT_OF_MEMORY: "Out of memory"
        else: "Code " & $error

      raise newException(GlError, message)

  else:
    body

proc checkGlError*() =
  glCheck: discard

#global variable for storing openGL initialization state
#this is far from a clean solution but I'm not sure where else to put this
var glInitialized* = false

#openGL wrapper functions. these are optimized

#last active texture unit - 0 is default
var 
  lastActiveTextureUnit = 0.GLenum
  #last bound texture2ds, mapping from texture unit to texture handle
  lastBoundTextures: array[32, int]
  #last program activated
  lastProgram = -1
  #last bound buffer
  lastArrayBuffer = -1
  #last bound framebuffer
  lastFramebuffer = -1
  #last glViewport parameters
  lastViewX = -1
  lastViewY = -1
  lastViewW = -1
  lastViewH = -1
  lastClearColor = [0f, 0f, 0f, 0f]
  #enabled state: 0 = unknown, 1 = off 2 = on TODO might be better as a bitset.
  lastEnabled: array[36349, byte]
  #blending S/D factor, set to false (invalid)
  lastSfactor: GLenum = GlFalse
  lastDfactor: GLenum = GlFalse
  #last glCullFace activated
  lastCullFace = GlBack
  #whether depthMask is on
  lastDepthMask = true

#fill with -1, since no texture can have that value
for x in lastBoundTextures.mitems: x = -1

proc glActiveTexture*(texture: GLenum) {.inline.} = 
  #don't active texture0 twice
  if lastActiveTextureUnit == texture: return

  glCheck(): wrap.glActiveTexture(texture)

  lastActiveTextureUnit = texture

proc glAttachShader*(program: GLuint, shader: GLuint) {.inline.} = glCheck(): wrap.glAttachShader(program, shader)
proc glBindAttribLocation*(program: GLuint, index: GLuint, name: cstring) {.inline.} = glCheck(): wrap.glBindAttribLocation(program, index, name)

proc glBindBuffer*(target: GLenum, buffer: GLuint) {.inline.} = 
  #don't bind the same array buffer twice
  #TODO make sure this works
  if target == GlArrayBuffer and buffer.int == lastArrayBuffer: return

  glCheck(): wrap.glBindBuffer(target, buffer)

  if target == GLArrayBuffer: lastArrayBuffer = buffer.int

proc glBindFramebuffer*(target: GLenum, framebuffer: GLuint) {.inline.} = 
  if lastFramebuffer == framebuffer.int: return

  glCheck(): wrap.glBindFramebuffer(target, framebuffer)

  lastFramebuffer = framebuffer.int

proc glBindRenderbuffer*(target: GLenum, renderbuffer: GLuint) {.inline.} = glCheck(): wrap.glBindRenderbuffer(target, renderbuffer)

proc glBindTexture*(target: GLenum, texture: GLuint) {.inline.} = 
  if target == GlTexture2D:
    #get current bound texture unit
    let index = lastActiveTextureUnit.int - GLTexture0.int
    if index >= 0 and index < lastBoundTextures.len:
      #if it was already bound, return
      if lastBoundTextures[index] == texture.int: return
      lastBoundTextures[index] = texture.int

  glCheck(): wrap.glBindTexture(target, texture)

proc glBlendColor*(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) {.inline.} = glCheck(): wrap.glBlendColor(red, green, blue, alpha)
proc glBlendEquation*(mode: GLenum) {.inline.} = glCheck(): wrap.glBlendEquation(mode)
proc glBlendEquationSeparate*(modeRGB: GLenum, modeAlpha: GLenum) {.inline.} = glCheck(): wrap.glBlendEquationSeparate(modeRGB, modeAlpha)

proc glBlendFunc*(sfactor: GLenum, dfactor: GLenum) {.inline.} = 
  if lastSfactor == sfactor and lastDfactor == dfactor: return

  glCheck(): wrap.glBlendFunc(sfactor, dfactor)

  lastSfactor = sfactor
  lastDfactor = dfactor

proc glBlendFuncSeparate*(sfactorRGB: GLenum, dfactorRGB: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum) {.inline.} = glCheck(): wrap.glBlendFuncSeparate(sfactorRGB, dfactorRGB, sfactorAlpha, dfactorAlpha)
proc glBufferData*(target: GLenum, size: GLsizeiptr, data: pointer, usage: GLenum) {.inline.} = glCheck(): wrap.glBufferData(target, size, data, usage)
proc glBufferSubData*(target: GLenum, offset: GLintptr, size: GLsizeiptr, data: pointer) {.inline.} = glCheck(): wrap.glBufferSubData(target, offset, size, data)
proc glCheckFramebufferStatus*(target: GLenum): GLenum {.inline.} = glCheck(): result = wrap.glCheckFramebufferStatus(target)
proc glClear*(mask: GLbitfield) {.inline.} = glCheck(): wrap.glClear(mask)

proc glClearColor*(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) {.inline.} = 
  if red == lastClearColor[0] and green == lastClearColor[1] and blue == lastClearColor[2] and alpha == lastClearColor[3]: return

  glCheck(): wrap.glClearColor(red, green, blue, alpha)

  lastClearColor = [red, green, blue, alpha]

proc glClearDepthf*(d: GLfloat) {.inline.} = glCheck(): wrap.glClearDepthf(d)
proc glClearStencil*(s: GLint) {.inline.} = glCheck(): wrap.glClearStencil(s)
proc glColorMask*(red: GLboolean, green: GLboolean, blue: GLboolean, alpha: GLboolean) {.inline.} = glCheck(): wrap.glColorMask(red, green, blue, alpha)
proc glCompileShader*(shader: GLuint) {.inline.} = glCheck(): wrap.glCompileShader(shader)
#proc glCompressedTexImage2D*(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, data: pointer) {.inline.} = glCheck(): wrap.glCompressedTexImage2D(target, level, internalformat, width, height, border, imageSize, data)
#proc glCompressedTexSubImage2D*(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer) {.inline.} = glCheck(): wrap.glCompressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, imageSize, data)
proc glCopyTexImage2D*(target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint) {.inline.} = glCheck(): wrap.glCopyTexImage2D(target, level, internalformat, x, y, width, height, border)
proc glCopyTexSubImage2D*(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.inline.} = glCheck(): wrap.glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height)
proc glCreateProgram*(): GLuint {.inline.} = glCheck(): result = wrap.glCreateProgram()
proc glCreateShader*(`type`: GLenum): GLuint {.inline.} = glCheck(): result = wrap.glCreateShader(`type`)

proc glCullFace*(mode: GLenum) {.inline.} = 
  if mode == lastCullFace: return
  lastCullFace = mode
  
  glCheck(): wrap.glCullFace(mode)

proc glDeleteBuffer*(buffer: GLuint) {.inline.} = 
  lastArrayBuffer = -1

  glCheck(): wrap.glDeleteBuffer(buffer)

proc glDeleteFramebuffer*(framebuffer: GLuint) {.inline.} = 
  #reset last used buffer when deleted.
  if framebuffer == lastFramebuffer.GLuint: lastFramebuffer = -1

  glCheck(): wrap.glDeleteFramebuffer(framebuffer)

proc glDeleteProgram*(program: GLuint) {.inline.} = 
  #reset last used program when deleted.
  if program == lastProgram.GLuint: lastProgram = -1

  glCheck(): wrap.glDeleteProgram(program)

proc glDeleteRenderbuffer*(renderbuffer: GLuint) {.inline.} = glCheck(): wrap.glDeleteRenderbuffer(renderbuffer)
proc glDeleteShader*(shader: GLuint) {.inline.} = glCheck(): wrap.glDeleteShader(shader)

proc glDeleteTexture*(texture: GLuint) {.inline.} = 
  #clear bound textures, their IDs may be reused after deletion
  for tex in lastBoundTextures.mitems: 
    if tex == texture.int: tex = -1

  glCheck(): wrap.glDeleteTexture(texture)

#TODO
proc glDepthFunc*(`func`: GLenum) {.inline.} = glCheck(): wrap.glDepthFunc(`func`)
proc glDepthMask*(flag: GLboolean) {.inline.} = 
  if lastDepthMask == flag: return

  lastDepthMask = flag
  
  glCheck(): wrap.glDepthMask(flag)
proc glDepthRangef*(n: GLfloat, f: GLfloat) {.inline.} = glCheck(): wrap.glDepthRangef(n, f)
proc glDetachShader*(program: GLuint, shader: GLuint) {.inline.} = glCheck(): wrap.glDetachShader(program, shader)

proc glDisable*(cap: GLenum) {.inline.} = 
  #skip disabling twice
  if lastEnabled[cap.int] == 1: return
  
  glCheck(): wrap.glDisable(cap)
  lastEnabled[cap.int] = 1

proc glDisableVertexAttribArray*(index: GLuint) {.inline.} = glCheck(): wrap.glDisableVertexAttribArray(index)
proc glDrawArrays*(mode: GLenum, first: GLint, count: GLsizei) {.inline.} = glCheck(): wrap.glDrawArrays(mode, first, count)
proc glDrawElements*(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer) {.inline.} = glCheck(): wrap.glDrawElements(mode, count, `type`, indices)

proc glEnable*(cap: GLenum) {.inline.} = 
  #skip enabling twice
  if lastEnabled[cap.int] == 2: return
  
  glCheck(): wrap.glEnable(cap)
  lastEnabled[cap.int] = 2

proc glEnableVertexAttribArray*(index: GLuint) {.inline.} = glCheck(): wrap.glEnableVertexAttribArray(index)
proc glFinish*() {.inline.} = glCheck(): wrap.glFinish()
proc glFramebufferRenderbuffer*(target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint) {.inline.} = glCheck(): wrap.glFramebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer)
proc glFramebufferTexture2D*(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) {.inline.} = glCheck(): wrap.glFramebufferTexture2D(target, attachment, textarget, texture, level)
proc glFrontFace*(mode: GLenum) {.inline.} = glCheck(): wrap.glFrontFace(mode)
proc glGenBuffer*(): GLuint {.inline.} = glCheck(): result = wrap.glGenBuffer()
proc glGenerateMipmap*(target: GLenum) {.inline.} = glCheck(): wrap.glGenerateMipmap(target)
proc glGenFramebuffer*(): GLuint {.inline.} = glCheck(): result = wrap.glGenFramebuffer()
proc glGenRenderbuffer*(): GLuint {.inline.} = glCheck(): result = wrap.glGenRenderbuffer()
proc glGenTexture*(): GLuint {.inline.} = glCheck(): result = wrap.glGenTexture()
proc glGetActiveAttrib*(program: GLuint, index: GLuint, length: var GLsizei, size: var GLint, `type`: var GLenum, name: var string) {.inline.} = glCheck(): wrap.glGetActiveAttrib(program, index, length, size, `type`, name)
proc glGetActiveUniform*(program: GLuint, index: GLuint, length: var GLsizei, size: var GLint, `type`: var GLenum, name: var string) {.inline.} = glCheck(): wrap.glGetActiveUniform(program, index, length, size, `type`, name)
proc glGetAttribLocation*(program: GLuint, name: cstring): GLint {.inline.} = glCheck(): result = wrap.glGetAttribLocation(program, name)
proc glGetError*(): GLenum {.inline.} = glCheck(): result = wrap.glGetError()
proc glGetFloatv*(pname: GLenum): GLfloat {.inline.} = glCheck(): result = wrap.glGetFloatv(pname)
proc glGetIntegerv*(pname: GLenum): GLint {.inline.} = glCheck(): result = wrap.glGetIntegerv(pname)
proc glGetProgramiv*(program: GLuint, pname: GLenum): GLint {.inline.} = glCheck(): result = wrap.glGetProgramiv(program, pname)
proc glGetProgramInfoLog*(program: GLuint): string {.inline.} = glCheck():result =  wrap.glGetProgramInfoLog(program)
proc glGetShaderiv*(shader: GLuint, pname: GLenum): GLint {.inline.} = glCheck(): result = wrap.glGetShaderiv(shader, pname)
proc glGetShaderInfoLog*(shader: GLuint): string {.inline.} = glCheck(): result = wrap.glGetShaderInfoLog(shader)
proc glGetString*(name: GLenum): string {.inline.} = glCheck(): result = wrap.glGetString(name)
proc glGetUniformLocation*(program: GLuint, name: cstring): GLint {.inline.} = glCheck(): result = wrap.glGetUniformLocation(program, name)
proc glGetVertexAttribfv*(index: GLuint, pname: GLenum): GLfloat {.inline.} = glCheck(): result = wrap.glGetVertexAttribfv(index, pname)
proc glGetVertexAttribiv*(index: GLuint, pname: GLenum): GLint {.inline.} = glCheck(): result = wrap.glGetVertexAttribiv(index, pname)
proc glHint*(target: GLenum, mode: GLenum) {.inline.} = glCheck(): wrap.glHint(target, mode)
proc glIsBuffer*(buffer: GLuint): GLboolean {.inline.} = glCheck(): result = wrap.glIsBuffer(buffer)
proc glIsEnabled*(cap: GLenum): GLboolean {.inline.} = glCheck(): result = wrap.glIsEnabled(cap)
proc glIsFramebuffer*(framebuffer: GLuint): GLboolean {.inline.} = glCheck(): result = wrap.glIsFramebuffer(framebuffer)
proc glIsProgram*(program: GLuint): GLboolean {.inline.} = glCheck(): result = wrap.glIsProgram(program)
proc glIsRenderbuffer*(renderbuffer: GLuint): GLboolean {.inline.} = glCheck(): result = wrap.glIsRenderbuffer(renderbuffer)
proc glIsShader*(shader: GLuint): GLboolean {.inline.} = glCheck(): result = wrap.glIsShader(shader)
proc glIsTexture*(texture: GLuint): GLboolean {.inline.} = glCheck(): result = wrap.glIsTexture(texture)
proc glLineWidth*(width: GLfloat) {.inline.} = glCheck(): wrap.glLineWidth(width)
proc glLinkProgram*(program: GLuint) {.inline.} = glCheck(): wrap.glLinkProgram(program)
proc glPixelStorei*(pname: GLenum, param: GLint) {.inline.} = glCheck(): wrap.glPixelStorei(pname, param)
proc glPolygonOffset*(factor: GLfloat, units: GLfloat) {.inline.} = glCheck(): wrap.glPolygonOffset(factor, units)
proc glReadPixels*(x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.inline.} = glCheck(): wrap.glReadPixels(x, y, width, height, format, `type`, pixels)
proc glRenderbufferStorage*(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei) {.inline.} = glCheck(): wrap.glRenderbufferStorage(target, internalformat, width, height)
proc glSampleCoverage*(value: GLfloat, invert: GLboolean) {.inline.} = glCheck(): wrap.glSampleCoverage(value, invert)
proc glScissor*(x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.inline.} = glCheck(): wrap.glScissor(x, y, width, height)
proc glShaderSource*(shader: GLuint, source: string) {.inline.} = glCheck(): wrap.glShaderSource(shader, source)
proc glStencilFunc*(`func`: GLenum, `ref`: GLint, mask: GLuint) {.inline.} = glCheck(): wrap.glStencilFunc(`func`, `ref`, mask)
proc glStencilFuncSeparate*(face: GLenum, `func`: GLenum, `ref`: GLint, mask: GLuint) {.inline.} = glCheck(): wrap.glStencilFuncSeparate(face, `func`, `ref`, mask)
proc glStencilMask*(mask: GLuint) {.inline.} = glCheck(): wrap.glStencilMask(mask)
proc glStencilMaskSeparate*(face: GLenum, mask: GLuint) {.inline.} = glCheck(): wrap.glStencilMaskSeparate(face, mask)
proc glStencilOp*(fail: GLenum, zfail: GLenum, zpass: GLenum) {.inline.} = glCheck(): wrap.glStencilOp(fail, zfail, zpass)
proc glStencilOpSeparate*(face: GLenum, sfail: GLenum, dpfail: GLenum, dppass: GLenum) {.inline.} = glCheck(): wrap.glStencilOpSeparate(face, sfail, dpfail, dppass)
proc glTexImage2D*(target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.inline.} = glCheck(): wrap.glTexImage2D(target, level, internalformat, width, height, border, format, `type`, pixels)
proc glTexParameterf*(target: GLenum, pname: GLenum, param: GLfloat) {.inline.} = glCheck(): wrap.glTexParameterf(target, pname, param)
proc glTexParameterfv*(target: GLenum, pname: GLenum): GLfloat {.inline.} = glCheck(): result = wrap.glTexParameterfv(target, pname)
proc glTexParameteri*(target: GLenum, pname: GLenum, param: GLint) {.inline.} = glCheck(): wrap.glTexParameteri(target, pname, param)
proc glTexParameteriv*(target: GLenum, pname: GLenum): GLint {.inline.} = glCheck(): result = wrap.glTexParameteriv(target, pname)
proc glTexSubImage2D*(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.inline.} = glCheck(): wrap.glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, `type`, pixels)
proc glUniform1f*(location: GLint, v0: GLfloat) {.inline.} = glCheck(): wrap.glUniform1f(location, v0)
proc glUniform1fv*(location: GLint, count: GLsizei, value: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glUniform1fv(location, count, value)
proc glUniform1i*(location: GLint, v0: GLint) {.inline.} = glCheck(): wrap.glUniform1i(location, v0)
proc glUniform1iv*(location: GLint, count: GLsizei, value: openArray[GLint]) {.inline.} = glCheck(): wrap.glUniform1iv(location, count, value)
proc glUniform2f*(location: GLint, v0: GLfloat, v1: GLfloat) {.inline.} = glCheck(): wrap.glUniform2f(location, v0, v1)
proc glUniform2fv*(location: GLint, count: GLsizei, value: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glUniform2fv(location, count, value)
proc glUniform2i*(location: GLint, v0: GLint, v1: GLint) {.inline.} = glCheck(): wrap.glUniform2i(location, v0, v1)
proc glUniform2iv*(location: GLint, count: GLsizei, value: openArray[GLint]) {.inline.} = glCheck(): wrap.glUniform2iv(location, count, value)
proc glUniform3f*(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) {.inline.} = glCheck(): wrap.glUniform3f(location, v0, v1, v2)
proc glUniform3fv*(location: GLint, count: GLsizei, value: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glUniform3fv(location, count, value)
proc glUniform3i*(location: GLint, v0: GLint, v1: GLint, v2: GLint) {.inline.} = glCheck(): wrap.glUniform3i(location, v0, v1, v2)
proc glUniform3iv*(location: GLint, count: GLsizei, value: openArray[GLint]) {.inline.} = glCheck(): wrap.glUniform3iv(location, count, value)
proc glUniform4f*(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat) {.inline.} = glCheck(): wrap.glUniform4f(location, v0, v1, v2, v3)
proc glUniform4fv*(location: GLint, count: GLsizei, value: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glUniform4fv(location, count, value)
proc glUniform4i*(location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint) {.inline.} = glCheck(): wrap.glUniform4i(location, v0, v1, v2, v3)
proc glUniform4iv*(location: GLint, count: GLsizei, value: openArray[GLint]) {.inline.} = glCheck(): wrap.glUniform4iv(location, count, value)
proc glUniformMatrix2fv*(location: GLint, count: GLsizei, transpose: GLboolean, value: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glUniformMatrix2fv(location, count, transpose, value)
proc glUniformMatrix3fv*(location: GLint, count: GLsizei, transpose: GLboolean, value: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glUniformMatrix3fv(location, count, transpose, value)
proc glUniformMatrix4fv*(location: GLint, count: GLsizei, transpose: GLboolean, value: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glUniformMatrix4fv(location, count, transpose, value)

proc glUseProgram*(program: GLuint) {.inline.} = 
  #don't use programs twice
  if lastProgram == program.int: return

  glCheck(): wrap.glUseProgram(program)
  lastProgram = program.int

proc glValidateProgram*(program: GLuint) {.inline.} = glCheck(): wrap.glValidateProgram(program)
proc glVertexAttrib1f*(index: GLuint, x: GLfloat) {.inline.} = glCheck(): wrap.glVertexAttrib1f(index, x)
proc glVertexAttrib1fv*(index: GLuint, v: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glVertexAttrib1fv(index, v)
proc glVertexAttrib2f*(index: GLuint, x: GLfloat, y: GLfloat) {.inline.} = glCheck(): wrap.glVertexAttrib2f(index, x, y)
proc glVertexAttrib2fv*(index: GLuint, v: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glVertexAttrib2fv(index, v)
proc glVertexAttrib3f*(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat) {.inline.} = glCheck(): wrap.glVertexAttrib3f(index, x, y, z)
proc glVertexAttrib3fv*(index: GLuint, v: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glVertexAttrib3fv(index, v)
proc glVertexAttrib4f*(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.inline.} = glCheck(): wrap.glVertexAttrib4f(index, x, y, z, w)
proc glVertexAttrib4fv*(index: GLuint, v: openArray[GLfloat]) {.inline.} = glCheck(): wrap.glVertexAttrib4fv(index, v)
proc glVertexAttribPointer*(index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei, pointer: pointer) {.inline.} = glCheck(): wrap.glVertexAttribPointer(index, size, `type`, normalized, stride, pointer)

proc glViewport*(x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.inline.} = 
  if x == lastViewX and y == lastViewY and width == lastViewW and height == lastViewH: return

  glCheck(): wrap.glViewport(x, y, width, height)

  (lastViewX, lastViewY, lastViewW, lastViewH) = (x, y, width, height)

proc glGenVertexArray*(): GLuint {.inline.} = glCheck(): result = wrap.glGenVertexArray()
proc glDeleteVertexArray*(varray: GLuint) {.inline.} = glCheck(): wrap.glDeleteVertexArray(varray)
proc glBindVertexArray*(varray: GLuint) {.inline.} = glCheck(): wrap.glBindVertexArray(varray)