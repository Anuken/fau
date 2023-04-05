import ../draw, ../globals, ../fmath, ../screenbuffer, ../color, os, strformat, times, osproc, math, streams, strutils
from pixie import Image, newImage, writeFile, flipVertical

export Image, newImage, writeFile, flipVertical
export os


## Tiny utility functions for saving a gif animation. Require ffmpeg.

const useGifPalette = defined(useGifPalette)

proc addGifFrame*(frames: var seq[pointer], bounds: Rect): pointer {.discardable.} =
  drawFlush()
  result = screen.read(
    bounds.xy.vec2i,
    bounds.size.vec2i
  )
  frames.add(result)

proc finishGif*(frames: seq[pointer], path: string, bounds: Rect, fps = 30) =
  let
    w = bounds.w.int
    h = bounds.h.int
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

template makeAnimation*(frameCount: int, fps: int, bounds: Rect, path: string, prefix: string, background = colorClear, body: untyped) =
  ## Compiles a gif with the specified amount of frames into a file. 
  ## Body should draw each frame. i is injected as the frame index.
  ## Screen is automatically cleared.

  discard path.existsOrCreateDir()

  var frames: seq[pointer]

  for i {.inject.} in 0..<frameCount:
    let fin {.inject, used.} = i.float32 / (frameCount.float32)
    screen.clear(background)
    body

    let 
      rawData = addGifFrame(frames, bounds)
      img = newImage(bounds.w.int, bounds.h.int)
    copyMem(addr img.data[0], rawData, img.data.len * 4)
    img.flipVertical()
    img.writeFile(path / prefix & $i & ".png")
  
  finishGif(frames, path / prefix & "out.gif", bounds, fps)


template makeGifBase*(frameCount: int, fps: int, bounds: Rect, path: string, background = colorClear, pingPong = false, body: untyped) =
  ## Compiles a gif with the specified amount of frames into a file. 
  ## Body should draw each frame. i is injected as the frame index.
  ## Screen is automatically cleared.

  var frames: seq[pointer]

  for i {.inject.} in 0..<frameCount:
    let fin {.inject, used.} = i.float32 / (frameCount.float32)
    screen.clear(background)
    body
    addGifFrame(frames.bounds)
  
  if pingPong:
    let top = frames.high

    for i {.inject.} in countdown(top - 1, 0):
      frames.add frames[i]
  
  finishGif(frames, path, bounds, fps)

template makeGif*(frames: int, fps: int, bounds: Rect, path: string, background = colorClear, body: untyped) =
  makeGifBase(frames, fps, bounds, path, background, false, body)

template makeGifPong*(frames: int, fps: int, bounds: Rect, path: string, background = colorClear, body: untyped) =
  makeGifBase(frames, fps, bounds, path, background, true, body)