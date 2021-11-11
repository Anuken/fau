import os

#TODO broken for windows
const
  #use my local version if possible, it's more up-to-date
  isMe = dirExists("/home/anuke")
  baseDir = if isMe: "/home/anuke/Projects/soloud" else: "/tmp/soloud"
  incl = baseDir & "/include"
  src = baseDir & "/src"

static:
  if not isMe and not dirExists(baseDir) or defined(clearCache):
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

{.pragma: libsoloud, header: baseDir & "/include/soloud_c.h".}

const
  SOLOUD_AUTO* = 0.cint
  SOLOUD_SDL1* = 1.cint
  SOLOUD_SDL2* = 2.cint
  SOLOUD_PORTAUDIO* = 3.cint
  SOLOUD_WINMM* = 4.cint
  SOLOUD_XAUDIO2* = 5.cint
  SOLOUD_WASAPI* = 6.cint
  SOLOUD_ALSA* = 7.cint
  SOLOUD_JACK* = 8.cint
  SOLOUD_OSS* = 9.cint
  SOLOUD_OPENAL* = 10.cint
  SOLOUD_COREAUDIO* = 11.cint
  SOLOUD_OPENSLES* = 12.cint
  SOLOUD_VITA_HOMEBREW* = 13.cint
  SOLOUD_MINIAUDIO* = 14.cint
  SOLOUD_NOSOUND* = 15.cint
  SOLOUD_NULLDRIVER* = 16.cint
  SOLOUD_BACKEND_MAX* = 17.cint
  SOLOUD_CLIP_ROUNDOFF* = 1.cint
  SOLOUD_ENABLE_VISUALIZATION* = 2.cint
  SOLOUD_LEFT_HANDED_3D* = 4.cint
  SOLOUD_NO_FPU_REGISTER_CHANGE* = 8.cint
  BASSBOOSTFILTER_WET* = 0.cint
  BASSBOOSTFILTER_BOOST* = 1.cint
  BIQUADRESONANTFILTER_LOWPASS* = 0.cint
  BIQUADRESONANTFILTER_HIGHPASS* = 1.cint
  BIQUADRESONANTFILTER_BANDPASS* = 2.cint
  BIQUADRESONANTFILTER_WET* = 0.cint
  BIQUADRESONANTFILTER_TYPE* = 1.cint
  BIQUADRESONANTFILTER_FREQUENCY* = 2.cint
  BIQUADRESONANTFILTER_RESONANCE* = 3.cint
  ECHOFILTER_WET* = 0.cint
  ECHOFILTER_DELAY* = 1.cint
  ECHOFILTER_DECAY* = 2.cint
  ECHOFILTER_FILTER* = 3.cint
  FLANGERFILTER_WET* = 0.cint
  FLANGERFILTER_DELAY* = 1.cint
  FLANGERFILTER_FREQ* = 2.cint
  FREEVERBFILTER_WET* = 0.cint
  FREEVERBFILTER_FREEZE* = 1.cint
  FREEVERBFILTER_ROOMSIZE* = 2.cint
  FREEVERBFILTER_DAMP* = 3.cint
  FREEVERBFILTER_WIDTH* = 4.cint
  LOFIFILTER_WET* = 0.cint
  LOFIFILTER_SAMPLERATE* = 1.cint
  LOFIFILTER_BITDEPTH* = 2.cint
  ROBOTIZEFILTER_WET* = 0.cint
  ROBOTIZEFILTER_FREQ* = 1.cint
  ROBOTIZEFILTER_WAVE* = 2.cint
  WAVESHAPERFILTER_WET* = 0.cint
  WAVESHAPERFILTER_AMOUNT* = 1.cint

type
  AlignedFloatBuffer* = pointer ## ```
                             ##   Object handle typedefs
                             ## ```
  TinyAlignedFloatBuffer* {.importc, libsoloud.} = pointer
  Soloud* = pointer
  AudioCollider* {.importc, libsoloud.} = pointer
  AudioAttenuator* {.importc, libsoloud.} = pointer
  AudioSource* {.importc, libsoloud.} = pointer
  BassboostFilter* {.importc, libsoloud.} = pointer
  BiquadResonantFilter* {.importc, libsoloud.} = pointer
  Bus* {.importc, libsoloud.} = pointer
  DCRemovalFilter* {.importc, libsoloud.} = pointer
  EchoFilter* {.importc, libsoloud.} = pointer
  Fader* {.importc, libsoloud.} = pointer
  FFTFilter* {.importc, libsoloud.} = pointer
  Filter* {.importc, libsoloud.} = pointer
  FlangerFilter* {.importc, libsoloud.} = pointer
  FreeverbFilter* {.importc, libsoloud.} = pointer
  LofiFilter* {.importc, libsoloud.} = pointer
  Queue* {.importc, libsoloud.} = pointer
  RobotizeFilter* {.importc, libsoloud.} = pointer
  Sfxr* {.importc, libsoloud.} = pointer
  Speech* {.importc, libsoloud.} = pointer
  Wav* {.importc, libsoloud.} = pointer
  WaveShaperFilter* {.importc, libsoloud.} = pointer
  WavStream* {.importc, libsoloud.} = pointer
  File* {.importc, libsoloud.} = pointer
proc Soloud_destroy*(aSoloud: ptr Soloud) {.importc, cdecl, libsoloud.}
  ## ```
  ##   Soloud
  ## ```
proc Soloud_create*(): ptr Soloud {.importc, cdecl, libsoloud.}
proc Soloud_init*(aSoloud: ptr Soloud): cint {.importc, cdecl, libsoloud.}
proc Soloud_initEx*(aSoloud: ptr Soloud; aFlags: cuint; aBackend: cuint;
                   aSamplerate: cuint; aBufferSize: cuint; aChannels: cuint): cint {.
    importc, cdecl, libsoloud.}
proc Soloud_deinit*(aSoloud: ptr Soloud) {.importc, cdecl, libsoloud.}
proc Soloud_getVersion*(aSoloud: ptr Soloud): cuint {.importc, cdecl, libsoloud.}
proc Soloud_getErrorString*(aSoloud: ptr Soloud; aErrorCode: cint): cstring {.importc,
    cdecl, libsoloud.}
proc Soloud_getBackendId*(aSoloud: ptr Soloud): cuint {.importc, cdecl, libsoloud.}
proc Soloud_getBackendString*(aSoloud: ptr Soloud): cstring {.importc, cdecl,
    libsoloud.}
