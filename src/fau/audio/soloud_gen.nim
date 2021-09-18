# Generated @ 2020-07-14T18:23:11-04:00
# Command line:
#   /home/anuke/.nimble/pkgs/nimterop-0.6.4/nimterop/toast --preprocess -m:c --defines+=WITH_OPENAL --includeDirs+=/home/anuke/.cache/nim/nimterop/fau/soloud/include --includeDirs+=/usr/include --pnim --symOverride=Soloud,AlignedFloatBuffer,Soloud_destroy --nim:/home/anuke/.choosenim/toolchains/nim-1.2.4/bin/nim --pluginSourcePath=/home/anuke/.cache/nim/nimterop/cPlugins/nimterop_3841321983.nim /home/anuke/.cache/nim/nimterop/fau/soloud/include/soloud_c.h -o /home/anuke/.cache/nim/nimterop/toastCache/nimterop_3521393388.nim

{.push hint[ConvFromXtoItselfNotNeeded]: off.}
import os, macros

#TODO broken for windows
const
  baseDir = "/home/anuke/Projects/soloud"
  incl = baseDir & "/include"
  src = baseDir & "/src"

static:
  if false and not dirExists(baseDir) or defined(clearCache):
    echo "Fetching SoLoud repo..."
    if dirExists(baseDir): echo staticExec("rm -rf " & baseDir)
    echo staticExec("git clone --depth 1 https://github.com/Anuken/soloud " & baseDir)

template cDefine(sym: string) =
  {.passC: "-D" & sym.}

{.passC: "-I" & incl.}

when defined(emscripten):
  {.passL: "-lpthread".}
  cDefine("WITH_SDL2_STATIC")
  {.compile: src & "/backend/sdl2_static/soloud_sdl2_static.cpp".}
elif defined(osx):
  cDefine("WITH_COREAUDIO")
  {.passL: "-framework CoreAudio -framework AudioToolbox".}
  {.compile: src & "/backend/coreaudio/soloud_coreaudio.cpp".}
elif defined(Android):
  {.passL: "-lOpenSLES".}
  cDefine("WITH_OPENSLES")
  {.compile: src & "/backend/opensles/soloud_opensles.cpp".}
elif defined(Linux):
  {.passL: "-lpthread".}
  cDefine("WITH_MINIAUDIO")
  cDefine("MA_NO_PULSEAUDIO")
  {.compile: src & "/backend/miniaudio/soloud_miniaudio.cpp".}
elif defined(Windows):
  {.passC: "-msse".}
  {.passL: "-lwinmm".}
  cDefine("WITH_WINMM")
  {.compile: src & "/backend/winmm/soloud_winmm.cpp".}
else:
  static: doAssert false

{.compile: baseDir & "/src/c_api/soloud_c.cpp".}
{.compile: baseDir & "/src/core/soloud.cpp".}
{.compile: baseDir & "/src/core/soloud_audiosource.cpp".}
{.compile: baseDir & "/src/core/soloud_bus.cpp".}
{.compile: baseDir & "/src/core/soloud_core_3d.cpp".}
{.compile: baseDir & "/src/core/soloud_core_basicops.cpp".}
{.compile: baseDir & "/src/core/soloud_core_faderops.cpp".}
{.compile: baseDir & "/src/core/soloud_core_filterops.cpp".}
{.compile: baseDir & "/src/core/soloud_core_getters.cpp".}
{.compile: baseDir & "/src/core/soloud_core_setters.cpp".}
{.compile: baseDir & "/src/core/soloud_core_voicegroup.cpp".}
{.compile: baseDir & "/src/core/soloud_core_voiceops.cpp".}
{.compile: baseDir & "/src/core/soloud_fader.cpp".}
{.compile: baseDir & "/src/core/soloud_fft.cpp".}
{.compile: baseDir & "/src/core/soloud_fft_lut.cpp".}
{.compile: baseDir & "/src/core/soloud_file.cpp".}
{.compile: baseDir & "/src/core/soloud_filter.cpp".}
{.compile: baseDir & "/src/core/soloud_misc.cpp".}
{.compile: baseDir & "/src/core/soloud_queue.cpp".}
{.compile: baseDir & "/src/core/soloud_thread.cpp".}
{.compile: baseDir & "/src/audiosource/wav/soloud_wav_ogg.cpp".}
{.compile: baseDir & "/src/audiosource/wav/soloud_wavstream_ogg.cpp".}
{.compile: baseDir & "/src/audiosource/wav/stb_vorbis.c".}
{.compile: baseDir & "/src/filter/soloud_bassboostfilter.cpp".}
{.compile: baseDir & "/src/filter/soloud_biquadresonantfilter.cpp".}
{.compile: baseDir & "/src/filter/soloud_dcremovalfilter.cpp".}
{.compile: baseDir & "/src/filter/soloud_echofilter.cpp".}
{.compile: baseDir & "/src/filter/soloud_fftfilter.cpp".}
{.compile: baseDir & "/src/filter/soloud_flangerfilter.cpp".}
{.compile: baseDir & "/src/filter/soloud_freeverbfilter.cpp".}
{.compile: baseDir & "/src/filter/soloud_lofifilter.cpp".}
{.compile: baseDir & "/src/filter/soloud_robotizefilter.cpp".}
{.compile: baseDir & "/src/filter/soloud_waveshaperfilter.cpp".}

macro defineEnum(typ: untyped): untyped =
  result = newNimNode(nnkStmtList)

  # Enum mapped to distinct cint
  result.add quote do:
    type `typ`* = distinct cint

  for i in ["+", "-", "*", "div", "mod", "shl", "shr", "or", "and", "xor", "<", "<=", "==", ">", ">="]:
    let
      ni = newIdentNode(i)
      typout = if i[0] in "<=>": newIdentNode("bool") else: typ # comparisons return bool
    if i[0] == '>': # cannot borrow `>` and `>=` from templates
      let
        nopp = if i.len == 2: newIdentNode("<=") else: newIdentNode("<")
      result.add quote do:
        proc `ni`*(x: `typ`, y: cint): `typout` = `nopp`(y, x)
        proc `ni`*(x: cint, y: `typ`): `typout` = `nopp`(y, x)
        proc `ni`*(x, y: `typ`): `typout` = `nopp`(y, x)
    else:
      result.add quote do:
        proc `ni`*(x: `typ`, y: cint): `typout` {.borrow.}
        proc `ni`*(x: cint, y: `typ`): `typout` {.borrow.}
        proc `ni`*(x, y: `typ`): `typout` {.borrow.}
    result.add quote do:
      proc `ni`*(x: `typ`, y: int): `typout` = `ni`(x, y.cint)
      proc `ni`*(x: int, y: `typ`): `typout` = `ni`(x.cint, y)

  let
    divop = newIdentNode("/")   # `/`()
    dlrop = newIdentNode("$")   # `$`()
    notop = newIdentNode("not") # `not`()
  result.add quote do:
    proc `divop`*(x, y: `typ`): `typ` = `typ`((x.float / y.float).cint)
    proc `divop`*(x: `typ`, y: cint): `typ` = `divop`(x, `typ`(y))
    proc `divop`*(x: cint, y: `typ`): `typ` = `divop`(`typ`(x), y)
    proc `divop`*(x: `typ`, y: int): `typ` = `divop`(x, y.cint)
    proc `divop`*(x: int, y: `typ`): `typ` = `divop`(x.cint, y)

    proc `dlrop`*(x: `typ`): string {.borrow.}
    proc `notop`*(x: `typ`): `typ` {.borrow.}


