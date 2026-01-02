
import gl/[glproc, gltypes], color, fmath, shader, framebuffer, macros, screenbuffer

#TODO this is necessary for macros but very hacky, what's the solution?
export glproc, gltypes

#types of blending
type Blending* = object
  src: GLenum = GlSrcAlpha
  dst: GLenum = GlOneMinusSrcAlpha

  srcAlpha: GLenum = GlOne
  dstAlpha: GLenum = GlOneMinusSrcAlpha

  eqRgb: GLenum = GlFuncAdd
  eqAlpha: GLenum = GlFuncAdd

type CullFace* = enum
  cfFront,
  cfBack,
  cfFrontAndBack

#Vertex index.
type Index* = GLushort

#Basic 2D vertex.
type Vert2* = object
  pos: Vec2
  uv: Vec2
  color, mixcolor: Color

#Uncolored 2D vertex
type SVert2* = object
  pos: Vec2
  uv: Vec2
  color: Color

#Generic mesh, optionally indexed.
type MeshObj*[V] = object
  vertices*: seq[V]
  indices*: seq[Index]
  vertexBuffer: GLuint
  indexBuffer: GLuint
  vertexArray: GLuint
  isStatic: bool
  modifiedVert: bool
  modifiedInd: bool
  indexed: bool
  vertSlice: Slice[int]
  indSlice: Slice[int]
  primitiveType: GLenum

  activeAttribs: array[12, int]
  totalActive: int
  attribsValid: bool
#Generic mesh
type Mesh*[T] = ref MeshObj[T]
#Basic 2D mesh
type Mesh2* = Mesh[Vert2]
#Uncolored mesh
type SMesh* = Mesh[SVert2]

type MeshParam* = object
  buffer*: Framebuffer
  offset*: int
  count*: int
  depth*: bool
  writeDepth*: bool
  blend*: Blending
  cullFace*: CullFace
  clip*: Rect
  viewport*: Rect #empty rectangle means use buffer bounds

const
  blendNormal* = Blending(src: GlSrcAlpha, dst: GlOneMinusSrcAlpha, srcAlpha: GlOne, dstAlpha: GlOneMinusSrcAlpha)
  blendMaxAlpha* = Blending(src: GlSrcAlpha, dst: GlOneMinusSrcAlpha, eqAlpha: GlMax)
  blendAdditive* = Blending(src: GlSrcAlpha, dst: GlOne)
  blendPremultiplied* = Blending(src: GlOne, dst: GlOneMinusSrcAlpha)
  blendErase* = Blending(src: GlZero, dst: GlOneMinusSrcAlpha, eqAlpha: GlFuncReverseSubtract)
  #implies glDisable(GlBlend)
  blendDisabled* = Blending(src: GlZero, dst: GlZero)
  blendClip* = Blending(src: GlSrcAlpha, dst: GlOneMinusSrcAlpha, srcAlpha: GlDstAlpha, dstAlpha: GlOneMinusSrcAlpha)

#TODO maybe blending should become an enum
proc blendFromString*(name: string): Blending =
  case name:
  of "", "normal": blendNormal
  of "maxAlpha": blendMaxAlpha
  of "additive", "add": blendAdditive
  of "premultiplied": blendPremultiplied
  of "disabled": blendDisabled
  of "clip": blendClip
  of "erase": blendErase
  else: blendNormal

proc `$`*(blend: Blending): string =
  if blend == blendNormal: "normal"
  elif blend == blendMaxAlpha: "maxAlpha"
  elif blend == blendAdditive: "additive"
  elif blend == blendPremultiplied: "premultiplied"
  elif blend == blendDisabled: "disabled"
  elif blend == blendClip: "clip"
  elif blend == blendErase: "erase"
  else: "normal"

#global vertex array state for optimization
var lastVertexArray = 0

proc `=destroy`*[T](mesh: var MeshObj[T]) =
  `=destroy`(mesh.vertices)
  `=destroy`(mesh.indices)

  if mesh.vertexBuffer != 0 and glInitialized:
    glDeleteBuffer(mesh.vertexBuffer)
    mesh.vertexBuffer = 0
  if mesh.indexBuffer != 0 and glInitialized:
    glDeleteBuffer(mesh.indexBuffer)
    mesh.indexBuffer = 0
  if mesh.vertexArray != 0 and glInitialized:
    glDeleteVertexArray(mesh.vertexArray)
    if lastVertexArray == mesh.vertexArray.int:
      glBindVertexArray(0)
      lastVertexArray = -1
    mesh.vertexArray = 0
    

