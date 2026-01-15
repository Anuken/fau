import soloud, os, macros, strutils, assets, globals, threading, util/misc, tables

# High-level soloud wrapper.

type
  SoundObj* = object
    handle: ptr AudioSource
    stream: bool
    loaded: bool
    protect: bool
    voice*: Voice
  Sound* = ref SoundObj
  Voice* = distinct cuint
  AudioBusObj* = object
    handle: ptr Bus
    voice: Voice
  AudioBus* = ref AudioBusObj
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
  NoVoice* = 0.Voice
  defaultMaxConcurrent = 7

let soundNone* = Sound()

var 
  so: ptr Soloud
  initialized: bool
  soundTable: Table[string, Sound]
  soundBus*: AudioBus

proc `=destroy`*(sound: var SoundObj) =
  if sound.handle != nil:
    if sound.stream:
      WavStreamDestroy(cast[ptr WavStream](sound.handle))
    else:
      WavDestroy(cast[ptr Wav](sound.handle))
    
    sound.handle = nil

proc `=destroy`*(bus: var AudioBusObj) =
  if bus.handle != nil:
    BusDestroy(bus.handle)
    bus.handle = nil

proc valid*(sound: Sound): bool {.inline.} = sound.loaded

proc getSoundByName*(name: string): Sound = soundTable.getOrDefault(name, soundNone)
proc registerSound*(name: string, sound: Sound) = 
  soundTable[name] = sound

template checkErr(details: string, body: untyped): bool =
  let err = body
  #the game shouldn't crash when an audio error happens, but it would be nice to log to stderr
  var success = true
  if err != 0: 
    echo "[Audio] ", details, ": ", so.SoloudGetErrorString(err)
    success = false
  success

proc stop*(v: Voice) {.inline.} = 
  if initialized and v.int > 0: so.SoloudStop(v.cuint)
proc pause*(v: Voice) {.inline.} = so.SoloudSetPause(v.cuint, 1)
proc resume*(v: Voice) {.inline.} = so.SoloudSetPause(v.cuint, 0)
proc seek*(v: Voice, pos: float) {.inline.} = discard so.SoloudSeek(v.cuint, pos.cdouble)

proc valid*(v: Voice): bool {.inline.} = v.int > 0 and so.SoloudIsValidVoiceHandle(v.cuint).bool
proc paused*(v: Voice): bool {.inline.} = v.int > 0 and so.SoloudGetPause(v.cuint).bool
proc playing*(v: Voice): bool {.inline.} = not v.paused
proc volume*(v: Voice): float32 {.inline.} = 
  if v.int > 0: so.SoloudGetVolume(v.cuint).float32 else: 0f
proc pitch*(v: Voice): float32 {.inline.} = 
  if v.int > 0: so.SoloudGetRelativePlaySpeed(v.cuint).float32 else: 0f
proc loopCount*(v: Voice): int {.inline.} = 
  if v.int > 0: so.SoloudGetLoopCount(v.cuint).int else: 0
proc streamTime*(v: Voice): float {.inline.} = 
  if v.int > 0: so.SoloudGetStreamTime(v.cuint).float else: 0f
#TODO what is the difference?
proc streamPos*(v: Voice): float {.inline.} = 
  if v.int > 0: so.SoloudGetStreamPosition(v.cuint).float else: 0f

proc `paused=`*(v: Voice, value: bool) {.inline.} = 
  if v.int > 0: so.SoloudSetPause(v.cuint, value.cint)
proc `volume=`*(v: Voice, value: float32) {.inline.} = 
  if v.int > 0: so.SoloudSetVolume(v.cuint, value)
proc `pitch=`*(v: Voice, value: float32) {.inline.} = 
  if v.int > 0: discard so.SoloudSetRelativePlaySpeed(v.cuint, value)
proc `pan=`*(v: Voice, value: float32) {.inline.} = 
  if v.int > 0: so.SoloudSetPan(v.cuint, value)

proc fadeVolume*(v: Voice, value: float32, time: float) {.inline.} = 
  if v.int > 0: so.SoloudFadeVolume(v.cuint, value, time)

proc `loopPoint=`*(sound: Sound, value: float) {.inline.} =
  if sound.handle.isNil: return

  if sound.stream:
    WavStreamSetLoopPoint(cast[ptr WavStream](sound.handle), value.cdouble)
  else:
    WavSetLoopPoint(cast[ptr Wav](sound.handle), value.cdouble)

