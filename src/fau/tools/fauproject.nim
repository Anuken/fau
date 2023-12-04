import os, strformat, cligen, strutils, tables, sequtils

const projectPresets = {
  "ecs": """
import ecs, fau/presets/[basic, effects]

static: echo staticExec("faupack -p:../assets-raw/sprites -o:../assets/atlas")

const scl = 4.0

registerComponents(defaultComponentOptions):
  type
    Vel = object
      x, y: float32

sys("init", [Main]):

  init:
    discard

  start:
    if keyEscape.tapped: quitApp()
    
    fau.cam.update(fau.size / scl)
    fau.cam.use()

    fillPoly(vec2(0, 0), 6, 30)
  
  finish:
    discard

makeEcsCommit("run")
 initFau(run, params = initParams(name = "{{APP_NAME}}"))
""",

  "simple": """
import fcore

static: echo staticExec("faupack -p:assets-raw/sprites -o:assets/atlas")

const scl = 4.0

proc init() = 
  discard

proc run() =
  if keyEscape.tapped: quitApp()

  fau.cam.resize(fau.widthf / scl, fau.heightf / scl)
  fau.cam.use()

  fillPoly(0, 0, 6, 30)

initFau(run, init, params = initParams(name = "{{APP_NAME}}"))
"""
}.toTable

const cfgTemplate = """
--path:"fau/src"
--hints:off
--passC:"-DSTBI_ONLY_PNG"
--gc:arc
--d:nimPreviewHashRef
--tlsEmulation:off

when defined(release) or defined(danger):
  --passC:"-flto"
  --passL:"-flto"
  --d:strip
else:
  --d:localAssets

when defined(Android):
  --d:androidNDK

if defined(emscripten):
  --os:linux
  --cpu:i386
  --cc:clang
  --clang.exe:emcc
  --clang.linkerexe:emcc
  --clang.cpp.exe:emcc
  --clang.cpp.linkerexe:emcc
  --listCmd

  --d:danger

  switch("passL", "-o build/web/index.html --shell-file fau/res/shell_minimal.html -O3 -s LLD_REPORT_UNDEFINED -s USE_SDL=2 -s ALLOW_MEMORY_GROWTH=1 --closure 1 --preload-file assets")
else:

  when defined(Windows):
    switch("passL", "-static-libstdc++ -static-libgcc")

  when defined(MacOSX):
    switch("clang.linkerexe", "g++")
  else:
    switch("gcc.linkerexe", "g++")
"""

const ignoreTemplate = """
build
repl.nim
assets/atlas.png
assets/atlas.dat
.idea
gifs/
"""

const vsTemplate = """
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "debug",
      "type": "shell",
      "command": "nimble debug",
      "problemMatcher": [],
      "group": {
        "kind": "build",
        "isDefault": true
      }
    }
  ]
}
"""

const ciTemplate = """
name: CI

on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2
        with:
          submodules: true
      - uses: jiro4989/setup-nim-action@v1
        with:
          nim-version: 'stable'
      - name: Install packages needed for GLFW
        run: |
          sudo apt install -y xorg-dev libgl1-mesa-dev
      - name: Build {{APP_NAME}}
        run: |
          nimble build -Y
      - name: Setup Emscripten
        uses: mymindstorm/setup-emsdk@v7
      - name: Verify Emscripten is installed
        run: emcc -v
      - name: Build web version
        run: |
          git config --global user.email "cli@github.com"
          git config --global user.name "Github Actions"
          git clone --recursive https://github.com/Anuken/{{APP_NAME}}.git
          cd {{APP_NAME}}
          nimble web
          git checkout gh-pages
          git pull
          rm -rf index*
          cp build/web/* .
          rm -rf build/ assets/ fau/
          git add .
          git commit --allow-empty -m "Updating pages"
          git push https://Anuken:${{ secrets.API_TOKEN_GITHUB }}@github.com/Anuken/{{APP_NAME}}
          
"""

const nimbleTemplate = """
version       = "0.0.1"
author        = "Anuken"
description   = "none"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["{{APP_NAME}}"]
binDir        = "build"

requires "nim >= 1.6.2"
requires "https://github.com/Anuken/fau#" & staticExec("git -C fau rev-parse HEAD")

import strformat, os

template shell(args: string) =
  try: exec(args)
  except OSError: quit(1)

const
  app = "{{APP_NAME}}"

  builds = [
    #(name: "linux64", os: "linux", cpu: "amd64", args: ""), #doesn't work due to glibc
    (name: "win64", os: "windows", cpu: "amd64", args: "--gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-g++"),
  ]

task pack, "Pack textures":
  shell &"faupack -p:\"{getCurrentDir()}/assets-raw/sprites\" -o:\"{getCurrentDir()}/assets/atlas\""

task debug, "Debug build":
  shell &"nim r -d:debug src/{app}"

task release, "Release build":
  shell &"nim r -d:release -d:danger -o:build/{app} src/{app}"

task web, "Deploy web build":
  mkDir "build/web"
  shell &"nim c -f -d:emscripten -d:danger src/{app}.nim"
  writeFile("build/web/index.html", readFile("build/web/index.html").replace("$title$", capitalizeAscii(app)))

task deploy, "Build for all platforms":
  webTask()

  for name, os, cpu, args in builds.items:
    let
      exeName = &"{app}-{name}"
      dir = "build"
      exeExt = if os == "windows": ".exe" else: ""
      bin = dir / exeName & exeExt

    mkDir dir
    shell &"nim --cpu:{cpu} --os:{os} --app:gui -f {args} -d:danger -o:{bin} c src/{app}"
    shell &"strip -s {bin}"
    shell &"upx-ucl --best {bin}"

  cd "build"
  shell &"zip -9r {app}-web.zip web/*"

"""

template assetReadStatic*(filename: string): string = 
  const str = staticRead(filename)
  str

proc fauproject(directory = getHomeDir() / "Projects", preset = "ecs", names: seq[string]) =
  if names.len != 1:
    echo "One project name must be provided."
    return

  let name = names[0]

  if name.len == 0:
    echo "Project name must not be empty."
    return

  echo &"Generating project '{name}'..."

  let dir = directory / name

  if dir.dirExists:
    echo &"Directory {dir} already exists. Exiting."
    return

  if not projectPresets.hasKey(preset):
    let choices = toSeq(projectPresets.keys).join(", ")
    echo &"Invalid preset: '{preset}'. Choices: {choices}"
    return

  let presetText = projectPresets[preset]
  
  createDir dir
  setCurrentDir dir

  #pull in latest fau version
  #TODO git submodule add https://github.com/Anuken/fau.git fau
  discard execShellCmd("git clone https://github.com/Anuken/fau.git")
  createDir dir/"assets"
  createDir dir/"src"
  createDir dir/"assets-raw/sprites"
  createDir dir/".vscode"
  createDir dir/".github/workflows"

  #default sprites
  writeFile(dir/"assets-raw/sprites/circle.png", assetReadStatic("../../../res/circle.png"))

  let lowerName = name.toLowerAscii()

  writeFile(&"src/{lowerName}.nim", presetText.replace("{{APP_NAME}}", name))
  writeFile(dir/".github/workflows/build.yml", ciTemplate.replace("{{APP_NAME}}", name))
  writeFile(&"{lowerName}.nimble", nimbleTemplate.replace("{{APP_NAME}}", name))
  writeFile("config.nims", cfgTemplate)
  writeFile(".gitignore", ignoreTemplate)
  writeFile(dir/".vscode/tasks.json", vsTemplate)

  echo &"Project generated in {dir}"

dispatch(fauproject, help = {
  "directory": "directory to place project in"
})