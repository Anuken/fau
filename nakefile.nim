import nake, os, strformat

task "buildPacker", "Build and install the fuse texture packer":
  cd "tools"
  shell &"nim -o:{getHomeDir()}/.nimble/bin/fusepack c -d:danger --gc:arc fusepack.nim"

task "buildTemplate", "Build and install the template tool":
  cd "tools"
  shell &"nim -o:{getHomeDir()}/.nimble/bin/fuseproject c -d:danger --gc:arc fuseproject.nim"