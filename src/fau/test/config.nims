#this is required for imgui

when defined(MacOSX):
  switch("clang.linkerexe", "g++")
else:
  switch("gcc.linkerexe", "g++")

when defined(Windows):
  --l:"-static"

  switch("passL", "-static-libstdc++ -static-libgcc")