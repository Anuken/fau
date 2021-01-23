import os, strformat, cligen, strutils, tables, sequtils

const nakeTemplate = """
import nake, os, strformat, strutils, sequtils, tables
const
  app = "{{APP_NAME}}"

  builds = [
    #linux builds don't work due to glibc issues. musl doesn't work because of x11 headers, and the glibc hack doesn't work due to depedencies on other C(++) libs
    #workaround: wrap all functions and use asm symver magic to make it work
    #(name: "linux64", os: "linux", cpu: "amd64", args: ""),
    (name: "win32", os: "windows", cpu: "i386", args: "--gcc.exe:i686-w64-mingw32-gcc --gcc.linkerexe:i686-w64-mingw32-g++"),
    (name: "win64", os: "windows", cpu: "amd64", args: "--gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-g++"),
  ]

task "pack", "Pack textures":
  direshell &"faupack -p:{getCurrentDir()}/assets-raw/sprites -o:{getCurrentDir()}/assets/atlas"

task "debug", "Debug build":
  shell &"nim r -f -d:debug {app}"

task "release", "Release build":
  direshell &"nim r -d:release -d:danger -o:build/{app} {app}"

task "web", "Deploy web build":
  createDir "build/web"
  direshell &"nim c -f -d:emscripten -d:danger {app}.nim"
  writeFile("build/web/index.html", readFile("build/web/index.html").replace("$title$", capitalizeAscii(app)))

task "profile", "Run with a profiler":
  shell nimExe, "c", "-r", "-d:release", "-d:danger", "--profiler:on", "--stacktrace:on", "-o:build/" & app, app

task "deploy", "Build for all platforms":
  runTask("web")

  for name, os, cpu, args in builds.items:
    let
      exeName = &"{app}-{name}"
      dir = "build"
      exeExt = if os == "windows": ".exe" else: ""
      bin = dir / exeName & exeExt
      #win32 crashes when the release/danger/optSize flag is specified
      dangerous = if name == "win32": "" else: "-d:danger"

    createDir dir
    direShell &"nim --cpu:{cpu} --os:{os} --app:gui -f {args} {dangerous} -o:{bin} c {app}"
    direShell &"strip -s {bin}"
    direShell &"upx-ucl --best {bin}"

  cd "build"

  direShell(&"zip -9r {app}-web.zip web/*")
"""

const projectPresets = {
  "ecs": """
import ecs, presets/[basic, effects]

static: echo staticExec("faupack -p:assets-raw/sprites -o:assets/atlas")

const scl = 4.0

registerComponents(defaultComponentOptions):
  type
    Vel = object
      x, y: float32

makeSystem("init", [Main]):

  init:
    discard

  start:
    if keyEscape.tapped: quitApp()
    
    fau.cam.resize(fau.widthf / scl, fau.heightf / scl)
    fau.cam.use()

    fillPoly(0, 0, 6, 30)
  
  finish:
    discard

launchFau("{{APP_NAME}}")
""",

  "simple": """
import fcore

static: echo staticExec("faupack -p:../assets-raw/sprites -o:../assets/atlas")

const scl = 4.0

proc init() = 
  discard

proc run() =
  if keyEscape.tapped: quitApp()

  fau.cam.resize(fau.widthf / scl, fau.heightf / scl)
  fau.cam.use()

  fillPoly(0, 0, 6, 30)

initFau(run, init, windowTitle = "{{APP_NAME}}")
"""
}.toTable

const cfgTemplate = """
--path:"fau"
--hints:off
--passC:"-DSTBI_ONLY_PNG"

when not defined(Android):
  --gc:arc

when not defined(debug):
  --passC:"-flto"
  --passL:"-flto"

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
nakefile
repl.nim
"""

const vsTemplate = """
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "debug",
      "type": "shell",
      "command": "nake debug",
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
          nake web
          git checkout gh-pages
          git pull
          rm -rf index*
          cp build/web/* .
          rm -rf build/ assets/ fau/
          git add .
          git commit --allow-empty -m "Updating pages"
          git push https://Anuken:${{ secrets.API_TOKEN_GITHUB }}@github.com/Anuken/{{APP_NAME}}
          
"""

template staticReadString*(filename: string): string = 
  const str = staticRead(filename)
  str

proc fauproject(name: string, directory = getHomeDir() / "Projects", preset = "ecs") =
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
  discard execShellCmd("git clone https://github.com/Anuken/fau.git")
  createDir dir/"assets"
  createDir dir/"assets-raw/sprites"
  createDir dir/".vscode"
  createDir dir/".github/workflows"

  #default sprites
  writeFile(dir/"assets-raw/sprites/circle.png", staticReadString("../res/circle.png"))

  let lowerName = name.toLowerAscii()

  #write a nakefile with basic setup
  writeFile("nakefile.nim", nakeTemplate.replace("{{APP_NAME}}", lowerName))
  writeFile(&"{lowerName}.nim", presetText.replace("{{APP_NAME}}", name))
  writeFile(dir/".github/workflows/build.yml", ciTemplate.replace("{{APP_NAME}}", name))
  writeFile("config.nims", cfgTemplate)
  writeFile(".gitignore", ignoreTemplate)
  writeFile(dir/".vscode/tasks.json", vsTemplate)

  echo &"Project generated in {dir}"

dispatch(fauproject, help = {
  "name": "name of project",
  "directory": "directory to place project in"
})