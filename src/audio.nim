#proxy file for multiple audio backends

import audio/soloud_gen

#TODO handle web focus properly
var so = SoloudCreate()

discard so.SoloudInit()

type Sound* = ref object
  handle: ptr AudioSource

proc filterEcho*(sound: Sound, delay = 0.4, decay = 0.9, filtering = 0.5) =
  let filter = EchoFilterCreate()
  discard filter.EchoFilterSetParamsEx(delay, decay, filtering)
  #TODO set filter depending on type
  sound.handle.WavStreamSetFilter(0, filter)

proc loadMusicStatic*(path: static[string]): Sound =
  const musData = staticRead(path)
  const len = musData.len

  let handle = WavStreamCreate()
  discard handle.WavStreamLoadMem(cast[ptr cuchar](musData.cstring), len.cuint)
  return Sound(handle: handle)

proc loadSoundStatic*(path: static[string]): Sound =
  const musData = staticRead(path)
  const len = musData.len

  let handle = WavCreate()
  discard handle.WavLoadMem(cast[ptr cuchar](musData.cstring), len.cuint)
  return Sound(handle: handle)

proc play*(sound: Sound, pitch = 1.0) =
  let id = so.Soloud_play(sound.handle)
  discard so.SoloudSetRelativePlaySpeed(id, pitch)