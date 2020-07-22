import nake, os, strformat

task "buildPacker", "Build and install the fuse texture packer":
  cd "tools"
  shell &"nim -o:{getHomeDir()}/.nimble/bin/fusepack c -d:danger --gc:arc fusepack.nim"

task "buildProject", "Build and install the project template tool":
  cd "tools"
  shell &"nim -o:{getHomeDir()}/.nimble/bin/fuseproject c -d:danger --gc:arc fuseproject.nim"

task "buildAntialias", "Build and install the antialias tool":
  cd "tools"
  shell &"nim -o:{getHomeDir()}/.nimble/bin/antialias c -d:danger --gc:arc antialias.nim"