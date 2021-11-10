
import ../fmath, ../color, ../mesh, ../shader

#https://github.com/JoeyDeVries/Cell/blob/master/cell/lighting/

#TODO: make components?

#there can only be one of these
type DirectionalLight* = object
  direction*: Vec3
  color*: Color
  intensity*: float32
  castShadow*: bool

type PointLight* = object
  position*: Vec3
  color*: Color
  intensity*: float32
  radius*: float32

type Material* = object
  #TODO how are custom uniform parameters stored? I'd rather not use a table
  id*: int #must be unique
  shader*: Shader
  color*: Color
  depthWrite*: bool
  depthTest*: bool
  blending*: Blending
  shadowCast*: bool
  shadowReceive*: bool

