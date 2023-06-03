import soloud, os, macros, strutils, assets, globals

# High-level soloud wrapper.

var 
  so: ptr Soloud
  initialized: bool

type
  SoundObj* = object
    handle: ptr AudioSource
    stream: bool
    protect: bool
  Sound* = ref SoundObj
  Voice* = distinct cuint
  AudioFilter* = ptr Filter
  #EchoFilter* = ptr EchoFilter #TODO how to resolve name conflict?
  BiquadFilter* = ptr BiquadResonantFilter
  FilterParam* = distinct uint

const
  fWet* = 0.FilterParam
  fBiquadFrequency* = 2.FilterParam
  fBiquadResonance* = 3.FilterParam
  fEchoDelay* = 1.FilterParam
  fEchoDecay* = 2.FilterParam
  fEchoFilter* = 3.FilterParam

proc `=destroy`*(sound: var SoundObj) =
  if sound.handle != nil:
    if sound.stream:
      WavStreamDestroy(cast[ptr WavStream](sound.handle))
    else:
      WavDestroy(cast[ptr Wav](sound.handle))

template checkErr(details: string, body: untyped) =
  let err = body
  #the game shouldn't crash when an audio error happens, but it would be nice to log to stderr
  if err != 0: echo "[Audio] ", details, ": ", so.SoloudGetErrorString(err)

proc initAudio*() =
  so = SoloudCreate()
  let err = so.SoloudInit()
  if err != 0:
    echo "[Audio] Failed to initialize: ", so.SoloudGetErrorString(err), " (", err, ")"
  else:
    initialized = true
    echo "Initialized SoLoud v" & $so.SoloudGetVersion() & " w/ " & $so.SoloudGetBackendString()

    #on Android, audio is not paused in the background, so that needs to be handled manually
    when defined(Android):
      addFauListener(proc(e: FauEvent) =
        if e.kind == feVisible:
          so.SoloudSetPauseAll(e.shown.not.cint)
      )

proc getAudioBufferSize*(): int = so.SoloudGetBackendBufferSize().int

proc getAudioSampleRate*(): int = so.SoloudGetBackendSampleRate().int

proc setGlobalVolume*(vol: float32) =
  so.SoloudSetGlobalVolume(vol.cdouble)

proc enableSoundVisualization*(visualize = true) =
  so.SoloudSetVisualizationEnable(visualize.cint)

proc getFft*(): array[256, float32] =
  let data = so.SoloudCalcFFT()
  let dataArr = cast[ptr UncheckedArray[cfloat]](data)
  for i in 0..<256:
    result[i] = dataArr[i].float32

proc loadMusicBytes*(path: string, data: string): Sound =
  let handle = WavStreamCreate()
  checkErr(path): handle.WavStreamLoadMemEx(cast[ptr cuchar](data.cstring), data.len.cuint, 1, 0)
  return Sound(handle: handle, protect: true, stream: true)

proc loadMusicStatic*(path: static[string]): Sound =
  return loadMusicBytes(path, assetReadStatic(path))

proc loadMusicFile*(path: string): Sound =
  let handle = WavStreamCreate()
  checkErr(path): handle.WavStreamLoad(path)
  return Sound(handle: handle, stream: true)

proc loadMusicAsset*(path: string): Sound =
  ## Loads music from the assets folder - non-static parameter version. Uses preloaded asset directory if static.
  when staticAssets or defined(Android):
    #on desktop, this uses the pre-loaded path; on Android, this reads from the APK
    return loadMusicBytes(path, assetRead(path))
  else: #load from filesystem
    return loadMusicFile(path.assetFile)

proc loadMusic*(path: static[string]): Sound =
  ## Loads music from the assets folder, or statically.
  when staticAssets:
    return loadMusicStatic(path)
  else:
    return loadMusicAsset(path)

proc loadSoundBytes*(path: string, data: string): Sound =
  let handle = WavCreate()
  checkErr(path): handle.WavLoadMemEx(cast[ptr cuchar](data.cstring), data.len.cuint, 1, 0)
  return Sound(handle: handle)

proc loadSoundStatic*(path: static[string]): Sound =
  return loadSoundBytes(path, assetReadStatic(path))

proc loadSoundFile*(path: string): Sound =
  let handle = WavCreate()
  checkErr(path): handle.WavLoad(path)
  return Sound(handle: handle)

proc loadSound*(path: static[string]): Sound =
  ## Loads a sound from the assets folder, or statically.
  when staticAssets:
    return loadSoundStatic(path)
  elif defined(Android):
    #android needs to use assetRead, which gets files from the APK
    return loadSoundBytes(path, assetRead(path))
  else: #load from filesystem
    return loadSoundFile(path.assetFile)

proc play*(sound: Sound, volume = 1.0f, pitch = 1.0f, pan = 0f, loop = false): Voice {.discardable.} =
  #handle may not exist due to failed loading
  if sound.handle.isNil or not initialized: return

  let id = so.SoloudPlay(sound.handle)
  if volume != 1.0: so.SoloudSetVolume(id, volume)
  if pan != 0f: so.SoloudSetPan(id, pan)
  if pitch != 1.0: discard so.SoloudSetRelativePlaySpeed(id, pitch)
  if loop: so.SoloudSetLooping(id, 1)
  if sound.protect: so.SoloudSetProtectVoice(id, 1)
  return id.Voice

