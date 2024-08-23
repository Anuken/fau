import tinyfd/tinyfd

when defined(Windows):
  import sequtils

proc saveFileDialog*(title = "Save File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files"): string =
  var patList = patterns
  #does not work properly on macos
  when defined(macosx): patList.insert("", 0)
  
  when defined(Windows):
    var pats = patList.mapIt(it.newWideCString)
    result = $tinyfd_saveFileDialogW(title.newWideCString, defaultPathAndFile.newWideCString, pats.len.cint, cast[ptr UncheckedArray[WideCString]](pats[0]), filterDescription.newWideCString)
  else:
    var pats = allocCStringArray(patList)
    result = $tinyfd_saveFileDialog(title.cstring, defaultPathAndFile.cstring, patList.len.cint, pats, filterDescription.cstring)
    pats.deallocCStringArray

proc openFileDialog*(title = "Open File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files", multiSelect = false): string =
  var patList = patterns
  #does not work properly on macos
  when defined(macosx): patList.insert("", 0)
  
  when defined(Windows):
    var pats = patList.mapIt(it.newWideCString)
    result = $tinyfd_openFileDialogW(title.newWideCString, defaultPathAndFile.newWideCString, pats.len.cint, cast[ptr UncheckedArray[WideCString]](pats[0]), filterDescription.newWideCString, multiSelect.cint)
  else:
    var pats = allocCStringArray(patList)
    result = $tinyfd_openFileDialog(title.cstring, defaultPathAndFile.cstring, patList.len.cint, pats, filterDescription.cstring, multiSelect.cint)
    pats.deallocCStringArray

when isMainModule:
  var patterns = @["*.png", "*.msav"]
  echo saveFileDialog(patterns = patterns, filterDescription = "Image/Msav files")
  echo openFileDialog(patterns = patterns, filterDescription = "Image/Msav files")