proc toGlEnum(face: CullFace): GlEnum {.inline.} =
  case face
  of cfFront: GlFront
  of cfBack: GlBack
  of cfFrontAndBack: GlFrontAndBack

#creates a new set of mesh parameters
proc meshParams*(buffer: Framebuffer = screenBufferHack, offset = 0, count = -1, depth = false, writeDepth = true, blend = blendDisabled, cullFace = cfBack, clip = rect(), viewport = rect()): MeshParam {.inline.} = 
  MeshParam(buffer: buffer, offset: offset, count: count, depth: depth, writeDepth: writeDepth, blend: blend, cullFace: cullFace, clip: clip, viewport: viewport)

#returns the unique ID of the shader - currently this is just the GL handle to the vertex buffer
proc id*(mesh: Mesh): int {.inline.} = mesh.vertexBuffer.int

#marks a mesh as modified, so ALL its vertices get reuploaded
proc update*[T](mesh: Mesh[T]) = 
  mesh.modifiedVert = true
  mesh.modifiedInd = true

#schedules an index buffer update
proc updateIndices*[T](mesh: Mesh[T]) = mesh.modifiedInd = true

#schedules a vertex buffer update
proc updateVertices*[T](mesh: Mesh[T]) = mesh.modifiedVert = true

#schedule a vertex buffer update in a slice; grows slice if one is already queued
proc updateVertices*[T](mesh: Mesh[T], slice: Slice[int]) =
  mesh.vertSlice.a = min(mesh.vertSlice.a, slice.a)
  mesh.vertSlice.b = max(mesh.vertSlice.b, slice.b)

#schedule an index buffer update in a slice; grows slice if one is already queued
proc updateIndices*[T](mesh: Mesh[T], slice: Slice[int]) =
  mesh.indSlice.a = min(mesh.indSlice.a, slice.a)
  mesh.indSlice.b = max(mesh.indSlice.b, slice.b)

proc vertexSize*[T](mesh: Mesh[T]): int = T.sizeOf

#creates a mesh with a set of attributes
proc newMesh*[T](isStatic: bool = false, primitiveType: Glenum = GlTriangles, vertices: seq[T] = @[], indices: seq[Index] = @[], update = true, indexed = false): Mesh[T] = 
  result = Mesh[T](
    isStatic: isStatic, 
    primitiveType: primitiveType, 
    vertices: vertices, 
    indices: indices,
    modifiedVert: update,
    modifiedInd: update,
    indexed: indexed,
    vertexBuffer: glGenBuffer(),
    indexBuffer: glGenBuffer(),
  )

  if supportsVertexArrays:
    result.vertexArray = glGenVertexArray()

proc newMesh2*(isStatic: bool = false, primitiveType: Glenum = GlTriangles, vertices: seq[Vert2] = @[], indices: seq[Index] = @[]): Mesh =
  newMesh[Vert2](isStatic, primitiveType, vertices, indices)

#global state for active attribute management - not used for VAOs!
#current active attributes; maps the index to the glEnableVertexAttribArray location
var activeAttribs: array[32, int]
#total active attributes in activeAttribs
var totalActive = 0
#fill with -1s
for i in 0..<activeAttribs.len:
  activeAttribs[i] = -1

proc getVertType(typeName: string): tuple[components: int, componentType: GLenum, normalized: bool] =
  var components = 1
  var componentType = cGlFloat
  var normalized = false

  if typeName == "Vec2":
    components = 2
  elif typeName == "Vec3":
    components = 3
  elif typeName == "Color":
    components = 4
    normalized = true
    componentType = GlUnsignedByte
  elif typeName == "float32": discard #nothing different here
  elif typeName == "uint16": 
    componentType = GlUnsignedShort
    normalized = true
  elif typeName == "int16": 
    componentType = cGlShort
    normalized = true
  elif typeName == "uint8": 
    componentType = GlUnsignedByte
    normalized = true
  elif typeName == "int8": 
    componentType = cGlByte
    normalized = true
  else: error("Unknown vertex component type: " & $typeName)

  return (components, componentType, normalized)

