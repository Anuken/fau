import ../../core, ../g2/imgui


var show_demo: bool = true
var somefloat: float32 = 0.0f
var counter: int32 = 0

proc init() =
  let version = igGetVersion()

  echo "ImGUI version: ", version

  igDebugCheckVersionAndDataLayout(version, ImGuiIO.sizeof().uint32,
                                  ImGuiStyle.sizeof().uint32, ImVec2.sizeof().uint32,
                                  ImVec4.sizeof().uint32, ImDrawVert.sizeof().uint32,
                                  ImDrawIdx.sizeof().uint32).assert()
                                  
  imguiInitFau(appName = "imguiTest")

proc run() =
  drawMat(ortho(fau.size))

  fillPoly(fau.size/2f, 3, 100f)
  
  if keyEscape.tapped:
    quitApp()

  if show_demo:
    igShowDemoWindow(show_demo.addr)

  # Simple window
  igBegin("Hello, world!")

  igText("This is some useful text.")
  igCheckbox("Demo Window", show_demo.addr)

  igSliderFloat("float", somefloat.addr, 0.0f, 1.0f)

  if igButton("Button", ImVec2(x: 0, y: 0)):
    counter.inc
  igSameLine()
  igText("counter = %d", counter)

  igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / igGetIO().framerate, igGetIO().framerate)
  igEnd()
  # End simple window

initFau(run, init, initParams())