{.pragma: impsoloud_cHdr,
  header: baseDir & "/include/soloud_c.h".}
{.experimental: "codeReordering".}
defineEnum(SOLOUD_ENUMS)      ## ```
                        ##   Collected enumerations
                        ## ```
const
  SOLOUD_AUTO* = (0).SOLOUD_ENUMS
  SOLOUD_SDL1* = (1).SOLOUD_ENUMS
  SOLOUD_SDL2* = (2).SOLOUD_ENUMS
  SOLOUD_PORTAUDIO* = (3).SOLOUD_ENUMS
  SOLOUD_WINMM* = (4).SOLOUD_ENUMS
  SOLOUD_XAUDIO2* = (5).SOLOUD_ENUMS
  SOLOUD_WASAPI* = (6).SOLOUD_ENUMS
  SOLOUD_ALSA* = (7).SOLOUD_ENUMS
  SOLOUD_JACK* = (8).SOLOUD_ENUMS
  SOLOUD_OSS* = (9).SOLOUD_ENUMS
  SOLOUD_OPENAL* = (10).SOLOUD_ENUMS
  SOLOUD_COREAUDIO* = (11).SOLOUD_ENUMS
  SOLOUD_OPENSLES* = (12).SOLOUD_ENUMS
  SOLOUD_VITA_HOMEBREW* = (13).SOLOUD_ENUMS
  SOLOUD_MINIAUDIO* = (14).SOLOUD_ENUMS
  SOLOUD_NOSOUND* = (15).SOLOUD_ENUMS
  SOLOUD_NULLDRIVER* = (16).SOLOUD_ENUMS
  SOLOUD_BACKEND_MAX* = (17).SOLOUD_ENUMS
  SOLOUD_CLIP_ROUNDOFF* = (1).SOLOUD_ENUMS
  SOLOUD_ENABLE_VISUALIZATION* = (2).SOLOUD_ENUMS
  SOLOUD_LEFT_HANDED_3D* = (4).SOLOUD_ENUMS
  SOLOUD_NO_FPU_REGISTER_CHANGE* = (8).SOLOUD_ENUMS
  BASSBOOSTFILTER_WET* = (0).SOLOUD_ENUMS
  BASSBOOSTFILTER_BOOST* = (1).SOLOUD_ENUMS
  BIQUADRESONANTFILTER_LOWPASS* = (0).SOLOUD_ENUMS
  BIQUADRESONANTFILTER_HIGHPASS* = (1).SOLOUD_ENUMS
  BIQUADRESONANTFILTER_BANDPASS* = (2).SOLOUD_ENUMS
  BIQUADRESONANTFILTER_WET* = (0).SOLOUD_ENUMS
  BIQUADRESONANTFILTER_TYPE* = (1).SOLOUD_ENUMS
  BIQUADRESONANTFILTER_FREQUENCY* = (2).SOLOUD_ENUMS
  BIQUADRESONANTFILTER_RESONANCE* = (3).SOLOUD_ENUMS
  ECHOFILTER_WET* = (0).SOLOUD_ENUMS
  ECHOFILTER_DELAY* = (1).SOLOUD_ENUMS
  ECHOFILTER_DECAY* = (2).SOLOUD_ENUMS
  ECHOFILTER_FILTER* = (3).SOLOUD_ENUMS
  FLANGERFILTER_WET* = (0).SOLOUD_ENUMS
  FLANGERFILTER_DELAY* = (1).SOLOUD_ENUMS
  FLANGERFILTER_FREQ* = (2).SOLOUD_ENUMS
  FREEVERBFILTER_WET* = (0).SOLOUD_ENUMS
  FREEVERBFILTER_FREEZE* = (1).SOLOUD_ENUMS
  FREEVERBFILTER_ROOMSIZE* = (2).SOLOUD_ENUMS
  FREEVERBFILTER_DAMP* = (3).SOLOUD_ENUMS
  FREEVERBFILTER_WIDTH* = (4).SOLOUD_ENUMS
  LOFIFILTER_WET* = (0).SOLOUD_ENUMS
  LOFIFILTER_SAMPLERATE* = (1).SOLOUD_ENUMS
  LOFIFILTER_BITDEPTH* = (2).SOLOUD_ENUMS
  ROBOTIZEFILTER_WET* = (0).SOLOUD_ENUMS
  ROBOTIZEFILTER_FREQ* = (1).SOLOUD_ENUMS
  ROBOTIZEFILTER_WAVE* = (2).SOLOUD_ENUMS
  WAVESHAPERFILTER_WET* = (0).SOLOUD_ENUMS
  WAVESHAPERFILTER_AMOUNT* = (1).SOLOUD_ENUMS
