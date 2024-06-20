version       = "0.0.1"
author        = "Anuken"
description   = "WIP Nim game framework"
license       = "MIT"
srcDir        = "src"
bin           = @["fau/tools/faupack"]
binDir        = "build"

requires "nim >= 2.0.0"
requires "https://github.com/Anuken/staticglfw#c69c02d9429f86bdb448e7727f1175c97404484e"
requires "https://github.com/Anuken/glfm#be73f6862533c4cccedfac512d7766c8a30f3122"
requires "https://github.com/Anuken/nimsoloud#c74878dcb60fd2e2af84f894a8a8ffe901aecd51"
requires "https://github.com/Anuken/polymorph#15bbc5da4223194d27520581e155521e495a9528"
requires "cligen == 1.6.17"
requires "chroma == 0.2.7"
requires "pixie == 5.0.6"
requires "vmath == 2.0.0"
requires "stbimage == 2.5"
requires "https://www.github.com/Anuken/jsony#12d63bbf98fa36734c1ad6b836fae3aa0c1443e5"

task imguiGen, "Generate imGUI bindings from source":
  exec("nim r src/fau/tools/imgui_gen.nim")

task imguiTest, "Run imGUI test apppplication":
  exec("nim -d:fauTests -d:debug r src/fau/test/test_imgui.nim")

task entityEditTest, "Run entity edit test apppplication":
  exec("nim -d:fauTests -d:debug r src/fau/test/test_entityedit.nim")