proc Soloud_getBackendChannels*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_getBackendSamplerate*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_getBackendBufferSize*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_setSpeakerPosition*(aSoloud: ptr Soloud; aChannel: cuint; aX: cfloat;
                               aY: cfloat; aZ: cfloat): cint {.importc, cdecl,
    libsoloud.}
proc Soloud_getSpeakerPosition*(aSoloud: ptr Soloud; aChannel: cuint; aX: ptr cfloat;
                               aY: ptr cfloat; aZ: ptr cfloat): cint {.importc, cdecl,
    libsoloud.}
proc Soloud_play*(aSoloud: ptr Soloud; aSound: ptr AudioSource): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_playEx*(aSoloud: ptr Soloud; aSound: ptr AudioSource; aVolume: cfloat;
                   aPan: cfloat; aPaused: cint; aBus: cuint): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_playClocked*(aSoloud: ptr Soloud; aSoundTime: cdouble;
                        aSound: ptr AudioSource): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_playClockedEx*(aSoloud: ptr Soloud; aSoundTime: cdouble;
                          aSound: ptr AudioSource; aVolume: cfloat; aPan: cfloat;
                          aBus: cuint): cuint {.importc, cdecl, libsoloud.}
proc Soloud_play3d*(aSoloud: ptr Soloud; aSound: ptr AudioSource; aPosX: cfloat;
                   aPosY: cfloat; aPosZ: cfloat): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_play3dEx*(aSoloud: ptr Soloud; aSound: ptr AudioSource; aPosX: cfloat;
                     aPosY: cfloat; aPosZ: cfloat; aVelX: cfloat; aVelY: cfloat;
                     aVelZ: cfloat; aVolume: cfloat; aPaused: cint; aBus: cuint): cuint {.
    importc, cdecl, libsoloud.}
proc Soloud_play3dClocked*(aSoloud: ptr Soloud; aSoundTime: cdouble;
                          aSound: ptr AudioSource; aPosX: cfloat; aPosY: cfloat;
                          aPosZ: cfloat): cuint {.importc, cdecl, libsoloud.}
proc Soloud_play3dClockedEx*(aSoloud: ptr Soloud; aSoundTime: cdouble;
                            aSound: ptr AudioSource; aPosX: cfloat; aPosY: cfloat;
                            aPosZ: cfloat; aVelX: cfloat; aVelY: cfloat;
                            aVelZ: cfloat; aVolume: cfloat; aBus: cuint): cuint {.
    importc, cdecl, libsoloud.}
proc Soloud_playBackground*(aSoloud: ptr Soloud; aSound: ptr AudioSource): cuint {.
    importc, cdecl, libsoloud.}
proc Soloud_playBackgroundEx*(aSoloud: ptr Soloud; aSound: ptr AudioSource;
                             aVolume: cfloat; aPaused: cint; aBus: cuint): cuint {.
    importc, cdecl, libsoloud.}
proc Soloud_seek*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aSeconds: cdouble): cint {.
    importc, cdecl, libsoloud.}
proc Soloud_stop*(aSoloud: ptr Soloud; aVoiceHandle: cuint) {.importc, cdecl,
    libsoloud.}
proc Soloud_stopAll*(aSoloud: ptr Soloud) {.importc, cdecl, libsoloud.}
proc Soloud_stopAudioSource*(aSoloud: ptr Soloud; aSound: ptr AudioSource) {.importc,
    cdecl, libsoloud.}
proc Soloud_countAudioSource*(aSoloud: ptr Soloud; aSound: ptr AudioSource): cint {.
    importc, cdecl, libsoloud.}
proc Soloud_setFilterParameter*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                               aFilterId: cuint; aAttributeId: cuint; aValue: cfloat) {.
    importc, cdecl, libsoloud.}
proc Soloud_getFilterParameter*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                               aFilterId: cuint; aAttributeId: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc Soloud_fadeFilterParameter*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                aFilterId: cuint; aAttributeId: cuint; aTo: cfloat;
                                aTime: cdouble) {.importc, cdecl, libsoloud.}
proc Soloud_oscillateFilterParameter*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                     aFilterId: cuint; aAttributeId: cuint;
                                     aFrom: cfloat; aTo: cfloat; aTime: cdouble) {.
    importc, cdecl, libsoloud.}
proc Soloud_getStreamTime*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cdouble {.
    importc, cdecl, libsoloud.}
proc Soloud_getStreamPosition*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cdouble {.
    importc, cdecl, libsoloud.}
proc Soloud_getPause*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cint {.importc, cdecl,
    libsoloud.}
proc Soloud_getVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.importc,
    cdecl, libsoloud.}
proc Soloud_getOverallVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc Soloud_getPan*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc Soloud_getSamplerate*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.importc,
    cdecl, libsoloud.}
proc Soloud_getProtectVoice*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cint {.importc,
    cdecl, libsoloud.}
proc Soloud_getActiveVoiceCount*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_getVoiceCount*(aSoloud: ptr Soloud): cuint {.importc, cdecl, libsoloud.}
proc Soloud_isValidVoiceHandle*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cint {.
    importc, cdecl, libsoloud.}
proc Soloud_getRelativePlaySpeed*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc Soloud_getPostClipScaler*(aSoloud: ptr Soloud): cfloat {.importc, cdecl,
    libsoloud.}
proc Soloud_getGlobalVolume*(aSoloud: ptr Soloud): cfloat {.importc, cdecl,
    libsoloud.}
proc Soloud_getMaxActiveVoiceCount*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_getLooping*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cint {.importc,
    cdecl, libsoloud.}
proc Soloud_getLoopPoint*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cdouble {.importc,
    cdecl, libsoloud.}
proc Soloud_setLoopPoint*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                         aLoopPoint: cdouble) {.importc, cdecl, libsoloud.}
proc Soloud_setLooping*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aLooping: cint) {.
    importc, cdecl, libsoloud.}
proc Soloud_setMaxActiveVoiceCount*(aSoloud: ptr Soloud; aVoiceCount: cuint): cint {.
    importc, cdecl, libsoloud.}
proc Soloud_setInaudibleBehavior*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                 aMustTick: cint; aKill: cint) {.importc, cdecl,
    libsoloud.}
proc Soloud_setGlobalVolume*(aSoloud: ptr Soloud; aVolume: cfloat) {.importc, cdecl,
    libsoloud.}
