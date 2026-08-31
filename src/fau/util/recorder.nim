import ../draw, ../globals, ../fmath, ../input, ../color, ../framebuffer, std/[os, strformat, times, osproc, math, streams, strutils]

const
  resizeKey = keyLctrl
  openKey = keyE
  recordKey = keyT
  shiftKey = keyLshift

var
  gifOutDir = "gifs"
  speedMultiplier* = 1f
  recordFps* = 45f
  recordSize* = vec2(300f)
  recordOffset* = vec2(0f)
  recording = false
  open = false
  mp4 = true
  ftime = 0f
  #streaming state
  ffmpegProc: Process
  procStream: Stream
  outFile: string
  frameLen: int

proc stopFfmpegProcess() =
  if not procStream.isNil:
    try:
      procStream.close()
    except:
      discard
    procStream = nil

  if not ffmpegProc.isNil:
    let exitCode = ffmpegProc.waitForExit()
    #surface ffmpeg's stdout/stderr (merged via poStdErrToStdOut) if it failed
    if exitCode != 0:
      try:
        echo &"ffmpeg exited with code {exitCode}:"
        echo ffmpegProc.outputStream.readAll()
      except:
        discard
    ffmpegProc.close()
    ffmpegProc = nil

proc startRecording() =
  gifOutDir.createDir()

  let
    dateStr = now().format("yyyy-MM-dd-hh-mm-ss")
    w = recordSize.x.int
    h = recordSize.y.int
    ext = if mp4: "mp4" else: "gif"
    filters = if mp4: "" else: ",split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
    codec = if mp4: "-c:v libx264 -pix_fmt yuv420p" else: "-c:v gif"

  frameLen = w * h * 4
  outFile = &"{gifOutDir}/{dateStr}.{ext}"

  try:
    ffmpegProc = startProcess(
      &"ffmpeg -r {recordFps} -s {w}x{h} -f rawvideo -pix_fmt rgba -i - -filter:v \"vflip{filters}\" {codec} {outFile}",
      options = {poEvalCommand, poStdErrToStdOut}
    )
    procStream = ffmpegProc.inputStream
    recording = true
    ftime = 0f
  except:
    echo getCurrentExceptionMsg()
    ffmpegProc = nil
    procStream = nil
    recording = false

proc finishRecording() =
  recording = false
  stopFfmpegProcess()

  try:
    let fullPath = outFile.expandFilename
    discard startProcess(&"echo \"file://{fullPath}\" | xclip -sel clip -t text/uri-list -i", options = {poEvalCommand})
  except:
    echo getCurrentExceptionMsg()

  ftime = 0f

proc cancelRecording() =
  recording = false
  stopFfmpegProcess()
  #remove the partial/invalid output file, if it exists
  try:
    if outFile.len > 0 and outFile.fileExists:
      outFile.removeFile
  except:
    discard
  ftime = 0f

proc record*() =
  if not fau.captureKeyboard:

    if openKey.tapped:
      if recording:
        cancelRecording()
      open = not open

    #start/stop recording
    if open and recordKey.tapped:
      if not recording:
        startRecording()
      else:
        finishRecording()

  #grab pixels and stream them straight to ffmpeg
  if recording and open:
    ftime += fau.rawDelta * 60.1f * speedMultiplier
    if ftime >= 60f / recordFps:
      ftime = ftime.mod 60f / recordFps

      let frame = fau.screen.read(
         (recordOffset + fau.size/2f - recordSize/2f).vec2i,
         recordSize.vec2i
       )

      if not procStream.isNil:
        try:
          procStream.writeData(frame, frameLen)
          procStream.flush()
        except:
          echo getCurrentExceptionMsg()
          recording = false
          stopFfmpegProcess()

      frame.dealloc

  #draw selection UI
  if open:
    var color = if mp4: %"1dc5b7" else: %"2890eb"

    if recording:
      color = %"f54033"
    
    drawStack:
  
      if resizeKey.down and not recording and not fau.captureKeyboard:
        color = %"f59827"
        recordSize = ((fau.size/2f + recordOffset - fau.mouse).abs * 2f).round(2f)
  
      if shiftKey.down and not fau.captureKeyboard:
        recordOffset = fau.mouse - fau.size/2f
        color = %"27e67a"
  
      if keyF12.tapped:
        mp4 = not mp4
  
      for entry in [(color: colorBlack, stroke: 8f), (color: color, stroke: 2f)]:
        lineRect(
          recordOffset + fau.size/2f - recordSize/2f,
          recordSize,
          color = entry.color,
          stroke = entry.stroke
        )