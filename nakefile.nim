import nake, os, strformat

task "buildPacker", "Build and install the fuse texture packer":
  cd "tools"
  shell &"nim -o:{getHomeDir()}/.nimble/bin/fusepack c -d:danger --gc:arc fusepack.nim"
