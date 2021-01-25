import audio/soloud_gen, fcore, os, macros, strutils

var so: ptr Soloud

type
  Sound* = ref object
    handle: ptr AudioSource
    protect: bool
  Voice* = distinct cuint

template checkErr(details: string, body: untyped) =
  let err = body
  if err != 0: echo "[Audio] ", details, ": ", so.SoloudGetErrorString(err)

proc initAudio*(visualize = false) =
  so = SoloudCreate()
  checkErr("Failed to initialize"): so.SoloudInit()

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
  const data = staticReadString(path)
  let handle = WavStreamCreate()
  checkErr(path): handle.WavStreamLoadMemEx(cast[ptr cuchar](data.cstring), data.len.cuint, 1, 0)
  return Sound(handle: handle, protect: true)

proc loadMusic*(path: static[string]): Sound =
  when not defined(emscripten):
    return loadMusicStatic(path)
  else: #load from filesystem on emscripten
    let handle = WavStreamCreate()
    checkErr(path): handle.WavStreamLoad("assets/" & path)
    return Sound(handle: handle)

proc loadSoundStatic*(path: static[string]): Sound =
  const data = staticReadString(path)
  let handle = WavCreate()
  checkErr(path): handle.WavLoadMemEx(cast[ptr cuchar](data.cstring), data.len.cuint, 1, 0)
  return Sound(handle: handle)

proc loadSound*(path: static[string]): Sound =
  when not defined(emscripten):
    return loadSoundStatic(path)
  else: #load from filesystem on emscripten
    let handle = WavCreate()
    checkErr(path): handle.WavLoad("assets/" & path)
    return Sound(handle: handle)

proc play*(sound: Sound, pitch = 1.0'f32, volume = 1.0'f32, pan = 1.0'f32, loop = false): Voice {.discardable.} =
  #handle may not exist due to failed loading
  if sound.handle.isNil: return

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

## defines all audio files as global variables and generates a loadAudio proc for loading them
## all files in music/ are loaded with the "music" prefix; likewise for sounds/
macro defineAudio*() =
  result = newStmtList()

  let loadProc = quote do:
    proc loadAudio*() =
      discard
  let loadBody = loadProc.last

  for folder in walkDir("assets"):
    if folder.kind == pcDir:
      for f in walkDir(folder.path):
        let file = f.path.substr("assets/".len)
        if (file.startsWith("music/") or file.startsWith("sounds/")) and file.splitFile.ext in [".ogg", ".mp3", ".wav"]:
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