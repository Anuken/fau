import common, math, algorithm, sugar

type 
  ReqKind = enum
    reqVert,
    reqRect,
    reqProc
  Req = object
    blend: Blending
    z: float32
    case kind: ReqKind:
    of reqVert:
      verts: array[24, Glfloat]
      tex: Texture
    of reqRect:
      patch: Patch
      x, y, originX, originY, width, height, rotation, color, mixColor: float32
    of reqProc:
      draw: proc()

#this batch wraps another batch and sorts its requests.
type SortBatch* = ref object of GenericBatch
  reqs: seq[Req]
  base: GenericBatch

proc newSortBatch*(batch: GenericBatch): SortBatch = 
  result = SortBatch(base: batch)

  result.flushProc = proc() = 
    if fuse.batchSort:
      #sort requests by their Z value
      result.reqs.sort((a, b) => a.z.cmp b.z)
    
    for req in result.reqs:
      fuse.batchBlending = req.blend
      case req.kind:
      of reqVert:
        result.base.drawVertProc(req.tex, req.verts)
      of reqRect:
        result.base.drawProc(req.patch, req.x, req.y, req.width, req.height, req.originX, req.originY, req.rotation, req.color, req.mixColor)
      of reqProc:
        req.draw()

    #flush the base batch
    result.base.flushProc()
  
  result.drawProc = proc(region: Patch, x, y, width, height: float32, originX = 0'f32, originY = 0'f32, rotation = 0'f32, color = colorWhiteF, mixColor = colorClearF) = 
    if fuse.batchSort:
      result.reqs.add(Req(kind: reqRect, patch: region, x: x, y: y, width: width, height: height, originX: originX, originY: originY, rotation: rotation, color: color, mixColor: mixColor, blend: fuse.batchBlending, z: fuse.batchZ))
    else:
      result.base.drawProc(region, x, y, width, height, originX, originY, rotation, color, mixColor)
  
  result.drawVertProc = proc(texture: Texture, vertices: array[24, Glfloat]) {.nosinks.} = 
    if fuse.batchSort:
      result.reqs.add(Req(kind: reqVert, tex: texture, verts: vertices, blend: fuse.batchBlending, z: fuse.batchZ))
    else:
      result.base.drawVertProc(texture, vertices)
  
  result.drawBlock = proc(val: proc()) =
    if fuse.batchSort:
      result.reqs.add(Req(kind: reqProc, draw: val))
    else:
      val()