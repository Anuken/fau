import os, strformat, cligen, strutils, tables, sequtils

const nakeTemplate = """
import nake, os, strformat
const
  app = "{{APP_NAME}}"

  builds = [
    #(name: "linux64", os: "linux", cpu: "amd64", args: ""),
    (name: "win32", os: "windows", cpu: "i386", args: "--gcc.exe:i686-w64-mingw32-gcc --gcc.linkerexe:i686-w64-mingw32-g++"),
    #(name: "win64", os: "windows", cpu: "amd64", args: "--gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-g++"),
  ]

task "pack", "Pack textures":
  direshell &"fusepack -p:{getCurrentDir()}/assets-raw/sprites -o:{getCurrentDir()}/assets/atlas"

task "debug", "Debug build":
  runTask("pack")
  shell &"nim r -d:debug {app}"

task "release", "Release build":
  shell &"nim c -r -d:release -d:danger -o:build/{app} {app}"

task "web", "Deploy web build":
  createDir "build/web"
  shell &"nim c -d:emscripten -d:danger {app}.nim"

task "profile", "Run with a profiler":
  shell nimExe, "c", "-r", "-d:release", "-d:danger", "--profiler:on", "--stacktrace:on", "-o:build/" & app, app

task "deploy", "Build for all platforms":
  for name, os, cpu, args in builds.items:
    let
      exeName = &"{app}-{name}"
      dir = "build"
      exeExt = if os == "windows": ".exe" else: ""
      bin = dir / exeName & exeExt
      #win32 crashes when the release flag is specified
      dangerous = if name == "win32": "" else: "-d:danger"

    createDir dir
    direShell &"nim --cpu:{cpu} --os:{os} --app:gui {args} {dangerous} -o:{bin} c {app}"
    direShell &"strip -s {bin}"
    direShell &"upx-ucl --best {bin}"

  createDir "build/web"
  shell &"nim c -d:emscripten -d:danger {app}.nim"

  cd "build"

  direShell(&"zip -9r {app}-web.zip web/*")
"""

const projectPresets = {
  "ecs": """
import core, polymorph

const scl = 4.0

registerComponents(defaultComponentOptions):
  type
    Pos = object
      x, y: float32

makeSystem("logic", [Pos]):

  init:
    discard

  start:
    if keyEscape.tapped: quitApp()
    
    fuse.cam.resize(fuse.widthf / scl, fuse.heightf / scl)
    fuse.cam.use()

    fillPoly(0, 0, 6, 30)
  
  finish:
    discard

makeEcs()
commitSystems("run")
initFuse(run, windowTitle = "{{APP_NAME}}")
""",

  "simple": """
import core

const scl = 4.0

proc init() = 
  discard

proc run() =
  if keyEscape.tapped: quitApp()

  fuse.cam.resize(fuse.widthf / scl, fuse.heightf / scl)
  fuse.cam.use()

  fillPoly(0, 0, 6, 30)

initFuse(run, init, windowTitle = "{{APP_NAME}}")
"""
}.toTable

const cfgTemplate = """
--path:"../fuse"
--gc:arc

if defined(emscripten):

  --passC:"-flto"
  --passL:"-flto"
  --os:linux
  --cpu:i386
  --cc:clang
  --clang.exe:emcc
  --clang.linkerexe:emcc
  --clang.cpp.exe:emcc
  --clang.cpp.linkerexe:emcc
  --listCmd

  --d:danger

  switch("passL", "-o build/web/index.html --shell-file ../fuse/res/shell_minimal.html -O3 -s LLD_REPORT_UNDEFINED -s USE_SDL=2 -s ALLOW_MEMORY_GROWTH=1")
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

proc fuseproject(name: string, directory = getHomeDir() / "Projects", preset = "ecs") =
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

  createDir dir/"assets"
  createDir dir/"assets-raw/sprites"

  createDir dir/".vscode"

  #write a nakefile with basic setup
  writeFile("nakefile.nim", nakeTemplate.replace("{{APP_NAME}}", name))
  writeFile(&"{name.toLowerAscii()}.nim", presetText.replace("{{APP_NAME}}", name))
  writeFile("config.nims", cfgTemplate)
  writeFile(".gitignore", ignoreTemplate)
  writeFile(dir/".vscode/tasks.json", vsTemplate)

  echo &"Project generated in {dir}"

dispatch(fuseproject, help = {
  "name": "name of project",
  "directory": "directory to place project in"
})