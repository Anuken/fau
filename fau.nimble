version       = "0.0.1"
author        = "Anuken"
description   = "WIP Nim game framework"
license       = "MIT"
srcDir        = "src"
bin           = @["fau/tools/faupack", "fau/tools/bleed"]
binDir        = "build"

requires "nim >= 2.0.0"
requires "https://github.com/Anuken/staticglfw#9fa998cae81a5c795063e0c4e2476747d0257cd3"
requires "https://github.com/Anuken/glfm#eac00f1d5df3b9f72d8bc00b8cb16190b0638dff"
requires "https://github.com/Anuken/nimsoloud#c74878dcb60fd2e2af84f894a8a8ffe901aecd51"
requires "https://github.com/Anuken/polymorph#170f1b22c1d13828ad9ef84237b9d4d408b77cc6"
requires "https://github.com/Araq/malebolgia#ab17bef08e8e84fabc33e0b039b324438e1ce27b"
requires "cligen >= 1.6.17"
requires "chroma >= 0.2.7"
requires "pixie >= 5.0.6"
requires "vmath >= 2.0.0"
requires "stbimage >= 2.5"
requires "https://www.github.com/Anuken/jsony#d4d368b0d8c6f1db0f842f73bbe31f42855a9375"
requires "mimalloc >= 0.3.6"

task imguiGen, "Generate imGUI bindings from source":
  exec("nim r src/fau/tools/imgui_gen.nim")

task imguiTest, "Run imGUI test apppplication":
  exec("nim -d:fauTests -d:debug r src/fau/test/test_imgui.nim")

task entityEditTest, "Run entity edit test apppplication":
  exec("nim -d:fauTests -d:debug r src/fau/test/test_entityedit.nim")