macro enableAttributes(shader: Shader, vert: typed): untyped =
  let vertexType = vert.getType()[1]
  result = newStmtList()
  var attribIndex = 0

  #disable older attributes
  result.add quote do:
    if true:
      #Optimization DOES NOT WORK, because when you call glVertexAttribPointer, that's relative to the currently bound VBO.
      for i in 0..<totalActive:
        if activeAttribs[i] != -1:
          glDisableVertexAttribArray(activeAttribs[i].GLuint)
          activeAttribs[i] = -1

  var resultBody = result[0][0][1]

  for identDefs in getImpl(vertexType)[2][2]:
    let t = identDefs[^2]
    let typeName = $t

    for i in 0 .. identDefs.len - 3:
      let field = if identDefs[i].kind == nnkPostfix: identDefs[i][1] else: identDefs[i]
      let name = $field
      let alias = "a_" & name
      
      var (components, componentType, normalized) = getVertType(typeName)

      resultBody.add quote do:
        let loc = shader.getAttributeLoc(`alias`)
        if loc != -1:
          activeAttribs[`attribIndex`] = loc
          glEnableVertexAttribArray(loc.GLuint)
          glVertexAttribPointer(loc.GLuint, `components`.GLint, `componentType`, `normalized`.GLboolean, vsize.GLsizei, cast[pointer](`vertexType`.offsetOf(`field`)))
        else:
          activeAttribs[`attribIndex`] = -1
      
      attribIndex.inc
  
  resultBody.add quote do:
    totalActive = `attribIndex`

macro enableAttributesVao(shader: Shader, mesh: typed, vert: typed): untyped =
  let vertexType = vert.getType()[1]
  result = newStmtList()
  var attribIndex = 0

  var 
    disableBody = newStmtList()
    enableBody = newStmtList()

  var checkOuter = newStmtList()
  checkOuter.add quote do:
    block:
      `mesh`.attribsValid = true

  var checkBody = checkOuter[0][1]

  enableBody.add quote do:
    glBindBuffer(GlArrayBuffer, `mesh`.vertexBuffer)

  for identDefs in getImpl(vertexType)[2][2]:
    let t = identDefs[^2]
    let typeName = $t

    for i in 0 .. identDefs.len - 3:
      let field = if identDefs[i].kind == nnkPostfix: identDefs[i][1] else: identDefs[i]
      let name = $field
      let alias = "a_" & name
      
      var (components, componentType, normalized) = getVertType(typeName)

      checkBody.add quote do:
        let loc = shader.getAttributeLoc(`alias`)
        if `mesh`.activeAttribs[`attribIndex`] != loc + 1:
          `mesh`.attribsValid = false
          break

      disableBody.add quote do:
        if `mesh`.activeAttribs[`attribIndex`] != 0:
          glDisableVertexAttribArray((`mesh`.activeAttribs[`attribIndex`] - 1).GLuint)
          `mesh`.activeAttribs[`attribIndex`] = 0

      enableBody.add quote do:
        let loc = shader.getAttributeLoc(`alias`)

        if loc != -1:
          `mesh`.activeAttribs[`attribIndex`] = loc + 1
          glEnableVertexAttribArray(loc.GLuint)
          glVertexAttribPointer(loc.GLuint, `components`.GLint, `componentType`, `normalized`.GLboolean, vsize.GLsizei, cast[pointer](`vertexType`.offsetOf(`field`)))
    
      attribIndex.inc
  
  result.add quote do:
    `checkOuter`
    if not `mesh`.attribsValid:
      `disableBody`
      `enableBody`

    `mesh`.totalActive = `attribIndex`

#this binds the VAO (if applicable)
proc updateData*[T](mesh: Mesh[T], vertSlice, indSlice: Slice[int], vertexPtr: pointer = nil, indexPtr: pointer = nil) =

  let 
    vsize = mesh.vertexSize
    usage = if mesh.isStatic: GlStaticDraw else: GlStreamDraw

    updateVertices = vertSlice.b != 0
    updateIndices = indSlice.b != 0 and (mesh.indices.len > 0 or indexPtr != nil)

  #bind VAO if possible
  if supportsVertexArrays and lastVertexArray != mesh.vertexArray.int:
    glBindVertexArray(mesh.vertexArray)
    lastVertexArray = mesh.vertexArray.int

  #NOTE: apparently glBufferSubData is really slow for sprite batching applications. locks. brilliant.

  #bind the vertex buffer
  #for VAOs, you only need to bind when you are setting up the VAO (totalActive == 0) or you want to update its data
  if not supportsVertexArrays or updateVertices or mesh.totalActive == 0:
    glBindBuffer(GlArrayBuffer, mesh.vertexBuffer)

  #update vertices if modified
  if updateVertices:
    glBufferData(GlArrayBuffer, (vertSlice.b - vertSlice.a + 1) * vsize, if vertexPtr != nil: vertexPtr else: mesh.vertices[0].addr, usage)

  #bind indices if there are any
  if (mesh.indices.len > 0 or indexPtr != nil) and (not supportsVertexArrays or updateIndices or mesh.totalActive == 0):
    glBindBuffer(GlElementArrayBuffer, mesh.indexBuffer)

  #update indices if relevant and modified
  if updateIndices:
    glBufferData(GlElementArrayBuffer, (indSlice.b - indSlice.a + 1) * 2, if indexPtr != nil: indexPtr else: mesh.indices[indSlice.a].addr, usage)
  
  mesh.vertSlice = 0..0
  mesh.indSlice = 0..0
  mesh.modifiedVert = false
  mesh.modifiedInd = false