proc length*(sound: Sound): float =
  if sound.stream:
    return WavStreamGetLength(cast[ptr WavStream](sound.handle)).float
  else:
    return WavGetLength(cast[ptr Wav](sound.handle)).float

proc stop*(v: Voice) {.inline.} = 
  if initialized: so.SoloudStop(v.cuint)
proc pause*(v: Voice) {.inline.} = so.SoloudSetPause(v.cuint, 1)
proc resume*(v: Voice) {.inline.} = so.SoloudSetPause(v.cuint, 0)
proc seek*(v: Voice, pos: float) {.inline.} = discard so.SoloudSeek(v.cuint, pos.cdouble)

proc valid*(v: Voice): bool {.inline.} = v.int > 0 and so.SoloudIsValidVoiceHandle(v.cuint).bool
proc paused*(v: Voice): bool {.inline.} = so.SoloudGetPause(v.cuint).bool
proc playing*(v: Voice): bool {.inline.} = not v.paused
proc volume*(v: Voice): float32 {.inline.} = so.SoloudGetVolume(v.cuint).float32
proc pitch*(v: Voice): float32 {.inline.} = discard so.SoloudGetRelativePlaySpeed(v.cuint).float32
proc loopCount*(v: Voice): int {.inline.} = so.SoloudGetLoopCount(v.cuint).int
proc streamTime*(v: Voice): float {.inline.} = so.SoloudGetStreamTime(v.cuint).float
#TODO what is the difference?
proc streamPos*(v: Voice): float {.inline.} = so.SoloudGetStreamPosition(v.cuint).float

proc `paused=`*(v: Voice, value: bool) {.inline.} = so.SoloudSetPause(v.cuint, value.cint)
proc `volume=`*(v: Voice, value: float32) {.inline.} = so.SoloudSetVolume(v.cuint, value)
proc `pitch=`*(v: Voice, value: float32) {.inline.} = discard so.SoloudSetRelativePlaySpeed(v.cuint, value)
proc `pan=`*(v: Voice, value: float32) {.inline.} = so.SoloudSetPan(v.cuint, value)

#TODO only works with wavs, not streams
proc setFilter*(sound: Sound, index: int, filter: AudioFilter) =
  cast[ptr Wav](sound.handle).WavSetFilter(index.cuint, cast[ptr Filter](filter))

proc fadeFilter*(voice: Voice, index: int, attribute: FilterParam, value, timeSec: float32) =
  so.SoloudFadeFilterParameter(voice.cuint, index.cuint, attribute.cuint, value.float32, timeSec.float32)

proc setFilterParam*(voice: Voice, index: int, attribute: FilterParam, value: float32) =
  so.SoloudSetFilterParameter(voice.cuint, index.cuint, attribute.cuint, value.float32)

proc setGlobalFilter*(index: int, filter: AudioFilter) =
  so.SoloudSetGlobalFilter(index.cuint, cast[ptr Filter](filter))

proc newBiquadFilter*(): BiquadFilter =
  return BiquadResonantFilterCreate()

#proc newEchoFilter*(): EchoFilter =
#  return EchoFilterCreate()

#proc set*(filter: EchoFilter, delay = 0.4, decay = 0.9, filtering = 0.5) =
#  discard filter.EchoFilterSetParamsEx(delay, decay, filtering)

proc setLowpass*(filter: BiquadFilter, value: float32, resonance: float32 = 2f) =
  discard filter.BiquadResonantFilterSetParams(BIQUADRESONANTFILTER_LOWPASS, value.cfloat, resonance.cfloat)

proc setHighpass*(filter: BiquadFilter, value: float32, resonance: float32 = 2f) =
  discard filter.BiquadResonantFilterSetParams(BIQUADRESONANTFILTER_HIGHPASS, value.cfloat, resonance.cfloat)

proc newLowpassFilter*(cutoff: float32, resonance = 2f): BiquadFilter =
  result = newBiquadFilter()
  result.setLowpass(cutoff, resonance)

#TODO remove, this should be more generic
#[
proc filterEcho*(sound: Sound, delay = 0.4, decay = 0.9, filtering = 0.5) =
  let filter = EchoFilterCreate()
  discard filter.EchoFilterSetParamsEx(delay, decay, filtering)
  #TODO set filter depending on type
  sound.handle.WavStreamSetFilter(0, filter)
  ]#

## defines all audio files as global variables and generates a loadAudio proc for loading them
## all files in music/ are loaded with the "music" prefix; likewise for sounds/
macro defineAudio*() =
  result = newStmtList()

  let loadProc = quote do:
    proc loadAudio*() =
      discard
  let loadBody = loadProc.last

  #TODO this can be slow, parallelize or use more streams if possible
  for folder in walkDir("assets"):
    if folder.kind == pcDir:
      for f in walkDir(folder.path):
        let file = f.path.substr("assets/".len)
        #all assets MUST be ogg, I don't care to support other formats.
        if (file.startsWith("music/") or file.startsWith("sounds/")) and file.splitFile.ext == ".ogg":
          let
            mus = file.startsWith("music")
            name = file.splitFile.name
            nameid = ident(if mus: "music" & name.capitalizeAscii() else: "sound" & name.capitalizeAscii())
          result.add quote do:
            var `nameid`*: Sound
          
          if mus:
            loadBody.add quote do:
              `nameid` = loadMusic(`file`)
          else:
            loadBody.add quote do:
              `nameid` = loadSound(`file`)
  
  result.add loadProc

defineAudio()