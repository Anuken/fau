import nake

const
    exeName = "testing"

task "debug", "Debug build":
    cd "test"
    shell nimExe, "c", "-r", "-d:debug", "-o:../build/" & exeName, exeName
