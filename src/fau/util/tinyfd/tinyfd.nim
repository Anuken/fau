import std/strutils

when defined(Windows):
  {.passL: "-lcomdlg32 -lole32".}

{.compile: "tinyfiledialogs.c".}

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

{.passC: "-I" & currentSourceDir().}

proc tinyfd_saveFileDialog*(title, defaultPathAndFile: cstring, numOfFilterPatterns: cint, filterPatterns: cstringArray, singleFilterDescription: cstring): cstring {.cdecl, header: "tinyfiledialogs.h".}
proc tinyfd_openFileDialog*(title, defaultPathAndFile: cstring, numOfFilterPatterns: cint, filterPatterns: cstringArray, singleFilterDescription: cstring, aAllowMultipleSelects: cint): cstring {.cdecl, header: "tinyfiledialogs.h".}

when defined(Windows):
  
  proc tinyfd_saveFileDialogW*(title, defaultPathAndFile: WideCString, numOfFilterPatterns: cint, filterPatterns: ptr UncheckedArray[WideCString], singleFilterDescription: WideCString): WideCString {.cdecl, header: "tinyfiledialogs.h".}
  proc tinyfd_openFileDialogW*(title, defaultPathAndFile: WideCString, numOfFilterPatterns: cint, filterPatterns: ptr UncheckedArray[WideCString], singleFilterDescription: WideCString, aAllowMultipleSelects: cint): WideCString {.cdecl, header: "tinyfiledialogs.h".}