proc `maxConcurrent=`(sound: Sound, max: int) =
  if sound.handle == nil: return
  if sound.stream:
    cast[ptr WavStream](sound.handle).WavStreamSetMaxConcurrent(max.cint)
  else:
    cast[ptr Wav](sound.handle).WavSetMaxConcurrent(max.cint)

proc `minInterrupt=`*(sound: Sound, minInterrupt: float) =
  if sound.handle == nil: return

  if sound.stream:
    cast[ptr WavStream](sound.handle).WavStreamSetMinConcurrentInterrupt(minInterrupt.cdouble)
  else:
    cast[ptr Wav](sound.handle).WavSetMinConcurrentInterrupt(minInterrupt.cdouble)

proc stop*(sound: Sound) =
  if sound.handle == nil or not initialized: return

  if sound.stream:
    cast[ptr WavStream](sound.handle).WavStreamStop()
  else:
    cast[ptr Wav](sound.handle).WavStop()

proc newAudioBus*(): AudioBus =
  AudioBus(handle: BusCreate())

proc play*(bus: AudioBus) =
  if not bus.voice.valid: 
    bus.voice = so.SoloudPlay(bus.handle).Voice

proc stop*(bus: AudioBus) =
  bus.voice.stop()
  bus.voice = 0.Voice

proc restart*(bus: AudioBus) =
  bus.stop()
  bus.play()

proc `paused=`*(bus: AudioBus, value: bool) {.inline.} =
  bus.voice.paused = value

proc `volume=`*(bus: AudioBus, value: float32) {.inline.} =
  bus.voice.volume = value

proc initAudio*() =
  so = SoloudCreate()
  let err = so.SoloudInit()
  if err != 0:
    echo "[Audio] Failed to initialize: ", so.SoloudGetErrorString(err), " (", err, ")"
    #create to prevent nil access errors...
    soundBus = newAudioBus()
  else:
    soundBus = newAudioBus()
    soundBus.play()

    initialized = true
    echo "Initialized SoLoud v", so.SoloudGetVersion(), " [", so.SoloudGetBackendString(), "]"

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

proc newEmptySound*(): Sound = 
  result = Sound(handle: WavCreate(), stream: false, loaded: false)
  result.maxConcurrent = defaultMaxConcurrent

proc newEmptyMusic*(): Sound = Sound(handle: WavStreamCreate(), protect: true, stream: true, loaded: false)

proc loadMusicBytes*(path: string, data: string): Sound =
  result = newEmptyMusic()
  result.loaded = checkErr(path): cast[ptr WavStream](result.handle).WavStreamLoadMemEx(cast[ptr cuchar](data.cstring), data.len.cuint, 1, 0)

proc loadMusicStatic*(path: static[string]): Sound =
  return loadMusicBytes(path, assetReadStatic(path))

proc loadMusicFile*(path: string): Sound =
  result = newEmptyMusic()
  result.loaded = checkErr(path): cast[ptr WavStream](result.handle).WavStreamLoad(path)

proc loadMusicAsset*(path: string): Sound =
  ## Loads music from the assets folder - non-static parameter version. Uses preloaded asset directory if static.
  when staticAssets or defined(Android):
    #on desktop, this uses the pre-loaded path; on Android, this reads from the APK
    return loadMusicBytes(path, assetRead(path))
  else: #load from filesystem
    return loadMusicFile(path.assetFile)

proc loadMusic*(path: static[string]): Sound =
  ## Loads music from the assets folder, or statically.
  when defined(skipSoundLoad):
    return newEmptyMusic()
  elif staticAssets:
    return loadMusicStatic(path)
  else:
    return loadMusicAsset(path)

proc loadMusicHandle(path: static[string], handle: pointer): bool {.gcsafe.}  =
  ## Loads a music file from a raw ptr handle. Used for parallel loading.
  when defined(skipSoundLoad):
    false #don't load anything
  elif staticAssets or defined(Android):
    let data = when staticAssets: assetReadStatic(path) else: assetRead(path)
    checkErr(path): cast[ptr WavStream](handle).WavStreamLoadMemEx(cast[ptr cuchar](data.cstring), data.len.cuint, 1, 0)
  else:
    checkErr(path): cast[ptr WavStream](handle).WavStreamLoad(path.assetFile)

proc loadSoundBytes*(path: string, data: string): Sound =
  result = newEmptySound()
  result.loaded = checkErr(path): cast[ptr Wav](result.handle).WavLoadMemEx(cast[ptr cuchar](data.cstring), data.len.cuint, 1, 0)

