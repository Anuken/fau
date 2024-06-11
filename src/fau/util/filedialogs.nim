import tinyfd/tinyfd

proc saveFileDialog*(title = "Save File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files"): string =
  var pats = allocCStringArray(patterns)
  
  result = $tinyfd_saveFileDialog(title.cstring, defaultPathAndFile.cstring, patterns.len.cint, pats, filterDescription.cstring)

  pats.deallocCStringArray

proc openFileDialog*(title = "Open File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files", multiSelect = false): string =
  var pats = allocCStringArray(patterns)
  
  result = $tinyfd_openFileDialog(title.cstring, defaultPathAndFile.cstring, patterns.len.cint, pats, filterDescription.cstring, multiSelect.cint)

  pats.deallocCStringArray

when isMainModule:
  var patterns = @["*.png", "*.msav"]
  echo saveFileDialog(patterns = patterns, filterDescription = "Image/Msav files")
  echo openFileDialog(patterns = patterns, filterDescription = "Image/Msav files")