type
  AlignedFloatBuffer* = pointer ## ```
                             ##   Object handle typedefs
                             ## ```
  TinyAlignedFloatBuffer* {.importc, impsoloud_cHdr.} = pointer
  Soloud* = pointer
  AudioCollider* {.importc, impsoloud_cHdr.} = pointer
  AudioAttenuator* {.importc, impsoloud_cHdr.} = pointer
  AudioSource* {.importc, impsoloud_cHdr.} = pointer
  BassboostFilter* {.importc, impsoloud_cHdr.} = pointer
  BiquadResonantFilter* {.importc, impsoloud_cHdr.} = pointer
  Bus* {.importc, impsoloud_cHdr.} = pointer
  DCRemovalFilter* {.importc, impsoloud_cHdr.} = pointer
  EchoFilter* {.importc, impsoloud_cHdr.} = pointer
  Fader* {.importc, impsoloud_cHdr.} = pointer
  FFTFilter* {.importc, impsoloud_cHdr.} = pointer
  Filter* {.importc, impsoloud_cHdr.} = pointer
  FlangerFilter* {.importc, impsoloud_cHdr.} = pointer
  FreeverbFilter* {.importc, impsoloud_cHdr.} = pointer
  LofiFilter* {.importc, impsoloud_cHdr.} = pointer
  Queue* {.importc, impsoloud_cHdr.} = pointer
  RobotizeFilter* {.importc, impsoloud_cHdr.} = pointer
  Sfxr* {.importc, impsoloud_cHdr.} = pointer
  Speech* {.importc, impsoloud_cHdr.} = pointer
  Wav* {.importc, impsoloud_cHdr.} = pointer
  WaveShaperFilter* {.importc, impsoloud_cHdr.} = pointer
  WavStream* {.importc, impsoloud_cHdr.} = pointer
  File* {.importc, impsoloud_cHdr.} = pointer
proc Soloud_destroy*(aSoloud: ptr Soloud) {.importc, cdecl, impsoloud_cHdr.}
  ## ```
  ##   Soloud
  ## ```