proc loadSoundStatic*(path: static[string]): Sound =
  return loadSoundBytes(path, assetReadStatic(path))

proc loadSoundFile*(path: string): Sound =
  result = newEmptySound()
  result.loaded = checkErr(path): cast[ptr Wav](result.handle).WavLoad(path)

proc loadSound*(path: static[string]): Sound =
  ## Loads a sound from the assets folder, or statically.
  when defined(skipSoundLoad):
    return newEmptySound()
  elif staticAssets:
    return loadSoundStatic(path)
  elif defined(Android):
    #android needs to use assetRead, which gets files from the APK
    return loadSoundBytes(path, assetRead(path))
  else: #load from filesystem
    return loadSoundFile(path.assetFile)

proc loadSoundHandle(path: static[string], handle: pointer): bool {.gcsafe.} =
  ## Loads a sound from a raw ptr handle. Used for parallel loading.
  when defined(skipSoundLoad):
    false #don't load anything
  elif staticAssets or defined(Android):
    let data = when staticAssets: assetReadStatic(path) else: assetRead(path)
    checkErr(path): cast[ptr Wav](handle).WavLoadMemEx(cast[ptr cuchar](data.cstring), data.len.cuint, 1, 0)
  else:
    checkErr(path): cast[ptr Wav](handle).WavLoad(path.assetFile)

proc play*(sound: Sound, volume = 1.0f, pitch = 1.0f, pan = 0f, loop = false, paused = false, bus = if sound.stream: nil else: soundBus): Voice {.discardable.} =
  #handle may not exist due to failed loading
  if sound.handle.isNil or not initialized or not sound.loaded: return

  let id = if bus == nil: 
    so.SoloudPlayEx(sound.handle, volume, pan, pitch, paused.cint, loop.cint, 0)
  else:
    BusPlayEx(bus.handle, sound.handle, volume, pan, pitch, paused.cint, loop.cint)
  if sound.protect: so.SoloudSetProtectVoice(id, 1)
  sound.voice = id.Voice
  return id.Voice

proc length*(sound: Sound): float =
  if sound.handle.isNil: return 0.0
  if sound.stream:
    return WavStreamGetLength(cast[ptr WavStream](sound.handle)).float
  else:
    return WavGetLength(cast[ptr Wav](sound.handle)).float

#TODO only works with wavs, not streams
proc setFilter*(sound: Sound, index: int, filter: AudioFilter) =
  if sound.loaded and initialized:
    cast[ptr Wav](sound.handle).WavSetFilter(index.cuint, cast[ptr Filter](filter))

proc setFilter*(bus: AudioBus, index: int, filter: AudioFilter) =
  if initialized:
    cast[ptr Bus](bus.handle).BusSetFilter(index.cuint, cast[ptr Filter](filter))

proc fadeFilter*(voice: Voice, index: int, attribute: FilterParam, value, timeSec: float32) =
  so.SoloudFadeFilterParameter(voice.cuint, index.cuint, attribute.cuint, value.float32, timeSec.float32)

proc setFilterParam*(voice: Voice, index: int, attribute: FilterParam, value: float32) =
  if initialized:
    so.SoloudSetFilterParameter(voice.cuint, index.cuint, attribute.cuint, value.float32)

proc setGlobalFilter*(index: int, filter: AudioFilter) =
  if initialized:
    so.SoloudSetGlobalFilter(index.cuint, cast[ptr Filter](filter))

proc clearGlobalFilter*(index: int) =
  if initialized:
    so.SoloudSetGlobalFilter(index.cuint, nil)

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

proc newHighpassFilter*(cutoff: float32, resonance = 2f): BiquadFilter =
  result = newBiquadFilter()
  result.setHighpass(cutoff, resonance)

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
      var exec {.inject.} = createMaster()
      exec.awaitAll:
        discard
  let loadBody = loadProc[6].last[1]

  for folder in walkDir("assets"):
    if folder.kind == pcDir:
      for f in walkDirRec2(folder.path):
        let file = f.substr("assets/".len)
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
              `nameid` = newEmptyMusic()
              registerSound(`name`, `nameid`)
              exec.spawn loadMusicHandle(`file`, `nameid`.handle) -> `nameid`.loaded
          else:
            loadBody.add quote do:
              `nameid` = newEmptySound()
              registerSound(`name`, `nameid`)
              exec.spawn loadSoundHandle(`file`, `nameid`.handle) -> `nameid`.loaded
  
  result.add loadProc

defineAudio()