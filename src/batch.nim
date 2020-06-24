import ../graphics, mesh, shader

type Batch* = ref object
    mesh: Mesh
    shader: Shader
    blending: Blending
    lastTexture: Texture
    index: int
    
proc newBatch*(): Batch = 
    result = Batch() #TODO

proc draw*(batch: Batch, region: TexReg, x: float32, y: float32, w: float32, h: float32, originX: float32 = 0, originY: float32 = 0, rotation: float32 = 0) =
    batch.index += 4

proc flush*(batch: Batch) =

    batch.shader.use()
    batch.blending.use()

    batch.mesh.update()
    batch.mesh.render(batch.shader)
    
    batch.index = 0