proc Soloud_setPostClipScaler*(aSoloud: ptr Soloud; aScaler: cfloat) {.importc, cdecl,
    libsoloud.}
proc Soloud_setPause*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aPause: cint) {.importc,
    cdecl, libsoloud.}
proc Soloud_setPauseAll*(aSoloud: ptr Soloud; aPause: cint) {.importc, cdecl,
    libsoloud.}
proc Soloud_setRelativePlaySpeed*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                 aSpeed: cfloat): cint {.importc, cdecl,
    libsoloud.}
proc Soloud_setProtectVoice*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aProtect: cint) {.
    importc, cdecl, libsoloud.}
proc Soloud_setSamplerate*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                          aSamplerate: cfloat) {.importc, cdecl, libsoloud.}
proc Soloud_setPan*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aPan: cfloat) {.importc,
    cdecl, libsoloud.}
proc Soloud_setPanAbsolute*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                           aLVolume: cfloat; aRVolume: cfloat) {.importc, cdecl,
    libsoloud.}
proc Soloud_setPanAbsoluteEx*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                             aLVolume: cfloat; aRVolume: cfloat; aLBVolume: cfloat;
                             aRBVolume: cfloat; aCVolume: cfloat; aSVolume: cfloat) {.
    importc, cdecl, libsoloud.}
proc Soloud_setVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aVolume: cfloat) {.
    importc, cdecl, libsoloud.}
proc Soloud_setDelaySamples*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aSamples: cuint) {.
    importc, cdecl, libsoloud.}
proc Soloud_fadeVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aTo: cfloat;
                       aTime: cdouble) {.importc, cdecl, libsoloud.}
proc Soloud_fadePan*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aTo: cfloat;
                    aTime: cdouble) {.importc, cdecl, libsoloud.}
proc Soloud_fadeRelativePlaySpeed*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                  aTo: cfloat; aTime: cdouble) {.importc, cdecl,
    libsoloud.}
proc Soloud_fadeGlobalVolume*(aSoloud: ptr Soloud; aTo: cfloat; aTime: cdouble) {.
    importc, cdecl, libsoloud.}
proc Soloud_schedulePause*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aTime: cdouble) {.
    importc, cdecl, libsoloud.}
proc Soloud_scheduleStop*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aTime: cdouble) {.
    importc, cdecl, libsoloud.}
proc Soloud_oscillateVolume*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aFrom: cfloat;
                            aTo: cfloat; aTime: cdouble) {.importc, cdecl,
    libsoloud.}
proc Soloud_oscillatePan*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aFrom: cfloat;
                         aTo: cfloat; aTime: cdouble) {.importc, cdecl, libsoloud.}
proc Soloud_oscillateRelativePlaySpeed*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                       aFrom: cfloat; aTo: cfloat; aTime: cdouble) {.
    importc, cdecl, libsoloud.}
proc Soloud_oscillateGlobalVolume*(aSoloud: ptr Soloud; aFrom: cfloat; aTo: cfloat;
                                  aTime: cdouble) {.importc, cdecl, libsoloud.}
proc Soloud_setGlobalFilter*(aSoloud: ptr Soloud; aFilterId: cuint;
                            aFilter: ptr Filter) {.importc, cdecl, libsoloud.}
proc Soloud_setVisualizationEnable*(aSoloud: ptr Soloud; aEnable: cint) {.importc,
    cdecl, libsoloud.}
proc Soloud_calcFFT*(aSoloud: ptr Soloud): ptr cfloat {.importc, cdecl, libsoloud.}
proc Soloud_getWave*(aSoloud: ptr Soloud): ptr cfloat {.importc, cdecl, libsoloud.}
proc Soloud_getApproximateVolume*(aSoloud: ptr Soloud; aChannel: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc Soloud_getLoopCount*(aSoloud: ptr Soloud; aVoiceHandle: cuint): cuint {.importc,
    cdecl, libsoloud.}
proc Soloud_getInfo*(aSoloud: ptr Soloud; aVoiceHandle: cuint; aInfoKey: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc Soloud_createVoiceGroup*(aSoloud: ptr Soloud): cuint {.importc, cdecl,
    libsoloud.}
proc Soloud_destroyVoiceGroup*(aSoloud: ptr Soloud; aVoiceGroupHandle: cuint): cint {.
    importc, cdecl, libsoloud.}
proc Soloud_addVoiceToGroup*(aSoloud: ptr Soloud; aVoiceGroupHandle: cuint;
                            aVoiceHandle: cuint): cint {.importc, cdecl,
    libsoloud.}
proc Soloud_isVoiceGroup*(aSoloud: ptr Soloud; aVoiceGroupHandle: cuint): cint {.
    importc, cdecl, libsoloud.}
proc Soloud_isVoiceGroupEmpty*(aSoloud: ptr Soloud; aVoiceGroupHandle: cuint): cint {.
    importc, cdecl, libsoloud.}
proc Soloud_update3dAudio*(aSoloud: ptr Soloud) {.importc, cdecl, libsoloud.}
proc Soloud_set3dSoundSpeed*(aSoloud: ptr Soloud; aSpeed: cfloat): cint {.importc,
    cdecl, libsoloud.}
proc Soloud_get3dSoundSpeed*(aSoloud: ptr Soloud): cfloat {.importc, cdecl,
    libsoloud.}
proc Soloud_set3dListenerParameters*(aSoloud: ptr Soloud; aPosX: cfloat;
                                    aPosY: cfloat; aPosZ: cfloat; aAtX: cfloat;
                                    aAtY: cfloat; aAtZ: cfloat; aUpX: cfloat;
                                    aUpY: cfloat; aUpZ: cfloat) {.importc, cdecl,
    libsoloud.}
proc Soloud_set3dListenerParametersEx*(aSoloud: ptr Soloud; aPosX: cfloat;
                                      aPosY: cfloat; aPosZ: cfloat; aAtX: cfloat;
                                      aAtY: cfloat; aAtZ: cfloat; aUpX: cfloat;
                                      aUpY: cfloat; aUpZ: cfloat;
                                      aVelocityX: cfloat; aVelocityY: cfloat;
                                      aVelocityZ: cfloat) {.importc, cdecl,
    libsoloud.}
proc Soloud_set3dListenerPosition*(aSoloud: ptr Soloud; aPosX: cfloat; aPosY: cfloat;
                                  aPosZ: cfloat) {.importc, cdecl, libsoloud.}
proc Soloud_set3dListenerAt*(aSoloud: ptr Soloud; aAtX: cfloat; aAtY: cfloat;
                            aAtZ: cfloat) {.importc, cdecl, libsoloud.}
proc Soloud_set3dListenerUp*(aSoloud: ptr Soloud; aUpX: cfloat; aUpY: cfloat;
                            aUpZ: cfloat) {.importc, cdecl, libsoloud.}
proc Soloud_set3dListenerVelocity*(aSoloud: ptr Soloud; aVelocityX: cfloat;
                                  aVelocityY: cfloat; aVelocityZ: cfloat) {.importc,
    cdecl, libsoloud.}
proc Soloud_set3dSourceParameters*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                  aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat) {.
    importc, cdecl, libsoloud.}
proc Soloud_set3dSourceParametersEx*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                    aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat;
                                    aVelocityX: cfloat; aVelocityY: cfloat;
                                    aVelocityZ: cfloat) {.importc, cdecl,
    libsoloud.}
