import ../draw, ../globals, ../fmath, ../screenbuffer, ../color, os, strformat, times, osproc, math, streams, strutils

## Tiny utility functions for saving a gif animation. Require ffmpeg.

var 
  frames: seq[pointer]
  gifSize: Rect
  useGifPalette* = true


proc addGifFrame*(bounds: Rect) =
  gifSize = bounds
  drawFlush()
  frames.add screen.read(
    bounds.xy.vec2i,
    bounds.size.vec2i
  )

proc finishGif*(path: string, fps = 30) =
  let
    w = gifSize.w.int
    h = gifSize.h.int
    len = w * h * 4
    filters = if not useGifPalette: "" else: ",split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
  
  if fileExists(path):
    removeFile(path)

  var
    p = startProcess(
      &"ffmpeg -r {fps} -s {w}x{h} -f rawvideo -pix_fmt rgba -i - -frames:v {frames.len} -filter:v \"vflip{filters}\" {path}",
      options = {poEvalCommand, poStdErrToStdOut}
    )
    stream = p.inputStream

  for frame in frames:
    stream.writeData(frame, len)
    stream.flush()

  stream.close()
  discard p.waitForExit()

  for f in frames:
    f.dealloc
  frames.setLen(0)

template makeGifBase*(frameCount: int, fps: int, bounds: Rect, path: string, background = colorClear, pingPong = false, body: untyped) =
  ## Compiles a gif with the specified amount of frames into a file. 
  ## Body should draw each frame. i is injected as the frame index.
  ## Screen is automatically cleared.

  for i {.inject.} in 0..<frameCount:
    let fin {.inject, used.} = i.float32 / (frameCount.float32)
    screen.clear(background)
    body
    addGifFrame(bounds)
  
  if pingPong:
    let top = frames.high

    for i {.inject.} in countdown(top - 1, 0):
      frames.add frames[i]
  
  finishGif(path, fps)

template makeGif*(frames: int, fps: int, bounds: Rect, path: string, background = colorClear, body: untyped) =
  makeGifBase(frames, fps, bounds, path, background, false, body)

template makeGifPong*(frames: int, fps: int, bounds: Rect, path: string, background = colorClear, body: untyped) =
  makeGifBase(frames, fps, bounds, path, background, true, body)