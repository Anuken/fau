import ../mesh, ../framebuffer, ../shader, ../texture, ../fmath, ../color, ../globals, ../draw, std/strutils

type MotionBlur* = object
  # this frame's contents get rendered here
  scene: Framebuffer
  # persistent trail buffer; NOT cleared between frames
  accum: Framebuffer
  # ping-pong target so accum can be read and written safely
  temp: Framebuffer
  combineShader: Shader
  blitShader: Shader
  scaling*: int
  # how much of the old trail survives each frame, 0..1
  decay*: float32

proc newMotionBlur*(decay: float32 = 0.85f, scaling: int = 1): MotionBlur =
  result.scene = newFramebuffer(filter = tfLinear)
  #float16 framebuffer needed to prevent leftover smearing
  result.accum = newFramebuffer(filter = tfLinear, formats = @[fmColorRgba16f])
  result.temp = newFramebuffer(filter = tfLinear, formats = @[fmColorRgba16f])
  result.scaling = scaling
  result.decay = decay

  result.combineShader = newShader(
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
  uniform lowp sampler2D u_scene;
  uniform lowp sampler2D u_accum;
  uniform float u_decay;
  varying vec2 v_uv;

  void main(){
    gl_FragColor = mix(texture2D(u_scene, v_uv), texture2D(u_accum, v_uv), u_decay);
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
    uniform float u_alphaScale;
    varying vec2 v_uv;
    
    void main(){
      vec4 c = texture2D(u_texture, v_uv);
      float a = c.a * u_alphaScale;
      gl_FragColor = vec4(c.rgb * a, a);
    }
    """
  )

proc buffer*(blur: MotionBlur, clearColor = colorClear, size = fau.sizei): Framebuffer =
  let s = size div blur.scaling
  blur.scene.resize(s)
  if blur.accum.resize(s): blur.accum.clear(colorClear)
  if blur.temp.resize(s): blur.temp.clear(colorClear)

  blur.scene.clear(clearColor)
  return blur.scene

proc blit*(blur: var MotionBlur, params = meshParams(), decay = blur.decay, alphaScale = 1f) =
  if blur.scene.texture.isNil: return

  #mix this frame into a decayed copy of the trail buffer
  blit(blur.combineShader, meshParams(buffer = blur.temp)):
    scene = blur.scene.sampler(0)
    accum = blur.accum.sampler(1)
    decay = decay

  #temp becomes the new trail buffer; old accum can be reused as next temp
  swap(blur.accum, blur.temp)
  
  var realParams = params
  realParams.blend = realParams.blend.premultiplied

  blit(blur.blitShader, realParams):
    alphaScale = alphaScale
    texture = blur.accum.sampler(0)