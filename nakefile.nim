import nake, os, strformat, osproc

const
    app = "testing"
    version = "DEBUG"

    builds = [
        (name: "linux_x86_64", os: "linux", cpu: "amd64", args: ""),
        (name: "win32", os: "windows", cpu: "i386", args: "--gcc.exe:i686-w64-mingw32-gcc --gcc.linkerexe:i686-w64-mingw32-gcc"),
        (name: "win64", os: "windows", cpu: "amd64", args: "--gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc"),
    ]

task "debug", "Debug build":
    cd "test"
    shell nimExe, "c", "-r", "-d:debug", "-o:../build/" & app, app

task "release", "Release build":
    cd "test"
    shell nimExe, "c", "-r", "-d:release", "-d:danger", "-o:../build/" & app, app

task "profile", "Run with a profiler":
    cd "test"
    shell nimExe, "c", "-r", "-d:release", "-d:danger", "--profiler:on", "--stacktrace:on", "-o:../build/" & app, app

task "deploy", "Build for all platforms":
    #removeDir "build"
    cd "test"

    for name, os, cpu, args in builds.items:
        let
            dirName = &"{app}_{version}_{name}"
            dir = "../build" / dirName
            exeExt = if os == "windows": ".exe" else: ""
            bin = dir / app & exeExt
            sdlConfigOps = execProcess("sdl2-config --static-libs")
            sdlOptions = ""#&"--dynlibOverride:SDL2 --passL:\"-static {sdlConfigOps}\""

        echo sdlOptions
        createDir dir
        direShell &"nim --cpu:{cpu} --os:{os} --app:gui {args} -d:release -d:danger -o:{bin} {sdlOptions} c {app}"
        direShell &"strip -s {bin}"
        direShell &"upx-ucl --best {bin}"
        #copyDir("data", dir / "data") #data isn't needed right now
        if os == "windows": copyDir("libs" / name, dir)
        setCurrentDir "../build"
        if os == "windows":
            direShell(fmt"zip -9r {dirName}.zip {dirName}")
        else:
            direShell(fmt"tar cfz {dirName}.tar.gz {dirName}")
        setCurrentDir "../test"
    
