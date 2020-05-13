import ../gl, shader

type VertexAttribute* = object
    componentType: GLuint
    components: int
    normalized: bool
    offset: int
    alias: string

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

proc render*(mesh: Mesh, shader: Shader) =
    glBindBuffer(GL_ARRAY_BUFFER, mesh.vertexHandle)

    if mesh.dirty:
        mesh.dirty = false
        glBufferData(GL_ARRAY_BUFFER, mesh.vertices.len, mesh.vertices, if mesh.isStatic: GL_STATIC_DRAW else: GL_DYNAMIC_DRAW)

    #[
     for(int i = 0; i < numAttributes; i++){
                final VertexAttribute attribute = attributes.get(i);
                final int location = shader.getAttributeLocation(attribute.alias);
                if(location < 0) continue;
                shader.enableVertexAttribute(location);

                shader.setVertexAttribute(location, attribute.numComponents, attribute.type, attribute.normalized,
                attributes.vertexSize, attribute.offset);
            }
    ]#

    for attrib in mesh.attributes:
        let location = shader.getAttribute(attrib.alias)

    glDrawArrays(mesh.primitiveType, 0.GLint, mesh.vertices.len.GLint)

    glBindBuffer(GL_ARRAY_BUFFER, 0)

#proc beginBind(mesh: Mesh, shader: Shader) =
#    glBindBuffer(GL_ARRAY_BUFFER, mesh.vertexHandle)

#proc endBind(mesh: Mesh, shader: Shader) =
#    glBindBuffer(GL_ARRAY_BUFFER, 0)
