
proc `=destroy`*[T](mesh: var MeshObj[T]) =
  if mesh.vertexBuffer != 0 and glInitialized:
    glDeleteBuffer(mesh.vertexBuffer)
    mesh.vertexBuffer = 0
  if mesh.indexBuffer != 0 and glInitialized:
    glDeleteBuffer(mesh.indexBuffer)
    mesh.indexBuffer = 0

#marks a mesh as modified, so its vertices get reuploaded
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
proc newMesh*[T](isStatic: bool = false, primitiveType: Glenum = GlTriangles, vertices: seq[T] = @[], indices: seq[Index] = @[]): Mesh[T] = 
  result = Mesh[T](
    isStatic: isStatic, 
    primitiveType: primitiveType, 
    vertices: vertices, 
    indices: indices,
    modifiedVert: true,
    modifiedInd: true,
    vertexBuffer: glGenBuffer(),
    indexBuffer: glGenBuffer()
  )

proc newMesh2*(isStatic: bool = false, primitiveType: Glenum = GlTriangles, vertices: seq[Vert2] = @[], indices: seq[Index] = @[]): Mesh =
  newMesh[Vert2](isStatic, primitiveType, vertices, indices)

#TODO! do not enable unnecessary attributes
#is is assumed the mesh is called 'mesh', the shader is called 'shader' and vsize is the vertex size
macro enableAttributes(vert: typed): untyped =
  let vertexType = vert.getType()[1]
  result = newStmtList()

  for identDefs in getImpl(vertexType)[2][2]:
    let t = identDefs[^2]
    let fieldType = t.getType()
    let typeName = $t

    for i in 0 .. identDefs.len - 3:
      let field = if identDefs[i].kind == nnkPostfix: identDefs[i][1] else: identDefs[i]
      let name = $field
      let alias = "a_" & name
      
      var components = 1
      var componentType = cGlFloat
      var normalized = false

      #using string comparisons here because Vec3 isn't imported; otherwise I would use 'is'
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

      result.add quote do:
        let loc = shader.getAttributeLoc(`alias`)
        if loc != -1:
          glEnableVertexAttribArray(loc.GLuint)
          glVertexAttribPointer(loc.GLuint, `components`, `componentType`, `normalized`.GLboolean, vsize.GLsizei, cast[pointer](`vertexType`.offsetOf(`field`)))

#TODO! do not disable attributes, only do it in enableAttributes if there is a mismatch!
#is is assumed the mesh is called 'mesh' and the shader is called 'shader'
macro disableAttributes(vert: typed): untyped =
  let vertexType = vert.getType()[1]
  result = newStmtList()

  for identDefs in getImpl(vertexType)[2][2]:
    for i in 0 .. identDefs.len - 3:
      let alias = "a_" & $identDefs[i]

      result.add quote do:
        if shader.attributes.hasKey(`alias`):
          glDisableVertexAttribArray(shader.attributes[`alias`].location.GLuint)

proc beginBind[T](mesh: Mesh[T], shader: Shader) =
  #draw usage
  let usage = if mesh.isStatic: GlStaticDraw else: GlStreamDraw

  #bind the vertex buffer
  glBindBuffer(GlArrayBuffer, mesh.vertexBuffer)

  #bind indices if there are any
  if mesh.indices.len > 0:
    glBindBuffer(GlElementArrayBuffer, mesh.indexBuffer)

  let vsize = mesh.vertexSize

  #update vertices if modified
  if mesh.modifiedVert:
    glBufferData(GlArrayBuffer, mesh.vertices.len * vsize, mesh.vertices[0].addr, usage)
  elif mesh.vertSlice.b != 0:
    glBufferSubData(GlArrayBuffer, mesh.vertSlice.a * vsize, mesh.vertSlice.len * vsize, mesh.vertices[mesh.vertSlice.a].addr)
  
  #update indices if relevant and modified
  if mesh.modifiedInd and mesh.indices.len > 0:
    glBufferData(GlElementArrayBuffer, mesh.indices.len * 2, mesh.indices[0].addr, usage)
  elif mesh.indSlice.b != 0 and mesh.indices.len > 0:
    glBufferSubData(GlElementArrayBuffer, mesh.indSlice.a * 2, mesh.indSlice.len * 2, mesh.indices[mesh.indSlice.a].addr)
  
  mesh.vertSlice = 0..0
  mesh.indSlice = 0..0
  mesh.modifiedVert = false
  mesh.modifiedInd = false

  enableAttributes(T)

proc endBind[T](mesh: Mesh[T], shader: Shader) =
  #TODO may not be necessary
  disableAttributes(T)

#offset and count are in vertices, not floats!
proc render*[T](mesh: Mesh[T], shader: Shader, offset = 0, count = -1, depth = false, writeDepth = true, blend = blendDisabled) =
  shader.use() #binds the shader if it isn't already bound

  beginBind(mesh, shader)

  #set up depth buffer info
  if depth:
    glEnable(GlDepthTest)
  else:
    glDisable(GlDepthTest)

  glDepthMask(depth and writeDepth)

  #set up blending state
  if blend == blendDisabled:
    glDisable(GLBlend)
  else:
    glEnable(GlBlend)
    glBlendFunc(blend.src, blend.dst)

  let vsize = mesh.vertexSize
  if mesh.indices.len == 0: #TODO vsize incorrect
    let pcount = if count < 0: mesh.vertices.len else: count
    glDrawArrays(mesh.primitiveType, offset.GLint, (vsize * pcount).GLsizei)
  else:
    let pcount = if count < 0: mesh.indices.len else: count
    glDrawElements(mesh.primitiveType, pcount.Glint, GlUnsignedShort, cast[pointer](offset * Glushort.sizeof))
  
  endBind(mesh, shader)

template vert2*(apos, auv: Vec2, acolor = colorWhite, amixcolor = colorClear): Vert2 = Vert2(pos: apos, uv: auv, color: acolor, mixcolor: amixcolor)
template vert2*(x, y, u, v: float32, acolor = colorWhite, amixcolor = colorClear): Vert2 = Vert2(pos: vec2(x, y), uv: vec2(u, v), color: acolor, mixcolor: amixcolor)
template svert2*(x, y, u, v: float32): SVert2 = SVert2(pos: vec2(x, y), uv: vec2(u, v))

#creates a mesh with position and tex coordinate attributes that covers the screen.
proc newScreenMesh*(): SMesh = 
  newMesh[SVert2](isStatic = true, primitiveType = GlTriangleFan, vertices = @[
    svert2(-1f, -1, 0, 0), 
    svert2(1, -1, 1, 0), 
    svert2(1, 1, 1, 1), 
    svert2(-1, 1, 0, 1)
  ])
