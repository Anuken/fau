import ../../core

proc run =
  if keyEscape.tapped:
    quitApp()

  if fau.frameId mod 10 == 0:
    setWindowTitle($fau.fps & " FPS")

  drawMat(ortho(fau.size))
  fillPoly(fau.size / 2f, 5, 100f, color = colorGreen, rotation = fau.time)
  if keyF11.tapped:
    setFullscreen(not isFullscreen())

proc init =
  echo "init() called"

initFau(run, init, initParams(title = "Tiled Test"))
