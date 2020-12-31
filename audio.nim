import audio/soloud, common

var so: ptr Soloud

proc initAudio*(visualize = false) =
  so = SoloudCreate()
  if visualize:
    discard so.SoloudInitEx(SOLOUD_ENABLE_VISUALIZATION.cuint, SOLOUD_AUTO.cuint, SOLOUD_AUTO.cuint, SOLOUD_AUTO.cuint, SOLOUD_AUTO.cuint)
  else:
    discard so.SoloudInit()

type Sound* = ref object
  handle: ptr AudioSource

proc getFft*(): array[256, float32] =
  let data = so.SoloudCalcFFT()
  let dataArr = cast[ptr UncheckedArray[cfloat]](data)
  for i in 0..<256:
    result[i] = dataArr[i].float32

proc filterEcho*(sound: Sound, delay = 0.4, decay = 0.9, filtering = 0.5) =
  let filter = EchoFilterCreate()
  discard filter.EchoFilterSetParamsEx(delay, decay, filtering)
  #TODO set filter depending on type
  sound.handle.WavStreamSetFilter(0, filter)

proc loadMusicStatic*(path: static[string]): Sound =
  const musData = staticReadString(path)
  const len = musData.len

  let handle = WavStreamCreate()
  discard handle.WavStreamLoadMem(cast[ptr cuchar](musData.cstring), len.cuint)
  return Sound(handle: handle)

proc loadSoundStatic*(path: static[string]): Sound =
  const musData = staticReadString(path)
  const len = musData.len

  let handle = WavCreate()
  discard handle.WavLoadMem(cast[ptr cuchar](musData.cstring), len.cuint)
  return Sound(handle: handle)

proc play*(sound: Sound, pitch = 1.0) =
  let id = so.SoloudPlay(sound.handle)
  discard so.SoloudSetRelativePlaySpeed(id, pitch)