proc Soloud_set3dSourcePosition*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat) {.
    importc, cdecl, libsoloud.}
proc Soloud_set3dSourceVelocity*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                aVelocityX: cfloat; aVelocityY: cfloat;
                                aVelocityZ: cfloat) {.importc, cdecl, libsoloud.}
proc Soloud_set3dSourceMinMaxDistance*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                      aMinDistance: cfloat; aMaxDistance: cfloat) {.
    importc, cdecl, libsoloud.}
proc Soloud_set3dSourceAttenuation*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                   aAttenuationModel: cuint;
                                   aAttenuationRolloffFactor: cfloat) {.importc,
    cdecl, libsoloud.}
proc Soloud_set3dSourceDopplerFactor*(aSoloud: ptr Soloud; aVoiceHandle: cuint;
                                     aDopplerFactor: cfloat) {.importc, cdecl,
    libsoloud.}
proc Soloud_mix*(aSoloud: ptr Soloud; aBuffer: ptr cfloat; aSamples: cuint) {.importc,
    cdecl, libsoloud.}
proc Soloud_mixSigned16*(aSoloud: ptr Soloud; aBuffer: ptr cshort; aSamples: cuint) {.
    importc, cdecl, libsoloud.}
proc BassboostFilter_destroy*(aBassboostFilter: ptr BassboostFilter) {.importc,
    cdecl, libsoloud.}
  ## ```
  ##   BassboostFilter
  ## ```
proc BassboostFilter_getParamCount*(aBassboostFilter: ptr BassboostFilter): cint {.
    importc, cdecl, libsoloud.}
proc BassboostFilter_getParamName*(aBassboostFilter: ptr BassboostFilter;
                                  aParamIndex: cuint): cstring {.importc, cdecl,
    libsoloud.}
proc BassboostFilter_getParamType*(aBassboostFilter: ptr BassboostFilter;
                                  aParamIndex: cuint): cuint {.importc, cdecl,
    libsoloud.}
proc BassboostFilter_getParamMax*(aBassboostFilter: ptr BassboostFilter;
                                 aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc BassboostFilter_getParamMin*(aBassboostFilter: ptr BassboostFilter;
                                 aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc BassboostFilter_setParams*(aBassboostFilter: ptr BassboostFilter;
                               aBoost: cfloat): cint {.importc, cdecl, libsoloud.}
proc BassboostFilter_create*(): ptr BassboostFilter {.importc, cdecl, libsoloud.}
proc BiquadResonantFilter_destroy*(aBiquadResonantFilter: ptr BiquadResonantFilter) {.
    importc, cdecl, libsoloud.}
  ## ```
  ##   BiquadResonantFilter
  ## ```
proc BiquadResonantFilter_getParamCount*(aBiquadResonantFilter: ptr BiquadResonantFilter): cint {.
    importc, cdecl, libsoloud.}
proc BiquadResonantFilter_getParamName*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                       aParamIndex: cuint): cstring {.importc,
    cdecl, libsoloud.}
proc BiquadResonantFilter_getParamType*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                       aParamIndex: cuint): cuint {.importc, cdecl,
    libsoloud.}
proc BiquadResonantFilter_getParamMax*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                      aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc BiquadResonantFilter_getParamMin*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                      aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc BiquadResonantFilter_create*(): ptr BiquadResonantFilter {.importc, cdecl,
    libsoloud.}
proc BiquadResonantFilter_setParams*(aBiquadResonantFilter: ptr BiquadResonantFilter;
                                    aType: cint; aFrequency: cfloat;
                                    aResonance: cfloat): cint {.importc, cdecl,
    libsoloud.}
proc Bus_destroy*(aBus: ptr Bus) {.importc, cdecl, libsoloud.}
  ## ```
  ##   Bus
  ## ```
proc Bus_create*(): ptr Bus {.importc, cdecl, libsoloud.}
proc Bus_setFilter*(aBus: ptr Bus; aFilterId: cuint; aFilter: ptr Filter) {.importc,
    cdecl, libsoloud.}
proc Bus_play*(aBus: ptr Bus; aSound: ptr AudioSource): cuint {.importc, cdecl,
    libsoloud.}
proc Bus_playEx*(aBus: ptr Bus; aSound: ptr AudioSource; aVolume: cfloat; aPan: cfloat;
                aPaused: cint): cuint {.importc, cdecl, libsoloud.}
proc Bus_playClocked*(aBus: ptr Bus; aSoundTime: cdouble; aSound: ptr AudioSource): cuint {.
    importc, cdecl, libsoloud.}
proc Bus_playClockedEx*(aBus: ptr Bus; aSoundTime: cdouble; aSound: ptr AudioSource;
                       aVolume: cfloat; aPan: cfloat): cuint {.importc, cdecl,
    libsoloud.}
proc Bus_play3d*(aBus: ptr Bus; aSound: ptr AudioSource; aPosX: cfloat; aPosY: cfloat;
                aPosZ: cfloat): cuint {.importc, cdecl, libsoloud.}
proc Bus_play3dEx*(aBus: ptr Bus; aSound: ptr AudioSource; aPosX: cfloat; aPosY: cfloat;
                  aPosZ: cfloat; aVelX: cfloat; aVelY: cfloat; aVelZ: cfloat;
                  aVolume: cfloat; aPaused: cint): cuint {.importc, cdecl,
    libsoloud.}
