import ../gl, shader, options

type VertexAttribute* = object
    componentType: GLuint
    components: int
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
const attribPos* = VertexAttribute(componentType: cGL_FLOAT, components: 2, alias: "a_position")
const attribPos3* = VertexAttribute(componentType: cGL_FLOAT, components: 3, alias: "a_position")
const attribNormal* = VertexAttribute(componentType: cGL_FLOAT, components: 3, alias: "a_normal")
const attribTexCoords* = VertexAttribute(componentType: cGL_FLOAT, components: 2, alias: "a_tex")
const attribColor* = VertexAttribute(componentType: GL_UNSIGNED_BYTE, components: 4, alias: "a_color", normalized: true)

type Mesh* = ref object
    vertices: seq[GLfloat]
    indices: seq[GLShort]
    attributes: seq[VertexAttribute]
    vertexHandle, indexHandle: GLuint
    isStatic: bool
    dirty: bool
    primitiveType: GLenum
    vertexSize: Glsizei

proc newMesh*(attrs: seq[VertexAttribute], isStatic: bool = false, primitiveType: Glenum = GlTriangles): Mesh = 
    result = Mesh(isStatic: isStatic, attributes: attrs, primitiveType: primitiveType)

    #calculate total vertex size
    for attr in result.attributes.mitems:
        #calculate vertex offset
        attr.offset = result.vertexSize
        result.vertexSize += attr.size().GLsizei

proc beginBind(mesh: Mesh, shader: Shader) =
    glBindBuffer(GL_ARRAY_BUFFER, mesh.vertexHandle)

    if mesh.dirty:
        mesh.dirty = false
        glBufferData(GL_ARRAY_BUFFER, mesh.vertices.len, mesh.vertices, if mesh.isStatic: GL_STATIC_DRAW else: GL_DYNAMIC_DRAW)
    
    for attrib in mesh.attributes:
        let sato = shader.getAttribute(attrib.alias)
        if sato.isSome:
            let sat = sato.get()
            shader.enableAttribute(sat.location.GLuint, sat.size, sat.gltype, attrib.normalized, mesh.vertexSize, attrib.offset)

proc endBind(mesh: Mesh, shader: Shader) =

    for attrib in mesh.attributes:
        shader.disableAttribute(attrib.alias)

    glBindBuffer(GL_ARRAY_BUFFER, 0)

proc render*(mesh: Mesh, shader: Shader) =
    beginBind(mesh, shader)
        
    glDrawArrays(mesh.primitiveType, 0.GLint, mesh.vertices.len.GLint)

    endBind(mesh, shader)

proc dispose*(mesh: Mesh) =
    glBindBuffer(GlArrayBuffer, 0)
    glDeleteBuffer(mesh.vertexHandle)
    glDeleteBuffer(mesh.indexHandle)
