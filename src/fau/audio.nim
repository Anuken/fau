import audio/soloud, os, macros, strutils, assets, globals

# High-level soloud wrapper.

var so: ptr Soloud

type
  Sound* = ref object
    handle: ptr AudioSource
    protect: bool
  Voice* = distinct cuint

template checkErr(details: string, body: untyped) =
  let err = body
  #the game shouldn't crash when an audio error happens, but it would be nice to log to stderr
  if err != 0: echo "[Audio] ", details, ": ", so.SoloudGetErrorString(err)

proc initAudio*(visualize = false) =
  so = SoloudCreate()
  checkErr("Failed to initialize"): so.SoloudInit()
  echo "Initialized SoLoud v" & $so.SoloudGetVersion() & " w/ " & $so.SoloudGetBackendString()

  #on Android, audio is not paused in the background, so that needs to be handled manually
  when defined(Android):
    addFauListener(proc(e: FauEvent) =
      if e.kind == feVisible:
        so.SoloudSetPauseAll(e.shown.not.cint)
    )

proc getFft*(): array[256, float32] =
  let data = so.SoloudCalcFFT()
  let dataArr = cast[ptr UncheckedArray[cfloat]](data)
  for i in 0..<256:
    result[i] = dataArr[i].float32

#TODO remove, this should be more generic
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

proc loadMusicFile*(path: string): Sound =
  let handle = WavStreamCreate()
  checkErr(path): handle.WavStreamLoad(path)
  return Sound(handle: handle)

proc loadMusic*(path: static[string]): Sound =
  ## Loads music from the assets folder, or statically.
  when staticAssets:
    return loadMusicStatic(path)
  else: #load from filesystem
    return loadMusicFile(path.assetFile)

proc loadSoundStatic*(path: static[string]): Sound =
  const data = staticReadString(path)
  let handle = WavCreate()
  checkErr(path): handle.WavLoadMemEx(cast[ptr cuchar](data.cstring), data.len.cuint, 1, 0)
  return Sound(handle: handle)

proc loadSoundFile*(path: string): Sound =
  let handle = WavCreate()
  checkErr(path): handle.WavLoad(path)
  return Sound(handle: handle)

proc loadSound*(path: static[string]): Sound =
  ## Loads a sound from the assets folder, or statically.
  when staticAssets:
    return loadSoundStatic(path)
  else: #load from filesystem
    return loadSoundFile(path.assetFile)

proc play*(sound: Sound, pitch = 1.0f, volume = 1.0f, pan = 1.0f, loop = false): Voice {.discardable.} =
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