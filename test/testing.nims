--path:"../src"

if defined(emscripten):
  # This path will only run if -d:emscripten is passed to nim.

  --passC:"-flto"
  --passL:"-flto"
  --os:linux # Emscripten pretends to be linux.
  --cpu:i386 # Emscripten is 32bits.
  --cc:clang # Emscripten is very close to clang, so we ill replace it.
  --clang.exe:emcc  # Replace C
  --clang.linkerexe:emcc # Replace C linker
  --clang.cpp.exe:emcc # Replace C++
  --clang.cpp.linkerexe:emcc # Replace C++ linker.
  --listCmd # List what commands we are running so that we can debug them.

  --gc:arc # GC:arc is friendlier with crazy platforms.
  --d:danger

  # Pass this to Emscripten linker to generate html file scaffold for us.
  switch("passL", "-o ../build/web/index.html --shell-file shell_minimal.html -O3 -s LLD_REPORT_UNDEFINED -s USE_SDL=2 -s ALLOW_MEMORY_GROWTH=1")
else:
  --gc:arc

  when defined(Windows):
    switch("passL", "-static-libstdc++ -static-libgcc")

  when defined(MacOSX):
    switch("clang.linkerexe", "g++")
  else:
    switch("gcc.linkerexe", "g++")
