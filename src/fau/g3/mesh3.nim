import fmath3, ../mesh, ../color
export mesh

#generic 3D vertex with a position, normal, color and UV
type Vert3* = object
  pos*: Vec3
  #TODO: this can be packed as 3 bytes with 1 byte wasted, which would save 8 bytes of space
  #alternatively this can be 3 shorts with 2 bytes wated, which saves 4 bytes of space
  normal*: Vec3
  #TODO color may be optional for some models...
  color*: Color
  #TODO UVs can be a normalized (u)int16 pair, which would save 4 bytes of space
  uv*: Vec2

#basic 3D mesh
type Mesh3* = Mesh[Vert3]

template vert3*(apos, anormal: Vec3, col: Color): Vert3 = Vert3(pos: apos, normal: anormal, color: col)