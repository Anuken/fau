#this is required for imgui
--path:"../../../../staticglfw/src"

#pass this on the commandline if you need SDL
#--d:fauUseSdl

when defined(MacOSX):
  switch("clang.linkerexe", "g++")
else:
  switch("gcc.linkerexe", "g++")

when defined(Windows):
  --l:"-static"

  switch("passL", "-static-libstdc++ -static-libgcc")