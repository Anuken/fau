import ../core, ../util/filedialogs_async

proc run =
  if keyEscape.tapped:
    quitApp()

  if keyS.tapped:
    saveFileDialogAsync(handler = (proc(file: string) = setWindowTitle("Saved: " & file)), title = "Save PNG", patterns = @["*.png"])

  if keyO.tapped:
    if shiftDown():
      openFileDialogMultiAsync(handler = (proc(files: seq[string]) = setWindowTitle("Opened: " & $files)), title = "Open PNG", patterns = @["*.png"])
    else:
      openFileDialogAsync(handler = (proc(file: string) = setWindowTitle("Opened: " & file)), title = "Open PNG", patterns = @["*.png"])

  drawMat(ortho(fau.size))
  fillPoly(fau.size / 2f, 5, 100f, color = colorGreen, rotation = fau.time)
  if keyF11.tapped:
    setFullscreen(not isFullscreen())

proc init =
  echo "init() called"

initFau(run, init, initParams(title = "S for save, O for open"))