proc Bus_play3dClocked*(aBus: ptr Bus; aSoundTime: cdouble; aSound: ptr AudioSource;
                       aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat): cuint {.importc,
    cdecl, libsoloud.}
proc Bus_play3dClockedEx*(aBus: ptr Bus; aSoundTime: cdouble; aSound: ptr AudioSource;
                         aPosX: cfloat; aPosY: cfloat; aPosZ: cfloat; aVelX: cfloat;
                         aVelY: cfloat; aVelZ: cfloat; aVolume: cfloat): cuint {.
    importc, cdecl, libsoloud.}
proc Bus_setChannels*(aBus: ptr Bus; aChannels: cuint): cint {.importc, cdecl,
    libsoloud.}
proc Bus_setVisualizationEnable*(aBus: ptr Bus; aEnable: cint) {.importc, cdecl,
    libsoloud.}
proc Bus_annexSound*(aBus: ptr Bus; aVoiceHandle: cuint) {.importc, cdecl,
    libsoloud.}
proc Bus_calcFFT*(aBus: ptr Bus): ptr cfloat {.importc, cdecl, libsoloud.}
proc Bus_getWave*(aBus: ptr Bus): ptr cfloat {.importc, cdecl, libsoloud.}
proc Bus_getApproximateVolume*(aBus: ptr Bus; aChannel: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc Bus_getActiveVoiceCount*(aBus: ptr Bus): cuint {.importc, cdecl, libsoloud.}
proc Bus_setVolume*(aBus: ptr Bus; aVolume: cfloat) {.importc, cdecl, libsoloud.}
proc Bus_setLooping*(aBus: ptr Bus; aLoop: cint) {.importc, cdecl, libsoloud.}
proc Bus_set3dMinMaxDistance*(aBus: ptr Bus; aMinDistance: cfloat;
                             aMaxDistance: cfloat) {.importc, cdecl, libsoloud.}
proc Bus_set3dAttenuation*(aBus: ptr Bus; aAttenuationModel: cuint;
                          aAttenuationRolloffFactor: cfloat) {.importc, cdecl,
    libsoloud.}
proc Bus_set3dDopplerFactor*(aBus: ptr Bus; aDopplerFactor: cfloat) {.importc, cdecl,
    libsoloud.}
proc Bus_set3dListenerRelative*(aBus: ptr Bus; aListenerRelative: cint) {.importc,
    cdecl, libsoloud.}
proc Bus_set3dDistanceDelay*(aBus: ptr Bus; aDistanceDelay: cint) {.importc, cdecl,
    libsoloud.}
proc Bus_set3dCollider*(aBus: ptr Bus; aCollider: ptr AudioCollider) {.importc, cdecl,
    libsoloud.}
proc Bus_set3dColliderEx*(aBus: ptr Bus; aCollider: ptr AudioCollider; aUserData: cint) {.
    importc, cdecl, libsoloud.}
proc Bus_set3dAttenuator*(aBus: ptr Bus; aAttenuator: ptr AudioAttenuator) {.importc,
    cdecl, libsoloud.}
proc Bus_setInaudibleBehavior*(aBus: ptr Bus; aMustTick: cint; aKill: cint) {.importc,
    cdecl, libsoloud.}
proc Bus_setLoopPoint*(aBus: ptr Bus; aLoopPoint: cdouble) {.importc, cdecl,
    libsoloud.}
proc Bus_getLoopPoint*(aBus: ptr Bus): cdouble {.importc, cdecl, libsoloud.}
proc Bus_stop*(aBus: ptr Bus) {.importc, cdecl, libsoloud.}
proc DCRemovalFilter_destroy*(aDCRemovalFilter: ptr DCRemovalFilter) {.importc,
    cdecl, libsoloud.}
  ## ```
  ##   DCRemovalFilter
  ## ```
proc DCRemovalFilter_create*(): ptr DCRemovalFilter {.importc, cdecl, libsoloud.}
proc DCRemovalFilter_setParams*(aDCRemovalFilter: ptr DCRemovalFilter): cint {.
    importc, cdecl, libsoloud.}
proc DCRemovalFilter_setParamsEx*(aDCRemovalFilter: ptr DCRemovalFilter;
                                 aLength: cfloat): cint {.importc, cdecl,
    libsoloud.}
proc DCRemovalFilter_getParamCount*(aDCRemovalFilter: ptr DCRemovalFilter): cint {.
    importc, cdecl, libsoloud.}
proc DCRemovalFilter_getParamName*(aDCRemovalFilter: ptr DCRemovalFilter;
                                  aParamIndex: cuint): cstring {.importc, cdecl,
    libsoloud.}
proc DCRemovalFilter_getParamType*(aDCRemovalFilter: ptr DCRemovalFilter;
                                  aParamIndex: cuint): cuint {.importc, cdecl,
    libsoloud.}
proc DCRemovalFilter_getParamMax*(aDCRemovalFilter: ptr DCRemovalFilter;
                                 aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc DCRemovalFilter_getParamMin*(aDCRemovalFilter: ptr DCRemovalFilter;
                                 aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc EchoFilter_destroy*(aEchoFilter: ptr EchoFilter) {.importc, cdecl, libsoloud.}
  ## ```
  ##   EchoFilter
  ## ```
proc EchoFilter_getParamCount*(aEchoFilter: ptr EchoFilter): cint {.importc, cdecl,
    libsoloud.}
proc EchoFilter_getParamName*(aEchoFilter: ptr EchoFilter; aParamIndex: cuint): cstring {.
    importc, cdecl, libsoloud.}
proc EchoFilter_getParamType*(aEchoFilter: ptr EchoFilter; aParamIndex: cuint): cuint {.
    importc, cdecl, libsoloud.}
proc EchoFilter_getParamMax*(aEchoFilter: ptr EchoFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc EchoFilter_getParamMin*(aEchoFilter: ptr EchoFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc EchoFilter_create*(): ptr EchoFilter {.importc, cdecl, libsoloud.}
proc EchoFilter_setParams*(aEchoFilter: ptr EchoFilter; aDelay: cfloat): cint {.
    importc, cdecl, libsoloud.}
proc EchoFilter_setParamsEx*(aEchoFilter: ptr EchoFilter; aDelay: cfloat;
                            aDecay: cfloat; aFilter: cfloat): cint {.importc, cdecl,
    libsoloud.}
proc FFTFilter_destroy*(aFFTFilter: ptr FFTFilter) {.importc, cdecl, libsoloud.}
  ## ```
  ##   FFTFilter
  ## ```
proc FFTFilter_create*(): ptr FFTFilter {.importc, cdecl, libsoloud.}
proc FFTFilter_getParamCount*(aFFTFilter: ptr FFTFilter): cint {.importc, cdecl,
    libsoloud.}
proc FFTFilter_getParamName*(aFFTFilter: ptr FFTFilter; aParamIndex: cuint): cstring {.
    importc, cdecl, libsoloud.}
proc FFTFilter_getParamType*(aFFTFilter: ptr FFTFilter; aParamIndex: cuint): cuint {.
    importc, cdecl, libsoloud.}
proc FFTFilter_getParamMax*(aFFTFilter: ptr FFTFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc FFTFilter_getParamMin*(aFFTFilter: ptr FFTFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc FlangerFilter_destroy*(aFlangerFilter: ptr FlangerFilter) {.importc, cdecl,
    libsoloud.}
  ## ```
  ##   FlangerFilter
  ## ```
proc FlangerFilter_getParamCount*(aFlangerFilter: ptr FlangerFilter): cint {.importc,
    cdecl, libsoloud.}
proc FlangerFilter_getParamName*(aFlangerFilter: ptr FlangerFilter;
                                aParamIndex: cuint): cstring {.importc, cdecl,
    libsoloud.}
proc FlangerFilter_getParamType*(aFlangerFilter: ptr FlangerFilter;
                                aParamIndex: cuint): cuint {.importc, cdecl,
    libsoloud.}
proc FlangerFilter_getParamMax*(aFlangerFilter: ptr FlangerFilter;
                               aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc FlangerFilter_getParamMin*(aFlangerFilter: ptr FlangerFilter;
                               aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc FlangerFilter_create*(): ptr FlangerFilter {.importc, cdecl, libsoloud.}
proc FlangerFilter_setParams*(aFlangerFilter: ptr FlangerFilter; aDelay: cfloat;
                             aFreq: cfloat): cint {.importc, cdecl, libsoloud.}
proc FreeverbFilter_destroy*(aFreeverbFilter: ptr FreeverbFilter) {.importc, cdecl,
    libsoloud.}
  ## ```
  ##   FreeverbFilter
  ## ```
proc FreeverbFilter_getParamCount*(aFreeverbFilter: ptr FreeverbFilter): cint {.
    importc, cdecl, libsoloud.}
proc FreeverbFilter_getParamName*(aFreeverbFilter: ptr FreeverbFilter;
                                 aParamIndex: cuint): cstring {.importc, cdecl,
    libsoloud.}
proc FreeverbFilter_getParamType*(aFreeverbFilter: ptr FreeverbFilter;
                                 aParamIndex: cuint): cuint {.importc, cdecl,
    libsoloud.}
proc FreeverbFilter_getParamMax*(aFreeverbFilter: ptr FreeverbFilter;
                                aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc FreeverbFilter_getParamMin*(aFreeverbFilter: ptr FreeverbFilter;
                                aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc FreeverbFilter_create*(): ptr FreeverbFilter {.importc, cdecl, libsoloud.}
proc FreeverbFilter_setParams*(aFreeverbFilter: ptr FreeverbFilter; aMode: cfloat;
                              aRoomSize: cfloat; aDamp: cfloat; aWidth: cfloat): cint {.
    importc, cdecl, libsoloud.}
proc LofiFilter_destroy*(aLofiFilter: ptr LofiFilter) {.importc, cdecl, libsoloud.}
  ## ```
  ##   LofiFilter
  ## ```
proc LofiFilter_getParamCount*(aLofiFilter: ptr LofiFilter): cint {.importc, cdecl,
    libsoloud.}
proc LofiFilter_getParamName*(aLofiFilter: ptr LofiFilter; aParamIndex: cuint): cstring {.
    importc, cdecl, libsoloud.}
proc LofiFilter_getParamType*(aLofiFilter: ptr LofiFilter; aParamIndex: cuint): cuint {.
    importc, cdecl, libsoloud.}
proc LofiFilter_getParamMax*(aLofiFilter: ptr LofiFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc LofiFilter_getParamMin*(aLofiFilter: ptr LofiFilter; aParamIndex: cuint): cfloat {.
    importc, cdecl, libsoloud.}
proc LofiFilter_create*(): ptr LofiFilter {.importc, cdecl, libsoloud.}
proc LofiFilter_setParams*(aLofiFilter: ptr LofiFilter; aSampleRate: cfloat;
                          aBitdepth: cfloat): cint {.importc, cdecl, libsoloud.}
proc Queue_destroy*(aQueue: ptr Queue) {.importc, cdecl, libsoloud.}
  ## ```
  ##   Queue
  ## ```
proc Queue_create*(): ptr Queue {.importc, cdecl, libsoloud.}
proc Queue_play*(aQueue: ptr Queue; aSound: ptr AudioSource): cint {.importc, cdecl,
    libsoloud.}
proc Queue_getQueueCount*(aQueue: ptr Queue): cuint {.importc, cdecl, libsoloud.}
proc Queue_isCurrentlyPlaying*(aQueue: ptr Queue; aSound: ptr AudioSource): cint {.
    importc, cdecl, libsoloud.}
proc Queue_setParamsFromAudioSource*(aQueue: ptr Queue; aSound: ptr AudioSource): cint {.
    importc, cdecl, libsoloud.}
proc Queue_setParams*(aQueue: ptr Queue; aSamplerate: cfloat): cint {.importc, cdecl,
    libsoloud.}
proc Queue_setParamsEx*(aQueue: ptr Queue; aSamplerate: cfloat; aChannels: cuint): cint {.
    importc, cdecl, libsoloud.}
proc Queue_setVolume*(aQueue: ptr Queue; aVolume: cfloat) {.importc, cdecl,
    libsoloud.}
proc Queue_setLooping*(aQueue: ptr Queue; aLoop: cint) {.importc, cdecl, libsoloud.}
proc Queue_set3dMinMaxDistance*(aQueue: ptr Queue; aMinDistance: cfloat;
                               aMaxDistance: cfloat) {.importc, cdecl,
    libsoloud.}
proc Queue_set3dAttenuation*(aQueue: ptr Queue; aAttenuationModel: cuint;
                            aAttenuationRolloffFactor: cfloat) {.importc, cdecl,
    libsoloud.}
proc Queue_set3dDopplerFactor*(aQueue: ptr Queue; aDopplerFactor: cfloat) {.importc,
    cdecl, libsoloud.}
proc Queue_set3dListenerRelative*(aQueue: ptr Queue; aListenerRelative: cint) {.
    importc, cdecl, libsoloud.}
proc Queue_set3dDistanceDelay*(aQueue: ptr Queue; aDistanceDelay: cint) {.importc,
    cdecl, libsoloud.}
proc Queue_set3dCollider*(aQueue: ptr Queue; aCollider: ptr AudioCollider) {.importc,
    cdecl, libsoloud.}
proc Queue_set3dColliderEx*(aQueue: ptr Queue; aCollider: ptr AudioCollider;
                           aUserData: cint) {.importc, cdecl, libsoloud.}
proc Queue_set3dAttenuator*(aQueue: ptr Queue; aAttenuator: ptr AudioAttenuator) {.
    importc, cdecl, libsoloud.}
proc Queue_setInaudibleBehavior*(aQueue: ptr Queue; aMustTick: cint; aKill: cint) {.
    importc, cdecl, libsoloud.}
proc Queue_setLoopPoint*(aQueue: ptr Queue; aLoopPoint: cdouble) {.importc, cdecl,
    libsoloud.}
proc Queue_getLoopPoint*(aQueue: ptr Queue): cdouble {.importc, cdecl, libsoloud.}
proc Queue_setFilter*(aQueue: ptr Queue; aFilterId: cuint; aFilter: ptr Filter) {.
    importc, cdecl, libsoloud.}
proc Queue_stop*(aQueue: ptr Queue) {.importc, cdecl, libsoloud.}
proc RobotizeFilter_destroy*(aRobotizeFilter: ptr RobotizeFilter) {.importc, cdecl,
    libsoloud.}
  ## ```
  ##   RobotizeFilter
  ## ```
proc RobotizeFilter_getParamCount*(aRobotizeFilter: ptr RobotizeFilter): cint {.
    importc, cdecl, libsoloud.}
proc RobotizeFilter_getParamName*(aRobotizeFilter: ptr RobotizeFilter;
                                 aParamIndex: cuint): cstring {.importc, cdecl,
    libsoloud.}
proc RobotizeFilter_getParamType*(aRobotizeFilter: ptr RobotizeFilter;
                                 aParamIndex: cuint): cuint {.importc, cdecl,
    libsoloud.}
proc RobotizeFilter_getParamMax*(aRobotizeFilter: ptr RobotizeFilter;
                                aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc RobotizeFilter_getParamMin*(aRobotizeFilter: ptr RobotizeFilter;
                                aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc RobotizeFilter_setParams*(aRobotizeFilter: ptr RobotizeFilter; aFreq: cfloat;
                              aWaveform: cint) {.importc, cdecl, libsoloud.}
proc RobotizeFilter_create*(): ptr RobotizeFilter {.importc, cdecl, libsoloud.}
proc Wav_destroy*(aWav: ptr Wav) {.importc, cdecl, libsoloud.}
  ## ```
  ##   Wav
  ## ```
proc Wav_create*(): ptr Wav {.importc, cdecl, libsoloud.}
proc Wav_load*(aWav: ptr Wav; aFilename: cstring): cint {.importc, cdecl, libsoloud.}
proc Wav_loadMem*(aWav: ptr Wav; aMem: ptr cuchar; aLength: cuint): cint {.importc, cdecl,
    libsoloud.}
proc Wav_loadMemEx*(aWav: ptr Wav; aMem: ptr cuchar; aLength: cuint; aCopy: cint;
                   aTakeOwnership: cint): cint {.importc, cdecl, libsoloud.}
proc Wav_loadFile*(aWav: ptr Wav; aFile: ptr File): cint {.importc, cdecl, libsoloud.}
proc Wav_loadRawWave8*(aWav: ptr Wav; aMem: ptr cuchar; aLength: cuint): cint {.importc,
    cdecl, libsoloud.}
proc Wav_loadRawWave8Ex*(aWav: ptr Wav; aMem: ptr cuchar; aLength: cuint;
                        aSamplerate: cfloat; aChannels: cuint): cint {.importc, cdecl,
    libsoloud.}
proc Wav_loadRawWave16*(aWav: ptr Wav; aMem: ptr cshort; aLength: cuint): cint {.importc,
    cdecl, libsoloud.}
proc Wav_loadRawWave16Ex*(aWav: ptr Wav; aMem: ptr cshort; aLength: cuint;
                         aSamplerate: cfloat; aChannels: cuint): cint {.importc,
    cdecl, libsoloud.}
proc Wav_loadRawWave*(aWav: ptr Wav; aMem: ptr cfloat; aLength: cuint): cint {.importc,
    cdecl, libsoloud.}
proc Wav_loadRawWaveEx*(aWav: ptr Wav; aMem: ptr cfloat; aLength: cuint;
                       aSamplerate: cfloat; aChannels: cuint; aCopy: cint;
                       aTakeOwnership: cint): cint {.importc, cdecl, libsoloud.}
proc Wav_getLength*(aWav: ptr Wav): cdouble {.importc, cdecl, libsoloud.}
proc Wav_setVolume*(aWav: ptr Wav; aVolume: cfloat) {.importc, cdecl, libsoloud.}
proc Wav_setLooping*(aWav: ptr Wav; aLoop: cint) {.importc, cdecl, libsoloud.}
proc Wav_set3dMinMaxDistance*(aWav: ptr Wav; aMinDistance: cfloat;
                             aMaxDistance: cfloat) {.importc, cdecl, libsoloud.}
proc Wav_set3dAttenuation*(aWav: ptr Wav; aAttenuationModel: cuint;
                          aAttenuationRolloffFactor: cfloat) {.importc, cdecl,
    libsoloud.}
proc Wav_set3dDopplerFactor*(aWav: ptr Wav; aDopplerFactor: cfloat) {.importc, cdecl,
    libsoloud.}
proc Wav_set3dListenerRelative*(aWav: ptr Wav; aListenerRelative: cint) {.importc,
    cdecl, libsoloud.}
proc Wav_set3dDistanceDelay*(aWav: ptr Wav; aDistanceDelay: cint) {.importc, cdecl,
    libsoloud.}
proc Wav_set3dCollider*(aWav: ptr Wav; aCollider: ptr AudioCollider) {.importc, cdecl,
    libsoloud.}
proc Wav_set3dColliderEx*(aWav: ptr Wav; aCollider: ptr AudioCollider; aUserData: cint) {.
    importc, cdecl, libsoloud.}
proc Wav_set3dAttenuator*(aWav: ptr Wav; aAttenuator: ptr AudioAttenuator) {.importc,
    cdecl, libsoloud.}
proc Wav_setInaudibleBehavior*(aWav: ptr Wav; aMustTick: cint; aKill: cint) {.importc,
    cdecl, libsoloud.}
proc Wav_setLoopPoint*(aWav: ptr Wav; aLoopPoint: cdouble) {.importc, cdecl,
    libsoloud.}
proc Wav_getLoopPoint*(aWav: ptr Wav): cdouble {.importc, cdecl, libsoloud.}
proc Wav_setFilter*(aWav: ptr Wav; aFilterId: cuint; aFilter: ptr Filter) {.importc,
    cdecl, libsoloud.}
proc Wav_stop*(aWav: ptr Wav) {.importc, cdecl, libsoloud.}
proc WaveShaperFilter_destroy*(aWaveShaperFilter: ptr WaveShaperFilter) {.importc,
    cdecl, libsoloud.}
  ## ```
  ##   WaveShaperFilter
  ## ```
proc WaveShaperFilter_setParams*(aWaveShaperFilter: ptr WaveShaperFilter;
                                aAmount: cfloat): cint {.importc, cdecl,
    libsoloud.}
proc WaveShaperFilter_create*(): ptr WaveShaperFilter {.importc, cdecl, libsoloud.}
proc WaveShaperFilter_getParamCount*(aWaveShaperFilter: ptr WaveShaperFilter): cint {.
    importc, cdecl, libsoloud.}
proc WaveShaperFilter_getParamName*(aWaveShaperFilter: ptr WaveShaperFilter;
                                   aParamIndex: cuint): cstring {.importc, cdecl,
    libsoloud.}
proc WaveShaperFilter_getParamType*(aWaveShaperFilter: ptr WaveShaperFilter;
                                   aParamIndex: cuint): cuint {.importc, cdecl,
    libsoloud.}
proc WaveShaperFilter_getParamMax*(aWaveShaperFilter: ptr WaveShaperFilter;
                                  aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc WaveShaperFilter_getParamMin*(aWaveShaperFilter: ptr WaveShaperFilter;
                                  aParamIndex: cuint): cfloat {.importc, cdecl,
    libsoloud.}
proc WavStream_destroy*(aWavStream: ptr WavStream) {.importc, cdecl, libsoloud.}
  ## ```
  ##   WavStream
  ## ```
proc WavStream_create*(): ptr WavStream {.importc, cdecl, libsoloud.}
proc WavStream_load*(aWavStream: ptr WavStream; aFilename: cstring): cint {.importc,
    cdecl, libsoloud.}
proc WavStream_loadMem*(aWavStream: ptr WavStream; aData: ptr cuchar; aDataLen: cuint): cint {.
    importc, cdecl, libsoloud.}
proc WavStream_loadMemEx*(aWavStream: ptr WavStream; aData: ptr cuchar;
                         aDataLen: cuint; aCopy: cint; aTakeOwnership: cint): cint {.
    importc, cdecl, libsoloud.}
proc WavStream_loadToMem*(aWavStream: ptr WavStream; aFilename: cstring): cint {.
    importc, cdecl, libsoloud.}
proc WavStream_loadFile*(aWavStream: ptr WavStream; aFile: ptr File): cint {.importc,
    cdecl, libsoloud.}
proc WavStream_loadFileToMem*(aWavStream: ptr WavStream; aFile: ptr File): cint {.
    importc, cdecl, libsoloud.}
proc WavStream_getLength*(aWavStream: ptr WavStream): cdouble {.importc, cdecl,
    libsoloud.}
proc WavStream_setVolume*(aWavStream: ptr WavStream; aVolume: cfloat) {.importc, cdecl,
    libsoloud.}
proc WavStream_setLooping*(aWavStream: ptr WavStream; aLoop: cint) {.importc, cdecl,
    libsoloud.}
proc WavStream_set3dMinMaxDistance*(aWavStream: ptr WavStream; aMinDistance: cfloat;
                                   aMaxDistance: cfloat) {.importc, cdecl,
    libsoloud.}
proc WavStream_set3dAttenuation*(aWavStream: ptr WavStream;
                                aAttenuationModel: cuint;
                                aAttenuationRolloffFactor: cfloat) {.importc,
    cdecl, libsoloud.}
proc WavStream_set3dDopplerFactor*(aWavStream: ptr WavStream; aDopplerFactor: cfloat) {.
    importc, cdecl, libsoloud.}
proc WavStream_set3dListenerRelative*(aWavStream: ptr WavStream;
                                     aListenerRelative: cint) {.importc, cdecl,
    libsoloud.}
proc WavStream_set3dDistanceDelay*(aWavStream: ptr WavStream; aDistanceDelay: cint) {.
    importc, cdecl, libsoloud.}
proc WavStream_set3dCollider*(aWavStream: ptr WavStream;
                             aCollider: ptr AudioCollider) {.importc, cdecl,
    libsoloud.}
proc WavStream_set3dColliderEx*(aWavStream: ptr WavStream;
                               aCollider: ptr AudioCollider; aUserData: cint) {.
    importc, cdecl, libsoloud.}
proc WavStream_set3dAttenuator*(aWavStream: ptr WavStream;
                               aAttenuator: ptr AudioAttenuator) {.importc, cdecl,
    libsoloud.}
proc WavStream_setInaudibleBehavior*(aWavStream: ptr WavStream; aMustTick: cint;
                                    aKill: cint) {.importc, cdecl, libsoloud.}
proc WavStream_setLoopPoint*(aWavStream: ptr WavStream; aLoopPoint: cdouble) {.
    importc, cdecl, libsoloud.}
proc WavStream_getLoopPoint*(aWavStream: ptr WavStream): cdouble {.importc, cdecl,
    libsoloud.}
proc WavStream_setFilter*(aWavStream: ptr WavStream; aFilterId: cuint;
                         aFilter: ptr Filter) {.importc, cdecl, libsoloud.}
proc WavStream_stop*(aWavStream: ptr WavStream) {.importc, cdecl, libsoloud.}
