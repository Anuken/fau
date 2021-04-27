import fcore, shapes, os, strformat, times, osproc, math, streams, strutils

const
  resizeKey = keyLctrl
  openKey = keyE
  recordKey = keyT
  shiftKey = keyLshift

var
  gifOutDir = "gifs"
  speedMultiplier* = 1f
  recordFps* = 25
  recordSize* = vec2(300f)
  recordOffset* = vec2(0f)
  saving = false
  recording = false
  open = false
  ftime = 0f
  frames: seq[pointer]

proc clearFrames() =
  for f in frames:
    f.dealloc
  frames = @[]

proc record*() =
  if openKey.tapped and not saving:
    if recording:
      clearFrames()
      recording = false
    open = not open

  if open and recordKey.tapped and not saving:
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
        len = w * h * 4

      var
        p = startProcess(
          &"ffmpeg -r {recordFps} -s {w}x{h} -f rawvideo -pix_fmt rgba -i - -frames:v {frames.len} -filter:v \"vflip,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse\" {gifOutDir}/{dateStr}.gif",
          options = {poEvalCommand, poStdErrToStdOut}
        )

      var stream = p.inputStream
      for frame in frames:
        stream.writeData(frame, len)
        stream.flush()

      p.close()

      clearFrames()
      ftime = 0f

  if recording and open:
    ftime += fau.delta * 60.1f * speedMultiplier
    if ftime >= 60f / recordFps:
      ftime = ftime.mod 60f / recordFps
      var pixels = readPixels(
        (recordOffset.x + fau.widthf/2f - recordSize.x/2f).int,
        (recordOffset.y + fau.height/2f - recordSize.y/2f).int,
        recordSize.x.int,
        recordSize.y.int
      )

      let len = recordSize.x.int * recordSize.y.int * 4
      var casted = cast[cstring](pixels)

      #set all alpha values to 1 after pixels are grabbed
      for i in countup(3, len, 4):
        casted[i] = 255.char

      frames.add pixels

  if open:
    var color = %"2890eb"

    if recording:
      color = %"f54033"

    drawMat(ortho(0, 0, fau.widthf, fau.heightf))

    if resizeKey.down and not recording:
      color = %"f59827"
      let
        xs = abs(fau.widthf/2f + recordOffset.x - mouse().x)
        ys = abs(fau.heightf/2f + recordOffset.y - mouse().y)
      recordSize = vec2(xs * 2, ys * 2)

    if shiftKey.down:
      recordOffset = -vec2(fau.widthf / 2f - mouse().x, fau.height / 2f - mouse().y)
      color = %"27e67a"

    for entry in [(color: colorBlack, stroke: 8f), (color: color, stroke: 2f)]:
      lineRect(
        recordOffset.x + fau.widthf/2f - recordSize.x/2f,
        recordOffset.y + fau.height/2f - recordSize.y/2f,
        recordSize.x,
        recordSize.y,
        color = entry.color,
        stroke = entry.stroke
      )

    drawFlush()

