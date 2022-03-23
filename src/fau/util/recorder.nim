import ../draw, ../globals, ../fmath, ../input, ../screenbuffer, ../color, os, strformat, times, osproc, math, streams, strutils

const
  resizeKey = keyLctrl
  openKey = keyE
  recordKey = keyT
  shiftKey = keyLshift

var
  gifOutDir = "gifs"
  speedMultiplier* = 1f
  recordFps* = 40f
  recordSize* = vec2(300f)
  recordOffset* = vec2(0f)
  recording = false
  open = false
  mp4 = true
  ftime = 0f
  frames: seq[pointer]

proc clearFrames() =
  for f in frames:
    f.dealloc
  frames = @[]

proc record*() =
  if openKey.tapped:
    if recording:
      clearFrames()
      recording = false
    open = not open

  #start/stop recording
  if open and recordKey.tapped:
    if not recording:
      clearFrames()
      recording = true
    else:
      recording = false
      gifOutDir.createDir()

      let
        dateStr = now().format("yyyy-MM-dd-hh-mm-ss")
        w = recordSize.x.int
        h = recordSize.y.int
        ext = if mp4: "mp4" else: "gif"
        filters = if mp4: "" else: ",split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
        len = w * h * 4

      var
        p = startProcess(
          &"ffmpeg -r {recordFps} -s {w}x{h} -f rawvideo -pix_fmt rgba -i - -frames:v {frames.len} -filter:v \"vflip{filters}\" {gifOutDir}/{dateStr}.{ext}",
          options = {poEvalCommand, poStdErrToStdOut}
        )
        stream = p.inputStream

      for frame in frames:
        stream.writeData(frame, len)
        stream.flush()

      stream.close()
      discard p.waitForExit()

      clearFrames()
      ftime = 0f

  #grab pixels
  if recording and open:
    ftime += fau.delta * 60.1f * speedMultiplier
    if ftime >= 60f / recordFps:
      ftime = ftime.mod 60f / recordFps

      frames.add screen.read(
         (recordOffset + fau.size/2f - recordSize/2f).vec2i,
         recordSize.vec2i
       )

  #draw selection UI
  if open:
    var color = %"2890eb"

    if recording:
      color = %"f54033"

    drawMat(ortho(vec2(), fau.size))

    if resizeKey.down and not recording:
      color = %"f59827"
      recordSize = (fau.size/2f + recordOffset - fau.mouse).abs * 2f

    if shiftKey.down:
      recordOffset = fau.mouse - fau.size/2f
      color = %"27e67a"

    for entry in [(color: colorBlack, stroke: 8f), (color: color, stroke: 2f)]:
      lineRect(
        recordOffset + fau.size/2f - recordSize/2f,
        recordSize,
        color = entry.color,
        stroke = entry.stroke
      )

    drawFlush()
