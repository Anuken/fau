import audio/soloud_gen, fcore

var so: ptr Soloud

type
  Sound* = ref object
    handle: ptr AudioSource
    protect: bool
  Voice* = distinct cuint

proc initAudio*(visualize = false) =
  so = SoloudCreate()
  if visualize:
    discard so.SoloudInitEx(SOLOUD_ENABLE_VISUALIZATION.cuint, SOLOUD_AUTO.cuint, SOLOUD_AUTO.cuint, SOLOUD_AUTO.cuint, SOLOUD_AUTO.cuint)
  else:
    discard so.SoloudInit()

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

  let handle = WavStreamCreate()
  discard handle.WavStreamLoadMem(cast[ptr cuchar](musData.cstring), musData.len.cuint)
  return Sound(handle: handle, protect: true)

proc loadSoundStatic*(path: static[string]): Sound =
  const musData = staticReadString(path)

  let handle = WavCreate()
  discard handle.WavLoadMem(cast[ptr cuchar](musData.cstring), musData.len.cuint)
  return Sound(handle: handle)

proc play*(sound: Sound, pitch = 1.0'f32, volume = 1.0'f32, pan = 1.0'f32, loop = false): Voice {.discardable.} =
  let id = so.SoloudPlay(sound.handle)
  if volume != 1.0: so.SoloudSetVolume(id, volume)
  if pan != 1.0: so.SoloudSetPan(id, pan)
  if pitch != 1.0: discard so.SoloudSetRelativePlaySpeed(id, pitch)
  if loop: so.SoloudSetLooping(id, 1)
  if sound.protect: so.SoloudSetProtectVoice(id, 1)
  return id.Voice

proc stop*(v: Voice) {.inline.} = so.SoloudStop(v.cuint)
proc pause*(v: Voice) {.inline.} = so.SoloudSetPause(v.cuint, 1)
proc resume*(v: Voice) {.inline.} = so.SoloudSetPause(v.cuint, 0)

proc valid*(v: Voice): bool {.inline.} = so.SoloudIsValidVoiceHandle(v.cuint).bool
proc paused*(v: Voice): bool {.inline.} = so.SoloudGetPause(v.cuint).bool
proc volume*(v: Voice): float32 {.inline.} = so.SoloudGetVolume(v.cuint).float32
proc pitch*(v: Voice): float32 {.inline.} = discard so.SoloudGetRelativePlaySpeed(v.cuint).float32

proc `paused=`*(v: Voice, value: bool) {.inline.} = so.SoloudSetPause(v.cuint, value.cint)
proc `volume=`*(v: Voice, value: float32) {.inline.} = so.SoloudSetVolume(v.cuint, value)
proc `pitch=`*(v: Voice, value: float32) {.inline.} = discard so.SoloudSetRelativePlaySpeed(v.cuint, value)
proc `pan=`*(v: Voice, value: float32) {.inline.} = so.SoloudSetPan(v.cuint, value)