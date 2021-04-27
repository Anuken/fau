import fcore, shapes, os, strformat, times, osproc
from pixie import nil

const
  resizeKey = keyLctrl
  openKey = keyE
  recordKey = keyT
  shiftKey = keyLshift

var
  gifTempDir = "build/images"
  gifOutDir = "gifs"
  speedMultiplier* = 1f
  recordFps* = 30
  recordSize* = vec2(300f)
  recordOffset* = vec2(0f)
  saving = false
  recording = false
  open = false
  ftime = 0f
  frames: seq[pixie.Image]

proc record*() =
  if openKey.tapped and not saving:
    if recording:
      frames = @[]
      recording = false
    open = not open

  if open and recordKey.tapped and not saving:
    if not recording:
      frames = @[]
      recording = true
    else:
      recording = false

      gifTempDir.removeDir()
      gifTempDir.createDir()

      #
      for i, img in frames:
        pixie.writeFile(img, gifTempDir / &"{i:05}.png", pixie.ffPng)

      gifOutDir.createDir()
      let dateStr = now().format("yyyy-MM-dd-hh-mm-ss")
      echo execProcess(&"ffmpeg -framerate {recordFps*2} -pattern_type glob -i '{gifTempDir}/*.png' -filter:v \"vflip,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse\" {gifOutDir}/{dateStr}.gif")
      gifTempDir.removeDir()
      frames = @[]
      ftime = 0f

  if recording and open:
    ftime += fau.delta * 60.1f * speedMultiplier
    if ftime >= 60f / recordFps:
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

      var img = pixie.newImage(recordSize.x.int, recordSize.y.int)
      copyMem(addr img.data[0], pixels, img.data.len * 4)
      dealloc pixels
      frames.add img

  if open:
    var color = %"2890eb"

    if recording:
      color = %"f54033"

    drawMat(ortho(0, 0, fau.widthf, fau.heightf))

    if resizeKey.down:
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