#offset and count are in vertices, not floats!
proc renderInternal[T](mesh: Mesh[T], shader: Shader, args: MeshParam) =
  #bind shader and buffer for drawing to
  shader.use()

  let vsize = mesh.vertexSize

  #use custom viewport if provided
  if args.viewport.w.int > 0 and args.viewport.h.int > 0:
    args.buffer.use(args.viewport.xy.vec2i, args.viewport.wh.vec2i)
  else:
    args.buffer.use()
  
  #enable clipping if necessary, disable if not.
  if args.clip.w.int > 0 and args.clip.h.int > 0:
    glEnable(GlScissorTest)
    glScissor(args.clip.x.GLint, args.clip.y.GLint, args.clip.w.GLsizei, args.clip.h.GLsizei)
  else:
    glDisable(GlScissorTest)

  glCullFace(args.cullFace.toGlEnum)

  #set up depth buffer info
  if args.depth:
    glEnable(GlDepthTest)
  else:
    glDisable(GlDepthTest)

  glDepthMask(args.depth and args.writeDepth)

  #set up blending state
  if args.blend == blendDisabled:
    glDisable(GLBlend)
  else:
    glEnable(GlBlend)
    glBlendFuncSeparate(args.blend.src, args.blend.dst, args.blend.srcAlpha, args.blend.dstAlpha)
    glBlendEquationSeparate(args.blend.eqRgb, args.blend.eqAlpha)

  if mesh.modifiedVert: mesh.vertSlice = 0..<mesh.vertices.len
  if mesh.modifiedInd: mesh.indSlice = 0..<mesh.indices.len

  #note: this binds the VAO regardless of whether anything is actually updated
  updateData(mesh, mesh.vertSlice, mesh.indSlice)
  
  if supportsVertexArrays:
    enableAttributesVao(shader, mesh, T)
  else:
    enableAttributes(shader, T)

  if mesh.indices.len == 0 and not mesh.indexed:
    let pcount = if args.count < 0: mesh.vertices.len else: args.count
    glDrawArrays(mesh.primitiveType, args.offset.GLint, pcount.GLsizei)
  else:
    let pcount = if args.count < 0: mesh.indices.len else: args.count
    glDrawElements(mesh.primitiveType, pcount.Glint, GlUnsignedShort, cast[pointer](args.offset * Index.sizeof))

template render*[T](mesh: Mesh[T], shader: Shader, args: MeshParam, uniformList: untyped) =
  shader.uniforms(uniformList)
  renderInternal(mesh, shader, args)

template vert2*(apos, auv: Vec2, acolor = colorWhite, amixcolor = colorClear): Vert2 = Vert2(pos: apos, uv: auv, color: acolor, mixcolor: amixcolor)
template vert2*(x, y, u, v: float32, acolor = colorWhite, amixcolor = colorClear): Vert2 = Vert2(pos: vec2(x, y), uv: vec2(u, v), color: acolor, mixcolor: amixcolor)
template svert2*(x, y, u, v: float32): SVert2 = SVert2(pos: vec2(x, y), uv: vec2(u, v))

#creates a mesh with position and tex coordinate attributes that covers the screen.
proc newScreenMesh*(): SMesh = 
  newMesh[SVert2](isStatic = true, primitiveType = GlTriangleFan, vertices = @[
    svert2(-1, -1, 0, 0), 
    svert2(1, -1, 1, 0), 
    svert2(1, 1, 1, 1), 
    svert2(-1, 1, 0, 1)
  ])
