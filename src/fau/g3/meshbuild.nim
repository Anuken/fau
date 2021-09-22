import fmath3, mesh3, ../color

#add a triangle to the mesh
proc tri*(mesh: Mesh3, v1, v2, v3: Vec3, nor: Vec3, col: Color) =
  let len = mesh.vertices.len
  #TODO minsert?
  mesh.vertices.add vert3(v1, nor, col)
  mesh.vertices.add vert3(v2, nor, col)
  mesh.vertices.add vert3(v3, nor, col)

  mesh.indices.add [Index(len), Index(len + 1), Index(len + 2)]

proc rect*(mesh: Mesh3, v1, v2, v3, v4: Vec3, nor: Vec3, col: Color) =
  let len = mesh.vertices.len
  #TODO minsert?
  mesh.vertices.add [vert3(v1, nor, col), vert3(v2, nor, col), vert3(v3, nor, col), vert3(v4, nor, col)]
  mesh.indices.add [Index(len), Index(len + 1), Index(len + 2), Index(len + 2), Index(len + 3), Index(len)]

#TODO no pos argument?
proc makeCube*(pos: Vec3 = vec3(), size: float32 = 1f, color: Color = colorWhite): Mesh3 =
  result = newMesh[Vert3]()
  var points = [
    vec3(1, 1, 1), 
    vec3(-1, 1, 1),
    vec3(-1, 1, -1),
    vec3(1, 1, -1),

    vec3(1, -1, 1), 
    vec3(-1, -1, 1),
    vec3(-1, -1, -1),
    vec3(1, -1, -1),
  ]

  for point in points.mitems:
    point *= size
  
  #top, bottom
  result.rect(points[0], points[1], points[2], points[3], vec3(0, 1, 0), color)
  result.rect(points[4], points[5], points[6], points[7], vec3(0, -1, 0), color)
  #left, right
  result.rect(points[1], points[2], points[6], points[5], vec3(-1, 0, 0), color)
  result.rect(points[0], points[3], points[7], points[4], vec3(1, 0, 0), color)
  #front, back
  result.rect(points[0], points[1], points[5], points[4], vec3(0, 0, 1), color)
  result.rect(points[2], points[3], points[7], points[6], vec3(0, 0, -1), color)

proc makePlane*(size: float32 = 1f, color: Color = colorWhite): Mesh3 =
  result = newMesh[Vert3]()
  result.rect(
    vec3(-size, 0, -size),
    vec3(size, 0, -size),
    vec3(size, 0, size),
    vec3(-size, 0, size),
    vec3(0, 1f, 0f),
    color
  )