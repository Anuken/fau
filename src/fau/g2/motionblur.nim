import ../mesh, ../framebuffer, ../shader, ../texture, ../fmath, ../color, ../globals, ../draw, std/strutils

type MotionBlur* = object
  scene: Framebuffer   # this frame's contents get rendered here
  accum: Framebuffer   # persistent trail buffer; NOT cleared between frames
  temp: Framebuffer    # ping-pong target so accum can be read and written safely
  combineShader: Shader
  blitShader: Shader
  scaling*: int
  decay*: float32       # how much of the old trail survives each frame, 0..1

proc newMotionBlur*(decay: float32 = 0.85f, scaling: int = 1): MotionBlur =
  result.scene = newFramebuffer(filter = tfLinear)
  result.accum = newFramebuffer(filter = tfLinear)
  result.temp = newFramebuffer(filter = tfLinear)
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
      gl_FragColor = texture2D(u_texture, v_uv) * vec4(1.0, 1.0, 1.0, u_alphaScale);
    }
    """
  )

proc buffer*(blur: MotionBlur, clearColor = colorClear, size = fau.sizei): Framebuffer =
  let s = size div blur.scaling
  blur.scene.resize(s)
  blur.accum.resize(s)
  blur.temp.resize(s)

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

  blit(blur.blitShader, params):
    alphaScale = alphaScale
    texture = blur.accum.sampler(0)