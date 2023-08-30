import ../mesh, ../framebuffer, ../shader, ../texture, ../fmath, ../color, ../globals, ../draw, strutils

type Blur* = object
  p1, p2: Framebuffer
  shader: Shader
  passes*: int
  scaling*: int

proc newBlur*(scaling: int = 4, passes: int = 1): Blur =
  result.p1 = newFramebuffer(filter = tfLinear)
  result.p2 = newFramebuffer(filter = tfLinear)
  result.scaling = scaling
  result.passes = passes

  result.shader = newShader(
  """ 
  attribute vec4 a_pos;
  attribute vec2 a_uv; 
  uniform vec2 u_dir;
  uniform vec2 u_size;
  varying vec2 v_texCoords0;
  varying vec2 v_texCoords1;
  varying vec2 v_texCoords2;
  varying vec2 v_texCoords3;
  varying vec2 v_texCoords4;
  const vec2 futher = vec2(3.2307692308, 3.2307692308);
  const vec2 closer = vec2(1.3846153846, 1.3846153846);

  void main(){
    vec2 sizeAndDir = u_dir / u_size;
    vec2 f = futher*sizeAndDir;
    vec2 c = closer*sizeAndDir;
    
    v_texCoords0 = a_uv - f;
    v_texCoords1 = a_uv - c;
    v_texCoords2 = a_uv;
    v_texCoords3 = a_uv + c;
    v_texCoords4 = a_uv + f;
    
    gl_Position = a_pos;
  }
  """,
  """
  uniform lowp sampler2D u_texture;
  varying vec2 v_texCoords0;
  varying vec2 v_texCoords1;
  varying vec2 v_texCoords2;
  varying vec2 v_texCoords3;
  varying vec2 v_texCoords4;
  const float center = 0.2270270270;
  const float close = 0.3162162162;
  const float far = 0.0702702703;

  void main(){
    gl_FragColor = far * texture2D(u_texture, v_texCoords0)
        + close * texture2D(u_texture, v_texCoords1)
        + center * texture2D(u_texture, v_texCoords2)
        + close * texture2D(u_texture, v_texCoords3)
        + far * texture2D(u_texture, v_texCoords4);
  }
  """
  )

proc buffer*(blur: Blur, clearColor = colorClear): Framebuffer =
  blur.p1.resize(fau.sizei div blur.scaling)
  blur.p2.resize(fau.sizei div blur.scaling)

  blur.p1.clear(clearColor)
  return blur.p1

proc blit*(blur: Blur, params = meshParams()) =
  
  #no texture
  if blur.p1.texture.isNil: return

  #TODO uniform blocks bad
  blur.shader.uniforms:
    size = blur.p1.size.vec2

  for i in 0..<blur.passes:
    #horizontal
    blit(blur.shader, meshParams(buffer = blur.p2)):
      texture = blur.p1.sampler
      dir = vec2(1, 0)
    #vertical
    blit(blur.shader, meshParams(buffer = blur.p1)):
      texture = blur.p2.sampler
      dir = vec2(0, 1)

  blit(fau.screenspace, params):
    texture = blur.p1.sampler(0)
  