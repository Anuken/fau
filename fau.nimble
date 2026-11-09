version       = "0.0.1"
author        = "Anuken"
description   = "WIP Nim game framework (revived fork)"
license       = "MIT"
srcDir        = "src"
bin           = @["fau/tools/faupack"]
binDir        = "build"

requires "nim >= 2.2.0"
requires "https://github.com/Anuken/staticglfw#master"
requires "https://github.com/Anuken/glfm#master"
requires "https://github.com/Anuken/nimsoloud#master"
requires "https://github.com/Anuken/polymorph#master"
requires "cligen >= 1.6.17"
requires "chroma >= 0.2.7"
requires "pixie >= 5.0.6"
requires "vmath >= 2.0.0"
requires "stbimage >= 2.5"
requires "https://www.github.com/Anuken/jsony#master"

task imguiGen, "Generate imGUI bindings from source":
  exec("nim r src/fau/tools/imgui_gen.nim")

task imguiTest, "Run imGUI test apppplication":
  exec("nim -d:fauTests -d:debug r src/fau/test/test_imgui.nim")

task entityEditTest, "Run entity edit test apppplication":
  exec("nim -d:fauTests -d:debug r src/fau/test/test_entityedit.nim")