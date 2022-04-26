import ../mesh, ../framebuffer, ../shader, ../texture, ../fmath, ../color, ../globals, ../draw

const screenspace = """
attribute vec4 a_pos;
attribute vec2 a_uv; 
varying vec2 v_uv;

void main(){
	v_uv = a_uv;
	gl_Position = a_pos;
}
"""

type Bloom* = object
  buffer, p1, p2: Framebuffer
  thresh, bloom, blur: Shader
  blurPasses*: int
  scaling*: int

proc newBloom*(scaling: int = 4, passes: int = 1, depth = false): Bloom =
  result.buffer = newFramebuffer(depth = depth)
  result.p1 = newFramebuffer()
  result.p2 = newFramebuffer()
  result.scaling = scaling
  result.blurPasses = passes

  result.thresh = newShader(screenspace,
  """ 
  uniform lowp sampler2D u_texture;
  uniform float u_threshold;
  varying vec2 v_uv;

  void main(){
    vec4 color = texture2D(u_texture, v_uv);
    if(color.r + color.g + color.b > u_threshold * 3.0){
      gl_FragColor = color;
    }else{
      gl_FragColor = vec4(0.0);
    }
  }
  """
  )

  result.bloom = newShader(screenspace,
  """ 
  uniform lowp sampler2D u_texture0;
  uniform lowp sampler2D u_texture1;
  uniform lowp float u_bloomIntensity;
  uniform lowp float u_originalIntensity;

  varying vec2 v_uv;

  void main(){
    vec4 original = texture2D(u_texture0, v_uv) * u_originalIntensity;
    vec4 bloom = texture2D(u_texture1, v_uv) * u_bloomIntensity;
    vec4 combined = original * (vec4(1.0) - bloom) + bloom;
    float mx = min(max(combined.r, max(combined.g, combined.b)), 1.0);
    gl_FragColor = vec4(combined.rgb / mx, mx);
  }

  """
  )

  result.blur = newShader(
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

proc buffer*(bloom: Bloom, clearColor = colorClear): Framebuffer =
  bloom.buffer.resize(fau.sizei)
  bloom.p1.resize(fau.sizei div bloom.scaling)
  bloom.p2.resize(fau.sizei div bloom.scaling)
  #TODO would be nice if buffer resizes preserved filters...
  bloom.buffer.texture.filter = tfLinear
  bloom.p1.texture.filter = tfLinear
  bloom.p2.texture.filter = tfLinear

  bloom.buffer.clear(clearColor)
  return bloom.buffer

proc blit*(bloom: Bloom, params = meshParams(), intensity = 2.5f, threshold = 0.5f) =
  #no texture
  if bloom.buffer.texture.isNil: return

  bloom.thresh.uniforms:
    threshold = threshold
  
  bloom.buffer.blit(bloom.thresh, meshParams(buffer = bloom.p1))

  #TODO uniform blocks bad
  bloom.blur.uniforms:
    size = bloom.p1.size.vec2

  for i in 0..<bloom.blurPasses:
    #horizontal
    blit(bloom.blur, meshParams(buffer = bloom.p2)):
      texture = bloom.p1.sampler
      dir = vec2(1, 0)
    #vertical
    blit(bloom.blur, meshParams(buffer = bloom.p1)):
      texture = bloom.p2.sampler
      dir = vec2(0, 1)

  blit(bloom.bloom, params):
    texture0 = bloom.buffer.sampler(0)
    texture1 = bloom.p1.sampler(1)
    bloomIntensity = intensity
    originalIntensity = 1f
  