proc Soloud_create*(): ptr Soloud {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_init*(aSoloud: ptr Soloud): cint {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_initEx*(aSoloud: ptr Soloud; aFlags: cuint; aBackend: cuint;
                   aSamplerate: cuint; aBufferSize: cuint; aChannels: cuint): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_deinit*(aSoloud: ptr Soloud) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_getVersion*(aSoloud: ptr Soloud): cuint {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_getErrorString*(aSoloud: ptr Soloud; aErrorCode: cint): cstring {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_getBackendId*(aSoloud: ptr Soloud): cuint {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_getBackendString*(aSoloud: ptr Soloud): cstring {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getBackendChannels*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getBackendSamplerate*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getBackendBufferSize*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_setSpeakerPosition*(aSoloud: ptr Soloud; aChannel: cuint; aX: cfloat;
                               aY: cfloat; aZ: cfloat): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getSpeakerPosition*(aSoloud: ptr Soloud; aChannel: cuint; aX: ptr cfloat;
                               aY: ptr cfloat; aZ: ptr cfloat): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_play*(aSoloud: ptr Soloud; aSound: ptr AudioSource): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_playEx*(aSoloud: ptr Soloud; aSound: ptr AudioSource; aVolume: cfloat;
                   aPan: cfloat; aPaused: cint; aBus: cuint): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_playClocked*(aSoloud: ptr Soloud; aSoundTime: cdouble;
                        aSound: ptr AudioSource): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_playClockedEx*(aSoloud: ptr Soloud; aSoundTime: cdouble;
                          aSound: ptr AudioSource; aVolume: cfloat; aPan: cfloat;
                          aBus: cuint): cuint {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_play3d*(aSoloud: ptr Soloud; aSound: ptr AudioSource; aPosX: cfloat;
                   aPosY: cfloat; aPosZ: cfloat): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_play3dEx*(aSoloud: ptr Soloud; aSound: ptr AudioSource; aPosX: cfloat;
                     aPosY: cfloat; aPosZ: cfloat; aVelX: cfloat; aVelY: cfloat;
                     aVelZ: cfloat; aVolume: cfloat; aPaused: cint; aBus: cuint): cuint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_play3dClocked*(aSoloud: ptr Soloud; aSoundTime: cdouble;
                          aSound: ptr AudioSource; aPosX: cfloat; aPosY: cfloat;
                          aPosZ: cfloat): cuint {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_play3dClockedEx*(aSoloud: ptr Soloud; aSoundTime: cdouble;
                            aSound: ptr AudioSource; aPosX: cfloat; aPosY: cfloat;
                            aPosZ: cfloat; aVelX: cfloat; aVelY: cfloat;
                            aVelZ: cfloat; aVolume: cfloat; aBus: cuint): cuint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_playBackground*(aSoloud: ptr Soloud; aSound: ptr AudioSource): cuint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_playBackgroundEx*(aSoloud: ptr Soloud; aSound: ptr AudioSource;
                             aVolume: cfloat; aPaused: cint; aBus: cuint): cuint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_seek*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aSeconds: cdouble): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_stop*(aSoloud: ptr Soloud; aVoiceHandle: cuint) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_stopAll*(aSoloud: ptr Soloud) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_stopAudioSource*(aSoloud: ptr Soloud; aSound: ptr AudioSource) {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_countAudioSource*(aSoloud: ptr Soloud; aSound: ptr AudioSource): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_setFilterParameter*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                               aFilterId: cuint; aAttributeId: cuint; aValue: cfloat) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_getFilterParameter*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                               aFilterId: cuint; aAttributeId: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_fadeFilterParameter*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                aFilterId: cuint; aAttributeId: cuint; aTo: cfloat;
                                aTime: cdouble) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_oscillateFilterParameter*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                     aFilterId: cuint; aAttributeId: cuint;
                                     aFrom: cfloat; aTo: cfloat; aTime: cdouble) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_getStreamTime*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cdouble {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_getStreamPosition*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cdouble {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_getPause*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_getOverallVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_getPan*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getSamplerate*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_getProtectVoice*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_getActiveVoiceCount*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getVoiceCount*(aSoloud: ptr Soloud): cuint {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_isValidVoiceHandle*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_getRelativePlaySpeed*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_getPostClipScaler*(aSoloud: ptr Soloud): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getGlobalVolume*(aSoloud: ptr Soloud): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getMaxActiveVoiceCount*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_getLooping*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_getLoopPoint*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cdouble {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_setLoopPoint*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                         aLoopPoint: cdouble) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_setLooping*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aLooping: cint) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_setMaxActiveVoiceCount*(aSoloud: ptr Soloud; aVoiceCount: cuint): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_setInaudibleBehavior*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                 aMustTick: cint; aKill: cint) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_setGlobalVolume*(aSoloud: ptr Soloud; aVolume: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_setPostClipScaler*(aSoloud: ptr Soloud; aScaler: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_setPause*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aPause: cint) {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_setPauseAll*(aSoloud: ptr Soloud; aPause: cint) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_setRelativePlaySpeed*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                 aSpeed: cfloat): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_setProtectVoice*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aProtect: cint) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_setSamplerate*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                          aSamplerate: cfloat) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_setPan*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aPan: cfloat) {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_setPanAbsolute*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                           aLVolume: cfloat; aRVolume: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_setPanAbsoluteEx*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                             aLVolume: cfloat; aRVolume: cfloat; aLBVolume: cfloat;
                             aRBVolume: cfloat; aCVolume: cfloat; aSVolume: cfloat) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_setVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aVolume: cfloat) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_setDelaySamples*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aSamples: cuint) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_fadeVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aTo: cfloat;
                       aTime: cdouble) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_fadePan*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aTo: cfloat;
                    aTime: cdouble) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_fadeRelativePlaySpeed*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                  aTo: cfloat; aTime: cdouble) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_fadeGlobalVolume*(aSoloud: ptr Soloud; aTo: cfloat; aTime: cdouble) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_schedulePause*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aTime: cdouble) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_scheduleStop*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aTime: cdouble) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_oscillateVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aFrom: cfloat;
                            aTo: cfloat; aTime: cdouble) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_oscillatePan*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aFrom: cfloat;
                         aTo: cfloat; aTime: cdouble) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_oscillateRelativePlaySpeed*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                       aFrom: cfloat; aTo: cfloat; aTime: cdouble) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_oscillateGlobalVolume*(aSoloud: ptr Soloud; aFrom: cfloat; aTo: cfloat;
                                  aTime: cdouble) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_setGlobalFilter*(aSoloud: ptr Soloud; aFilterId: cuint;
                            aFilter: ptr Filter) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_setVisualizationEnable*(aSoloud: ptr Soloud; aEnable: cint) {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_calcFFT*(aSoloud: ptr Soloud): ptr cfloat {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_getWave*(aSoloud: ptr Soloud): ptr cfloat {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_getApproximateVolume*(aSoloud: ptr Soloud; aChannel: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_getLoopCount*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cuint {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_getInfo*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aInfoKey: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_createVoiceGroup*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_destroyVoiceGroup*(aSoloud: ptr Soloud; aVoiceGroupHandle: cuint): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_addVoiceToGroup*(aSoloud: ptr Soloud; aVoiceGroupHandle: cuint;
                            aVoiceHandle: cuint): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_isVoiceGroup*(aSoloud: ptr Soloud; aVoiceGroupHandle: cuint): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_isVoiceGroupEmpty*(aSoloud: ptr Soloud; aVoiceGroupHandle: cuint): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_update3dAudio*(aSoloud: ptr Soloud) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_set3dSoundSpeed*(aSoloud: ptr Soloud; aSpeed: cfloat): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_get3dSoundSpeed*(aSoloud: ptr Soloud): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_set3dListenerParameters*(aSoloud: ptr Soloud; aPosX: cfloat;
                                    aPosY: cfloat; aPosZ: cfloat; aAtX: cfloat;
                                    aAtY: cfloat; aAtZ: cfloat; aUpX: cfloat;
                                    aUpY: cfloat; aUpZ: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_set3dListenerParametersEx*(aSoloud: ptr Soloud; aPosX: cfloat;
                                      aPosY: cfloat; aPosZ: cfloat; aAtX: cfloat;
                                      aAtY: cfloat; aAtZ: cfloat; aUpX: cfloat;
                                      aUpY: cfloat; aUpZ: cfloat;
                                      aVelocityX: cfloat; aVelocityY: cfloat;
                                      aVelocityZ: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_set3dListenerPosition*(aSoloud: ptr Soloud; aPosX: cfloat; aPosY: cfloat;
                                  aPosZ: cfloat) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_set3dListenerAt*(aSoloud: ptr Soloud; aAtX: cfloat; aAtY: cfloat;
                            aAtZ: cfloat) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_set3dListenerUp*(aSoloud: ptr Soloud; aUpX: cfloat; aUpY: cfloat;
                            aUpZ: cfloat) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_set3dListenerVelocity*(aSoloud: ptr Soloud; aVelocityX: cfloat;
                                  aVelocityY: cfloat; aVelocityZ: cfloat) {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_set3dSourceParameters*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                  aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_set3dSourceParametersEx*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                    aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat;
                                    aVelocityX: cfloat; aVelocityY: cfloat;
                                    aVelocityZ: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_set3dSourcePosition*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_set3dSourceVelocity*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                aVelocityX: cfloat; aVelocityY: cfloat;
                                aVelocityZ: cfloat) {.importc, cdecl, impsoloud_cHdr.}
proc Soloud_set3dSourceMinMaxDistance*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                      aMinDistance: cfloat; aMaxDistance: cfloat) {.
    importc, cdecl, impsoloud_cHdr.}
proc Soloud_set3dSourceAttenuation*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                   aAttenuationModel: cuint;
                                   aAttenuationRolloffFactor: cfloat) {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_set3dSourceDopplerFactor*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                     aDopplerFactor: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Soloud_mix*(aSoloud: ptr Soloud; aBuffer: ptr cfloat; aSamples: cuint) {.importc,
    cdecl, impsoloud_cHdr.}
proc Soloud_mixSigned16*(aSoloud: ptr Soloud; aBuffer: ptr cshort; aSamples: cuint) {.
    importc, cdecl, impsoloud_cHdr.}
proc BassboostFilter_destroy*(aBassboostFilter: ptr BassboostFilter) {.importc,
    cdecl, impsoloud_cHdr.}
  ## ```
  ##   BassboostFilter
  ## ```
proc BassboostFilter_getParamCount*(aBassboostFilter: ptr BassboostFilter): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc BassboostFilter_getParamName*(aBassboostFilter: ptr BassboostFilter;
                                  aParamIndex: cuint): cstring {.importc, cdecl,
    impsoloud_cHdr.}
proc BassboostFilter_getParamType*(aBassboostFilter: ptr BassboostFilter;
                                  aParamIndex: cuint): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc BassboostFilter_getParamMax*(aBassboostFilter: ptr BassboostFilter;
                                 aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc BassboostFilter_getParamMin*(aBassboostFilter: ptr BassboostFilter;
                                 aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc BassboostFilter_setParams*(aBassboostFilter: ptr BassboostFilter;
                               aBoost: cfloat): cint {.importc, cdecl, impsoloud_cHdr.}
proc BassboostFilter_create*(): ptr BassboostFilter {.importc, cdecl, impsoloud_cHdr.}
proc BiquadResonantFilter_destroy*(aBiquadResonantFilter: ptr BiquadResonantFilter) {.
    importc, cdecl, impsoloud_cHdr.}
  ## ```
  ##   BiquadResonantFilter
  ## ```
proc BiquadResonantFilter_getParamCount*(aBiquadResonantFilter: ptr BiquadResonantFilter): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc BiquadResonantFilter_getParamName*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                       aParamIndex: cuint): cstring {.importc,
    cdecl, impsoloud_cHdr.}
proc BiquadResonantFilter_getParamType*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                       aParamIndex: cuint): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc BiquadResonantFilter_getParamMax*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                      aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc BiquadResonantFilter_getParamMin*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                      aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc BiquadResonantFilter_create*(): ptr BiquadResonantFilter {.importc, cdecl,
    impsoloud_cHdr.}
proc BiquadResonantFilter_setParams*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                    aType: cint; aFrequency: cfloat;
                                    aResonance: cfloat): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_destroy*(aBus: ptr Bus) {.importc, cdecl, impsoloud_cHdr.}
  ## ```
  ##   Bus
  ## ```
proc Bus_create*(): ptr Bus {.importc, cdecl, impsoloud_cHdr.}
proc Bus_setFilter*(aBus: ptr Bus; aFilterId: cuint; aFilter: ptr Filter) {.importc,
    cdecl, impsoloud_cHdr.}
proc Bus_play*(aBus: ptr Bus; aSound: ptr AudioSource): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_playEx*(aBus: ptr Bus; aSound: ptr AudioSource; aVolume: cfloat; aPan: cfloat;
                aPaused: cint): cuint {.importc, cdecl, impsoloud_cHdr.}
proc Bus_playClocked*(aBus: ptr Bus; aSoundTime: cdouble; aSound: ptr AudioSource): cuint {.
    importc, cdecl, impsoloud_cHdr.}
proc Bus_playClockedEx*(aBus: ptr Bus; aSoundTime: cdouble; aSound: ptr AudioSource;
                       aVolume: cfloat; aPan: cfloat): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_play3d*(aBus: ptr Bus; aSound: ptr AudioSource; aPosX: cfloat; aPosY: cfloat;
                aPosZ: cfloat): cuint {.importc, cdecl, impsoloud_cHdr.}
proc Bus_play3dEx*(aBus: ptr Bus; aSound: ptr AudioSource; aPosX: cfloat; aPosY: cfloat;
                  aPosZ: cfloat; aVelX: cfloat; aVelY: cfloat; aVelZ: cfloat;
                  aVolume: cfloat; aPaused: cint): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_play3dClocked*(aBus: ptr Bus; aSoundTime: cdouble; aSound: ptr AudioSource;
                       aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat): cuint {.importc,
    cdecl, impsoloud_cHdr.}
proc Bus_play3dClockedEx*(aBus: ptr Bus; aSoundTime: cdouble; aSound: ptr AudioSource;
                         aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat; aVelX: cfloat;
                         aVelY: cfloat; aVelZ: cfloat; aVolume: cfloat): cuint {.
    importc, cdecl, impsoloud_cHdr.}
proc Bus_setChannels*(aBus: ptr Bus; aChannels: cuint): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_setVisualizationEnable*(aBus: ptr Bus; aEnable: cint) {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_annexSound*(aBus: ptr Bus; aVoiceHandle: cuint) {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_calcFFT*(aBus: ptr Bus): ptr cfloat {.importc, cdecl, impsoloud_cHdr.}
proc Bus_getWave*(aBus: ptr Bus): ptr cfloat {.importc, cdecl, impsoloud_cHdr.}
proc Bus_getApproximateVolume*(aBus: ptr Bus; aChannel: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_getActiveVoiceCount*(aBus: ptr Bus): cuint {.importc, cdecl, impsoloud_cHdr.}
proc Bus_setVolume*(aBus: ptr Bus; aVolume: cfloat) {.importc, cdecl, impsoloud_cHdr.}
proc Bus_setLooping*(aBus: ptr Bus; aLoop: cint) {.importc, cdecl, impsoloud_cHdr.}
proc Bus_set3dMinMaxDistance*(aBus: ptr Bus; aMinDistance: cfloat;
                             aMaxDistance: cfloat) {.importc, cdecl, impsoloud_cHdr.}
proc Bus_set3dAttenuation*(aBus: ptr Bus; aAttenuationModel: cuint;
                          aAttenuationRolloffFactor: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_set3dDopplerFactor*(aBus: ptr Bus; aDopplerFactor: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_set3dListenerRelative*(aBus: ptr Bus; aListenerRelative: cint) {.importc,
    cdecl, impsoloud_cHdr.}
proc Bus_set3dDistanceDelay*(aBus: ptr Bus; aDistanceDelay: cint) {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_set3dCollider*(aBus: ptr Bus; aCollider: ptr AudioCollider) {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_set3dColliderEx*(aBus: ptr Bus; aCollider: ptr AudioCollider; aUserData: cint) {.
    importc, cdecl, impsoloud_cHdr.}
proc Bus_set3dAttenuator*(aBus: ptr Bus; aAttenuator: ptr AudioAttenuator) {.importc,
    cdecl, impsoloud_cHdr.}
proc Bus_setInaudibleBehavior*(aBus: ptr Bus; aMustTick: cint; aKill: cint) {.importc,
    cdecl, impsoloud_cHdr.}
proc Bus_setLoopPoint*(aBus: ptr Bus; aLoopPoint: cdouble) {.importc, cdecl,
    impsoloud_cHdr.}
proc Bus_getLoopPoint*(aBus: ptr Bus): cdouble {.importc, cdecl, impsoloud_cHdr.}
proc Bus_stop*(aBus: ptr Bus) {.importc, cdecl, impsoloud_cHdr.}
proc DCRemovalFilter_destroy*(aDCRemovalFilter: ptr DCRemovalFilter) {.importc,
    cdecl, impsoloud_cHdr.}
  ## ```
  ##   DCRemovalFilter
  ## ```
proc DCRemovalFilter_create*(): ptr DCRemovalFilter {.importc, cdecl, impsoloud_cHdr.}
proc DCRemovalFilter_setParams*(aDCRemovalFilter: ptr DCRemovalFilter): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc DCRemovalFilter_setParamsEx*(aDCRemovalFilter: ptr DCRemovalFilter;
                                 aLength: cfloat): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc DCRemovalFilter_getParamCount*(aDCRemovalFilter: ptr DCRemovalFilter): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc DCRemovalFilter_getParamName*(aDCRemovalFilter: ptr DCRemovalFilter;
                                  aParamIndex: cuint): cstring {.importc, cdecl,
    impsoloud_cHdr.}
proc DCRemovalFilter_getParamType*(aDCRemovalFilter: ptr DCRemovalFilter;
                                  aParamIndex: cuint): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc DCRemovalFilter_getParamMax*(aDCRemovalFilter: ptr DCRemovalFilter;
                                 aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc DCRemovalFilter_getParamMin*(aDCRemovalFilter: ptr DCRemovalFilter;
                                 aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc EchoFilter_destroy*(aEchoFilter: ptr EchoFilter) {.importc, cdecl, impsoloud_cHdr.}
  ## ```
  ##   EchoFilter
  ## ```
proc EchoFilter_getParamCount*(aEchoFilter: ptr EchoFilter): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc EchoFilter_getParamName*(aEchoFilter: ptr EchoFilter; aParamIndex: cuint): cstring {.
    importc, cdecl, impsoloud_cHdr.}
proc EchoFilter_getParamType*(aEchoFilter: ptr EchoFilter; aParamIndex: cuint): cuint {.
    importc, cdecl, impsoloud_cHdr.}
proc EchoFilter_getParamMax*(aEchoFilter: ptr EchoFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc EchoFilter_getParamMin*(aEchoFilter: ptr EchoFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc EchoFilter_create*(): ptr EchoFilter {.importc, cdecl, impsoloud_cHdr.}
proc EchoFilter_setParams*(aEchoFilter: ptr EchoFilter; aDelay: cfloat): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc EchoFilter_setParamsEx*(aEchoFilter: ptr EchoFilter; aDelay: cfloat;
                            aDecay: cfloat; aFilter: cfloat): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc FFTFilter_destroy*(aFFTFilter: ptr FFTFilter) {.importc, cdecl, impsoloud_cHdr.}
  ## ```
  ##   FFTFilter
  ## ```
proc FFTFilter_create*(): ptr FFTFilter {.importc, cdecl, impsoloud_cHdr.}
proc FFTFilter_getParamCount*(aFFTFilter: ptr FFTFilter): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc FFTFilter_getParamName*(aFFTFilter: ptr FFTFilter; aParamIndex: cuint): cstring {.
    importc, cdecl, impsoloud_cHdr.}
proc FFTFilter_getParamType*(aFFTFilter: ptr FFTFilter; aParamIndex: cuint): cuint {.
    importc, cdecl, impsoloud_cHdr.}
proc FFTFilter_getParamMax*(aFFTFilter: ptr FFTFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc FFTFilter_getParamMin*(aFFTFilter: ptr FFTFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc FlangerFilter_destroy*(aFlangerFilter: ptr FlangerFilter) {.importc, cdecl,
    impsoloud_cHdr.}
  ## ```
  ##   FlangerFilter
  ## ```
proc FlangerFilter_getParamCount*(aFlangerFilter: ptr FlangerFilter): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc FlangerFilter_getParamName*(aFlangerFilter: ptr FlangerFilter;
                                aParamIndex: cuint): cstring {.importc, cdecl,
    impsoloud_cHdr.}
proc FlangerFilter_getParamType*(aFlangerFilter: ptr FlangerFilter;
                                aParamIndex: cuint): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc FlangerFilter_getParamMax*(aFlangerFilter: ptr FlangerFilter;
                               aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc FlangerFilter_getParamMin*(aFlangerFilter: ptr FlangerFilter;
                               aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc FlangerFilter_create*(): ptr FlangerFilter {.importc, cdecl, impsoloud_cHdr.}
proc FlangerFilter_setParams*(aFlangerFilter: ptr FlangerFilter; aDelay: cfloat;
                             aFreq: cfloat): cint {.importc, cdecl, impsoloud_cHdr.}
proc FreeverbFilter_destroy*(aFreeverbFilter: ptr FreeverbFilter) {.importc, cdecl,
    impsoloud_cHdr.}
  ## ```
  ##   FreeverbFilter
  ## ```
proc FreeverbFilter_getParamCount*(aFreeverbFilter: ptr FreeverbFilter): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc FreeverbFilter_getParamName*(aFreeverbFilter: ptr FreeverbFilter;
                                 aParamIndex: cuint): cstring {.importc, cdecl,
    impsoloud_cHdr.}
proc FreeverbFilter_getParamType*(aFreeverbFilter: ptr FreeverbFilter;
                                 aParamIndex: cuint): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc FreeverbFilter_getParamMax*(aFreeverbFilter: ptr FreeverbFilter;
                                aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc FreeverbFilter_getParamMin*(aFreeverbFilter: ptr FreeverbFilter;
                                aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc FreeverbFilter_create*(): ptr FreeverbFilter {.importc, cdecl, impsoloud_cHdr.}
proc FreeverbFilter_setParams*(aFreeverbFilter: ptr FreeverbFilter; aMode: cfloat;
                              aRoomSize: cfloat; aDamp: cfloat; aWidth: cfloat): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc LofiFilter_destroy*(aLofiFilter: ptr LofiFilter) {.importc, cdecl, impsoloud_cHdr.}
  ## ```
  ##   LofiFilter
  ## ```
proc LofiFilter_getParamCount*(aLofiFilter: ptr LofiFilter): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc LofiFilter_getParamName*(aLofiFilter: ptr LofiFilter; aParamIndex: cuint): cstring {.
    importc, cdecl, impsoloud_cHdr.}
proc LofiFilter_getParamType*(aLofiFilter: ptr LofiFilter; aParamIndex: cuint): cuint {.
    importc, cdecl, impsoloud_cHdr.}
proc LofiFilter_getParamMax*(aLofiFilter: ptr LofiFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc LofiFilter_getParamMin*(aLofiFilter: ptr LofiFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, impsoloud_cHdr.}
proc LofiFilter_create*(): ptr LofiFilter {.importc, cdecl, impsoloud_cHdr.}
proc LofiFilter_setParams*(aLofiFilter: ptr LofiFilter; aSampleRate: cfloat;
                          aBitdepth: cfloat): cint {.importc, cdecl, impsoloud_cHdr.}
proc Queue_destroy*(aQueue: ptr Queue) {.importc, cdecl, impsoloud_cHdr.}
  ## ```
  ##   Queue
  ## ```
proc Queue_create*(): ptr Queue {.importc, cdecl, impsoloud_cHdr.}
proc Queue_play*(aQueue: ptr Queue; aSound: ptr AudioSource): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Queue_getQueueCount*(aQueue: ptr Queue): cuint {.importc, cdecl, impsoloud_cHdr.}
proc Queue_isCurrentlyPlaying*(aQueue: ptr Queue; aSound: ptr AudioSource): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Queue_setParamsFromAudioSource*(aQueue: ptr Queue; aSound: ptr AudioSource): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Queue_setParams*(aQueue: ptr Queue; aSamplerate: cfloat): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Queue_setParamsEx*(aQueue: ptr Queue; aSamplerate: cfloat; aChannels: cuint): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc Queue_setVolume*(aQueue: ptr Queue; aVolume: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Queue_setLooping*(aQueue: ptr Queue; aLoop: cint) {.importc, cdecl, impsoloud_cHdr.}
proc Queue_set3dMinMaxDistance*(aQueue: ptr Queue; aMinDistance: cfloat;
                               aMaxDistance: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Queue_set3dAttenuation*(aQueue: ptr Queue; aAttenuationModel: cuint;
                            aAttenuationRolloffFactor: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Queue_set3dDopplerFactor*(aQueue: ptr Queue; aDopplerFactor: cfloat) {.importc,
    cdecl, impsoloud_cHdr.}
proc Queue_set3dListenerRelative*(aQueue: ptr Queue; aListenerRelative: cint) {.
    importc, cdecl, impsoloud_cHdr.}
proc Queue_set3dDistanceDelay*(aQueue: ptr Queue; aDistanceDelay: cint) {.importc,
    cdecl, impsoloud_cHdr.}
proc Queue_set3dCollider*(aQueue: ptr Queue; aCollider: ptr AudioCollider) {.importc,
    cdecl, impsoloud_cHdr.}
proc Queue_set3dColliderEx*(aQueue: ptr Queue; aCollider: ptr AudioCollider;
                           aUserData: cint) {.importc, cdecl, impsoloud_cHdr.}
proc Queue_set3dAttenuator*(aQueue: ptr Queue; aAttenuator: ptr AudioAttenuator) {.
    importc, cdecl, impsoloud_cHdr.}
proc Queue_setInaudibleBehavior*(aQueue: ptr Queue; aMustTick: cint; aKill: cint) {.
    importc, cdecl, impsoloud_cHdr.}
proc Queue_setLoopPoint*(aQueue: ptr Queue; aLoopPoint: cdouble) {.importc, cdecl,
    impsoloud_cHdr.}
proc Queue_getLoopPoint*(aQueue: ptr Queue): cdouble {.importc, cdecl, impsoloud_cHdr.}
proc Queue_setFilter*(aQueue: ptr Queue; aFilterId: cuint; aFilter: ptr Filter) {.
    importc, cdecl, impsoloud_cHdr.}
proc Queue_stop*(aQueue: ptr Queue) {.importc, cdecl, impsoloud_cHdr.}
proc RobotizeFilter_destroy*(aRobotizeFilter: ptr RobotizeFilter) {.importc, cdecl,
    impsoloud_cHdr.}
  ## ```
  ##   RobotizeFilter
  ## ```
proc RobotizeFilter_getParamCount*(aRobotizeFilter: ptr RobotizeFilter): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc RobotizeFilter_getParamName*(aRobotizeFilter: ptr RobotizeFilter;
                                 aParamIndex: cuint): cstring {.importc, cdecl,
    impsoloud_cHdr.}
proc RobotizeFilter_getParamType*(aRobotizeFilter: ptr RobotizeFilter;
                                 aParamIndex: cuint): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc RobotizeFilter_getParamMax*(aRobotizeFilter: ptr RobotizeFilter;
                                aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc RobotizeFilter_getParamMin*(aRobotizeFilter: ptr RobotizeFilter;
                                aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc RobotizeFilter_setParams*(aRobotizeFilter: ptr RobotizeFilter; aFreq: cfloat;
                              aWaveform: cint) {.importc, cdecl, impsoloud_cHdr.}
proc RobotizeFilter_create*(): ptr RobotizeFilter {.importc, cdecl, impsoloud_cHdr.}
proc Wav_destroy*(aWav: ptr Wav) {.importc, cdecl, impsoloud_cHdr.}
  ## ```
  ##   Wav
  ## ```
proc Wav_create*(): ptr Wav {.importc, cdecl, impsoloud_cHdr.}
proc Wav_load*(aWav: ptr Wav; aFilename: cstring): cint {.importc, cdecl, impsoloud_cHdr.}
proc Wav_loadMem*(aWav: ptr Wav; aMem: ptr cuchar; aLength: cuint): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Wav_loadMemEx*(aWav: ptr Wav; aMem: ptr cuchar; aLength: cuint; aCopy: cint;
                   aTakeOwnership: cint): cint {.importc, cdecl, impsoloud_cHdr.}
proc Wav_loadFile*(aWav: ptr Wav; aFile: ptr File): cint {.importc, cdecl, impsoloud_cHdr.}
proc Wav_loadRawWave8*(aWav: ptr Wav; aMem: ptr cuchar; aLength: cuint): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc Wav_loadRawWave8Ex*(aWav: ptr Wav; aMem: ptr cuchar; aLength: cuint;
                        aSamplerate: cfloat; aChannels: cuint): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc Wav_loadRawWave16*(aWav: ptr Wav; aMem: ptr cshort; aLength: cuint): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc Wav_loadRawWave16Ex*(aWav: ptr Wav; aMem: ptr cshort; aLength: cuint;
                         aSamplerate: cfloat; aChannels: cuint): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc Wav_loadRawWave*(aWav: ptr Wav; aMem: ptr cfloat; aLength: cuint): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc Wav_loadRawWaveEx*(aWav: ptr Wav; aMem: ptr cfloat; aLength: cuint;
                       aSamplerate: cfloat; aChannels: cuint; aCopy: cint;
                       aTakeOwnership: cint): cint {.importc, cdecl, impsoloud_cHdr.}
proc Wav_getLength*(aWav: ptr Wav): cdouble {.importc, cdecl, impsoloud_cHdr.}
proc Wav_setVolume*(aWav: ptr Wav; aVolume: cfloat) {.importc, cdecl, impsoloud_cHdr.}
proc Wav_setLooping*(aWav: ptr Wav; aLoop: cint) {.importc, cdecl, impsoloud_cHdr.}
proc Wav_set3dMinMaxDistance*(aWav: ptr Wav; aMinDistance: cfloat;
                             aMaxDistance: cfloat) {.importc, cdecl, impsoloud_cHdr.}
proc Wav_set3dAttenuation*(aWav: ptr Wav; aAttenuationModel: cuint;
                          aAttenuationRolloffFactor: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Wav_set3dDopplerFactor*(aWav: ptr Wav; aDopplerFactor: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc Wav_set3dListenerRelative*(aWav: ptr Wav; aListenerRelative: cint) {.importc,
    cdecl, impsoloud_cHdr.}
proc Wav_set3dDistanceDelay*(aWav: ptr Wav; aDistanceDelay: cint) {.importc, cdecl,
    impsoloud_cHdr.}
proc Wav_set3dCollider*(aWav: ptr Wav; aCollider: ptr AudioCollider) {.importc, cdecl,
    impsoloud_cHdr.}
proc Wav_set3dColliderEx*(aWav: ptr Wav; aCollider: ptr AudioCollider; aUserData: cint) {.
    importc, cdecl, impsoloud_cHdr.}
proc Wav_set3dAttenuator*(aWav: ptr Wav; aAttenuator: ptr AudioAttenuator) {.importc,
    cdecl, impsoloud_cHdr.}
proc Wav_setInaudibleBehavior*(aWav: ptr Wav; aMustTick: cint; aKill: cint) {.importc,
    cdecl, impsoloud_cHdr.}
proc Wav_setLoopPoint*(aWav: ptr Wav; aLoopPoint: cdouble) {.importc, cdecl,
    impsoloud_cHdr.}
proc Wav_getLoopPoint*(aWav: ptr Wav): cdouble {.importc, cdecl, impsoloud_cHdr.}
proc Wav_setFilter*(aWav: ptr Wav; aFilterId: cuint; aFilter: ptr Filter) {.importc,
    cdecl, impsoloud_cHdr.}
proc Wav_stop*(aWav: ptr Wav) {.importc, cdecl, impsoloud_cHdr.}
proc WaveShaperFilter_destroy*(aWaveShaperFilter: ptr WaveShaperFilter) {.importc,
    cdecl, impsoloud_cHdr.}
  ## ```
  ##   WaveShaperFilter
  ## ```
proc WaveShaperFilter_setParams*(aWaveShaperFilter: ptr WaveShaperFilter;
                                aAmount: cfloat): cint {.importc, cdecl,
    impsoloud_cHdr.}
proc WaveShaperFilter_create*(): ptr WaveShaperFilter {.importc, cdecl, impsoloud_cHdr.}
proc WaveShaperFilter_getParamCount*(aWaveShaperFilter: ptr WaveShaperFilter): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc WaveShaperFilter_getParamName*(aWaveShaperFilter: ptr WaveShaperFilter;
                                   aParamIndex: cuint): cstring {.importc, cdecl,
    impsoloud_cHdr.}
proc WaveShaperFilter_getParamType*(aWaveShaperFilter: ptr WaveShaperFilter;
                                   aParamIndex: cuint): cuint {.importc, cdecl,
    impsoloud_cHdr.}
proc WaveShaperFilter_getParamMax*(aWaveShaperFilter: ptr WaveShaperFilter;
                                  aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc WaveShaperFilter_getParamMin*(aWaveShaperFilter: ptr WaveShaperFilter;
                                  aParamIndex: cuint): cfloat {.importc, cdecl,
    impsoloud_cHdr.}
proc WavStream_destroy*(aWavStream: ptr WavStream) {.importc, cdecl, impsoloud_cHdr.}
  ## ```
  ##   WavStream
  ## ```
proc WavStream_create*(): ptr WavStream {.importc, cdecl, impsoloud_cHdr.}
proc WavStream_load*(aWavStream: ptr WavStream; aFilename: cstring): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc WavStream_loadMem*(aWavStream: ptr WavStream; aData: ptr cuchar; aDataLen: cuint): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc WavStream_loadMemEx*(aWavStream: ptr WavStream; aData: ptr cuchar;
                         aDataLen: cuint; aCopy: cint; aTakeOwnership: cint): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc WavStream_loadToMem*(aWavStream: ptr WavStream; aFilename: cstring): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc WavStream_loadFile*(aWavStream: ptr WavStream; aFile: ptr File): cint {.importc,
    cdecl, impsoloud_cHdr.}
proc WavStream_loadFileToMem*(aWavStream: ptr WavStream; aFile: ptr File): cint {.
    importc, cdecl, impsoloud_cHdr.}
proc WavStream_getLength*(aWavStream: ptr WavStream): cdouble {.importc, cdecl,
    impsoloud_cHdr.}
proc WavStream_setVolume*(aWavStream: ptr WavStream; aVolume: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc WavStream_setLooping*(aWavStream: ptr WavStream; aLoop: cint) {.importc, cdecl,
    impsoloud_cHdr.}
proc WavStream_set3dMinMaxDistance*(aWavStream: ptr WavStream; aMinDistance: cfloat;
                                   aMaxDistance: cfloat) {.importc, cdecl,
    impsoloud_cHdr.}
proc WavStream_set3dAttenuation*(aWavStream: ptr WavStream;
                                aAttenuationModel: cuint;
                                aAttenuationRolloffFactor: cfloat) {.importc,
    cdecl, impsoloud_cHdr.}
proc WavStream_set3dDopplerFactor*(aWavStream: ptr WavStream; aDopplerFactor: cfloat) {.
    importc, cdecl, impsoloud_cHdr.}
proc WavStream_set3dListenerRelative*(aWavStream: ptr WavStream;
                                     aListenerRelative: cint) {.importc, cdecl,
    impsoloud_cHdr.}
proc WavStream_set3dDistanceDelay*(aWavStream: ptr WavStream; aDistanceDelay: cint) {.
    importc, cdecl, impsoloud_cHdr.}
proc WavStream_set3dCollider*(aWavStream: ptr WavStream;
                             aCollider: ptr AudioCollider) {.importc, cdecl,
    impsoloud_cHdr.}
proc WavStream_set3dColliderEx*(aWavStream: ptr WavStream;
                               aCollider: ptr AudioCollider; aUserData: cint) {.
    importc, cdecl, impsoloud_cHdr.}
proc WavStream_set3dAttenuator*(aWavStream: ptr WavStream;
                               aAttenuator: ptr AudioAttenuator) {.importc, cdecl,
    impsoloud_cHdr.}
proc WavStream_setInaudibleBehavior*(aWavStream: ptr WavStream; aMustTick: cint;
                                    aKill: cint) {.importc, cdecl, impsoloud_cHdr.}
proc WavStream_setLoopPoint*(aWavStream: ptr WavStream; aLoopPoint: cdouble) {.
    importc, cdecl, impsoloud_cHdr.}
proc WavStream_getLoopPoint*(aWavStream: ptr WavStream): cdouble {.importc, cdecl,
    impsoloud_cHdr.}
proc WavStream_setFilter*(aWavStream: ptr WavStream; aFilterId: cuint;
                         aFilter: ptr Filter) {.importc, cdecl, impsoloud_cHdr.}
proc WavStream_stop*(aWavStream: ptr WavStream) {.importc, cdecl, impsoloud_cHdr.}
{.pop.}
