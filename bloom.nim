import fcore

const screenspace = """
attribute vec4 a_position;
attribute vec2 a_texc; 
varying vec2 v_texc;

void main(){
	v_texc = a_texc;
	gl_Position = a_position;
}
"""

type Bloom* = object
  buffer, p1, p2: Framebuffer
  thresh, bloom, blur: Shader
  blurPasses*: int
  scaling: int
  blend: bool

proc newBloom*(scaling: int = 4, passes: int = 1, blend = false): Bloom =
  result.buffer = newFramebuffer()
  result.p1 = newFramebuffer()
  result.p2 = newFramebuffer()
  result.scaling = scaling
  result.blurPasses = passes
  result.blend = blend

  result.thresh = newShader(screenspace,
  """ 
  uniform lowp sampler2D u_texture0;
  varying vec2 v_texc;

  void main(){
    vec4 color = texture2D(u_texture0, v_texc);
    if(color.r + color.g + color.b > 0.5 * 3.0){
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

  varying vec2 v_texc;

  void main(){
    vec4 original = texture2D(u_texture0, v_texc) * u_originalIntensity;
    vec4 bloom = texture2D(u_texture1, v_texc) * u_bloomIntensity;
    gl_FragColor = original * (vec4(1.0) - bloom) + bloom;
  }

  """
  )

  result.blur = newShader(
  """ 
  attribute vec4 a_position;
  attribute vec2 a_texc; 
  uniform vec2 dir;
  uniform vec2 size;
  varying vec2 v_texCoords0;
  varying vec2 v_texCoords1;
  varying vec2 v_texCoords2;
  varying vec2 v_texCoords3;
  varying vec2 v_texCoords4;
  const vec2 futher = vec2(3.2307692308, 3.2307692308);
  const vec2 closer = vec2(1.3846153846, 1.3846153846);

  void main(){
    vec2 sizeAndDir = dir / size;
    vec2 f = futher*sizeAndDir;
    vec2 c = closer*sizeAndDir;
    
    v_texCoords0 = a_texc - f;
    v_texCoords1 = a_texc - c;	
    v_texCoords2 = a_texc;
    v_texCoords3 = a_texc + c;
    v_texCoords4 = a_texc + f;
    
    gl_Position = a_position;
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

  result.bloom.seti("u_texture0", 0)
  result.bloom.seti("u_texture1", 1)
  result.bloom.setf("u_bloomIntensity", 2.5)
  result.bloom.setf("u_originalIntensity", 1.0)

proc capture*(bloom: Bloom) =
  let
    w = fau.width
    h = fau.height

  if w != bloom.buffer.width or h != bloom.buffer.height:
    bloom.buffer.resize(w, h)
    bloom.p1.resize(w div bloom.scaling, h div bloom.scaling)
    bloom.p2.resize(w div bloom.scaling, h div bloom.scaling)
    bloom.blur.setf("size", bloom.p1.width.float32, bloom.p1.height.float32)
    bloom.buffer.texture.filterLinear()
    bloom.p1.texture.filterLinear()
    bloom.p2.texture.filterLinear()

  bloom.buffer.push(colorClear)

proc render*(bloom: Bloom) =
  bloom.buffer.pop()

  blendDisabled.use()

  bloom.p1.push()
  bloom.buffer.blitQuad(bloom.thresh)
  bloom.p1.pop()

  for i in 0..<bloom.blurPasses:
    #horizontal
    bloom.p2.push()
    bloom.blur.setf("dir", 1, 0)
    bloom.p1.blitQuad(bloom.blur)
    bloom.p2.pop()

    #vertical
    bloom.p1.push()
    bloom.blur.setf("dir", 0, 1)
    bloom.p2.blitQuad(bloom.blur)
    bloom.p1.pop()

  (if bloom.blend: blendNormal else: blendDisabled).use()
  bloom.buffer.texture.use(0)
  bloom.p1.blitQuad(bloom.bloom, unit = 1)
  