import ../mesh, ../framebuffer, ../shader, ../texture, ../fmath, ../color, ../globals, ../draw, std/strutils

type Blur* = object
  p1, p2: Framebuffer
  scene: Framebuffer
  shader: Shader
  blitShader: Shader
  passes*: int
  scaling*: int

proc newBlur*(scaling: int = 4, passes: int = 1): Blur =
  result.p1 = newFramebuffer(filter = tfLinear)
  result.p2 = newFramebuffer(filter = tfLinear)
  result.scene = newFramebuffer(filter = tfLinear)
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
  varying vec2 v_texCoords5;
  varying vec2 v_texCoords6;
  const vec2 near = vec2(1.4231349116, 1.4231349116);
  const vec2 mid = vec2(3.3267017996, 3.3267017996);
  const vec2 far = vec2(5.2429886272, 5.2429886272);

  void main(){
    vec2 sizeAndDir = u_dir / u_size;
    vec2 n = near*sizeAndDir;
    vec2 m = mid*sizeAndDir;
    vec2 f = far*sizeAndDir;
    
    v_texCoords0 = a_uv - f;
    v_texCoords1 = a_uv - m;
    v_texCoords2 = a_uv - n;
    v_texCoords3 = a_uv;
    v_texCoords4 = a_uv + n;
    v_texCoords5 = a_uv + m;
    v_texCoords6 = a_uv + f;
    
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
  varying vec2 v_texCoords5;
  varying vec2 v_texCoords6;
  const float center = 0.1818615348;
  const float near = 0.2843161064;
  const float mid = 0.1065975459;
  const float far = 0.0181555804;

  void main(){
    gl_FragColor = far * texture2D(u_texture, v_texCoords0)
        + mid * texture2D(u_texture, v_texCoords1)
        + near * texture2D(u_texture, v_texCoords2)
        + center * texture2D(u_texture, v_texCoords3)
        + near * texture2D(u_texture, v_texCoords4)
        + mid * texture2D(u_texture, v_texCoords5)
        + far * texture2D(u_texture, v_texCoords6);
  }
  """
  )

  result.blitShader = newShader(
    """
    attribute vec4 a_pos;
    attribute vec2 a_uv;
    varying vec2 v_uv;

    void main(){
        v_uv = a_uv;
        gl_Position = a_pos;
    }
    """,
    """
    uniform sampler2D u_texture;
    uniform sampler2D u_scene;
    uniform float u_alphaScale;
    uniform float u_blurBlend;
    varying vec2 v_uv;

    void main(){
      //mix between the sharp scene and the blurred texture
      vec4 c = mix(texture2D(u_scene, v_uv), texture2D(u_texture, v_uv), u_blurBlend) * u_alphaScale;
      //premultiply alpha
      gl_FragColor = vec4(c.rgb * c.a, c.a);
    }
    """
  )

proc buffer*(blur: Blur, clearColor = colorClear, size = fau.sizei): Framebuffer =
  blur.p1.resize(size div blur.scaling)
  blur.p2.resize(size div blur.scaling)

  blur.scene.resize(size)
  blur.scene.clear(clearColor)
  return blur.scene

proc blit*(blur: Blur, params = meshParams(), strength = 1f, alphaScale = 1f, blurBlend = 1f) =
  
  #no texture
  if blur.p1.texture.isNil: return

  blit(blur.scene, params = meshParams(buffer = blur.p1))

  blur.shader.uniforms:
    size = blur.p1.size.vec2

  for i in 0..<blur.passes:
    let passStrength = strength * (1f + i.float32 * 0.5f)
    #horizontal
    blit(blur.shader, meshParams(buffer = blur.p2)):
      texture = blur.p1.sampler
      dir = vec2(1, 0) * passStrength
    #vertical
    blit(blur.shader, meshParams(buffer = blur.p1)):
      texture = blur.p2.sampler
      dir = vec2(0, 1) * passStrength

  #output is premultiplied, so blend accordingly
  var realParams = params
  realParams.blend = realParams.blend.premultiplied

  blit(blur.blitShader, realParams):
    alphaScale = alphaScale
    blurBlend = blurBlend
    texture = blur.p1.sampler(0)
    scene = blur.scene.sampler(1)