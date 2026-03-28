version       = "0.0.1"
author        = "Anuken"
description   = "WIP Nim game framework"
license       = "MIT"
srcDir        = "src"
bin           = @["fau/tools/faupack", "fau/tools/bleed"]
binDir        = "build"

requires "nim >= 2.0.0"
requires "https://github.com/Anuken/staticglfw#e4b204f5cbce497c2681fdd61b5d5f75a88ccb5f"
requires "https://github.com/Anuken/glfm#8f1e2fa5ec6f6a96fc7eeb2bb6727d921a9259c4"
requires "https://github.com/Anuken/nimsoloud#7e23039c4790f36f233733171845bae02044708c"
requires "https://github.com/Anuken/polymorph#170f1b22c1d13828ad9ef84237b9d4d408b77cc6"
requires "https://github.com/Araq/malebolgia#ab17bef08e8e84fabc33e0b039b324438e1ce27b"
requires "cligen >= 1.6.17"
requires "chroma >= 0.2.7"
requires "pixie >= 5.0.6"
requires "vmath >= 2.0.0"
requires "stbimage >= 2.5"
requires "https://www.github.com/Anuken/jsony#cbf96cdffca7eddbfc926c7fc836225b6cd1a2b3"
requires "mimalloc >= 0.3.6"

task imguiGen, "Generate imGUI bindings from source":
  exec("nim r src/fau/tools/imgui_gen.nim")

task imguiTest, "Run imGUI test apppplication":
  exec("nim -d:fauTests -d:debug r src/fau/test/test_imgui.nim")

task entityEditTest, "Run entity edit test apppplication":
  exec("nim -d:fauTests -d:debug r src/fau/test/test_entityedit.nim")