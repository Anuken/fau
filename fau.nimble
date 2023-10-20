version       = "0.0.1"
author        = "Anuken"
description   = "WIP Nim game framework"
license       = "MIT"
srcDir        = "src"
bin           = @["fau/tools/faupack"] #, "fau/tools/antialias", "fau/tools/fauproject", "fau/tools/bleed"]
binDir        = "build"

requires "nim >= 1.4.8"
requires "https://github.com/Anuken/staticglfw#f354b058fe644944ea1d9fd8acd776f65541ca74"
requires "https://github.com/Anuken/glfm#be73f6862533c4cccedfac512d7766c8a30f3122"
requires "https://github.com/Anuken/nimsoloud#c74878dcb60fd2e2af84f894a8a8ffe901aecd51"
requires "polymorph >= 0.3.1"
requires "cligen >= 1.6.1"
requires "chroma >= 0.2.7"
requires "pixie >= 5.0.6"
requires "vmath >= 1.1.4"
requires "stbimage >= 2.5"
requires "jsony >= 1.1.5"