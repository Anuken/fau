import graphics, core, math

const vertexSize = 6
const spriteSize = 4 * vertexSize

type Batch* = ref object
    mesh: Mesh
    shader: Shader
    blending: Blending
    lastTexture: Texture
    mat: Mat
    index: int
    size: int
    colorPack: float32
    mixColorPack: float32
    
proc newBatch*(size: int = 8192): Batch = 
    result = Batch(
        mesh: newMesh(@[attribPos, attribTexCoords, attribColor, attribMixColor]),
        blending: blendNormal, 
        size: size * spriteSize
    )

    result.mesh.vertices = newSeq[Glfloat](size * spriteSize)
    result.mat = ortho(0.0, 0.0, screenW.float32, screenH.float32)
    result.colorPack = rgba(1.0, 1.0, 1.0, 1.0).toFloat

    #set up default indices
    let len = size * 6
    result.mesh.indices = newSeq[Glshort](len)
    var j = 0
    var i = 0
    
    while i < len:
        result.mesh.indices[i] = j.Glshort
        result.mesh.indices[i + 1] = (j+1).Glshort
        result.mesh.indices[i + 2] = (j+2).Glshort
        result.mesh.indices[i + 3] = (j+2).Glshort
        result.mesh.indices[i + 4] = (j+3).Glshort
        result.mesh.indices[i + 5] = (j).Glshort
        i += 6
        j += 4
    
    #create default shader
    result.shader = newShader(
    """
    attribute vec4 a_position;
    attribute vec4 a_color;
    attribute vec2 a_texc;
    attribute vec4 a_mixcolor;
    uniform mat4 u_proj;
    varying vec4 v_color;
    varying vec4 v_mixcolor;
    varying vec2 v_texc;

    void main(){
        v_color = a_color;
        v_mixcolor = a_mixcolor;
        v_texc = a_texc;
        gl_Position = u_proj * a_position;
    }
    """,
    """
    varying lowp vec4 v_color;
    varying lowp vec4 v_mixcolor;
    varying vec2 v_texc;
    uniform sampler2D u_texture;

    void main(){
        vec4 c = texture2D(u_texture, v_texc);
        gl_FragColor = v_color * mix(c, vec4(v_mixcolor.rgb, c.a), v_mixcolor.a);
    }
    """)

#TODO these colors methods are bad style - no sense simply copying libGDX's color code.

proc `color=`*(batch: Batch, color: Color) =
    batch.colorPack = color.toFloat()
    
proc `mixColor=`*(batch: Batch, color: Color) =
    batch.colorPack = color.toFloat()

proc flush*(batch: Batch) =
    if batch.index == 0: return

    batch.shader.seti("u_texture", 0)
    batch.shader.setmat4("u_proj", batch.mat)

    batch.blending.use()

    batch.mesh.render(batch.shader, count = batch.index)
    
    batch.index = 0

proc `mat=`*(batch: Batch, mat: Mat) = 
    batch.flush()
    batch.mat = mat

proc prepare(batch: Batch, texture: Texture) =
    if batch.lastTexture != texture or batch.index >= batch.size:
        batch.flush()
        batch.lastTexture = texture


proc draw*(batch: Batch, region: Patch, x: float32, y: float32, width: float32, height: float32, originX: float32 = 0, originY: float32 = 0, rotation: float32 = 0) =
    batch.prepare(region.texture)

    #bottom left and top right corner points relative to origin
    let worldOriginX = x + originX
    let worldOriginY = y + originY
    let fx = -originX
    let fy = -originY
    let fx2 = width - originX
    let fy2 = height - originY

    #rotate
    let cos = cos(rotation.degToRad)
    let sin = sin(rotation.degToRad)

    let x1 = cos * fx - sin * fy + worldOriginX
    let y1 = sin * fx + cos * fy + worldOriginY
    let x2 = cos * fx - sin * fy2 + worldOriginX
    let y2 = sin * fx + cos * fy2 + worldOriginY
    let x3 = cos * fx2 - sin * fy2 + worldOriginX
    let y3 = sin * fx2 + cos * fy2 + worldOriginY
    let x4 = x1 + (x3 - x2)
    let y4 = y3 - (y2 - y1)

    let u = region.u
    let v = region.v2
    let u2 = region.u2
    let v2 = region.v

    let color = batch.colorPack
    let mixColor = batch.mixColorPack
    let idx = batch.index
    var vertices = batch.mesh.vertices

    vertices[idx] = x1
    vertices[idx + 1] = y1
    vertices[idx + 2] = u
    vertices[idx + 3] = v
    vertices[idx + 4] = color
    vertices[idx + 5] = mixColor

    vertices[idx + 6] = x2
    vertices[idx + 7] = y2
    vertices[idx + 8] = u
    vertices[idx + 9] = v2
    vertices[idx + 10] = color
    vertices[idx + 11] = mixColor

    vertices[idx + 12] = x3
    vertices[idx + 13] = y3
    vertices[idx + 14] = u2
    vertices[idx + 15] = v2
    vertices[idx + 16] = color
    vertices[idx + 17] = mixColor

    vertices[idx + 18] = x4
    vertices[idx + 19] = y4
    vertices[idx + 20] = u2
    vertices[idx + 21] = v
    vertices[idx + 22] = color
    vertices[idx + 23] = mixColor

    batch.index += spriteSize

