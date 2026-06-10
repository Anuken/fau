#this is required for imgui
--path:"../../../../staticglfw/src"

--d:fauUseSdl

when defined(MacOSX):
  switch("clang.linkerexe", "g++")
else:
  switch("gcc.linkerexe", "g++")

when defined(Windows):
  --l:"-static"

  switch("passL", "-static-libstdc++ -static-libgcc")