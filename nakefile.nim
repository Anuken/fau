import nake

const
    exeName = "testing"

task "debug", "Debug build":
    cd "test"
    shell nimExe, "c", "-r", "-d:debug", "-o:../build/" & exeName, exeName

task "release", "Release build":
    cd "test"
    shell nimExe, "c", "-r", "-d:release", "-d:danger", "-o:../build/" & exeName, exeName

task "profile", "Run with a profiler":
    cd "test"
    shell nimExe, "c", "-r", "-d:release", "-d:danger", "--profiler:on", "--stacktrace:on", "-o:../build/" & exeName, exeName