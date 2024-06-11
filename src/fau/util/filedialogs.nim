import tinyfd/tinyfd

proc saveFileDialog*(title = "Save File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files"): string =
  var patternArr = newSeqOfCap[cstring](patterns.len)
  for i in 0..<patterns.len:
    patternArr[i] = patterns[i].cstring
  
  return $tinyfd_saveFileDialog(title.cstring, defaultPathAndFile.cstring, patterns.len.cint, cast[ptr UncheckedArray[cstring]](patternArr[0].addr), filterDescription.cstring)

proc openFileDialog*(title = "Open File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files", multiSelect = false): string =
  var patternArr = newSeqOfCap[cstring](patterns.len)
  for i in 0..<patterns.len:
    patternArr[i] = patterns[i].cstring
  
  return $tinyfd_openFileDialog(title.cstring, defaultPathAndFile.cstring, patterns.len.cint, cast[ptr UncheckedArray[cstring]](patternArr[0].addr), filterDescription.cstring, multiSelect.cint)

when isMainModule:
  var patterns = @["*.png", "*.msav"]
  echo saveFileDialog(patterns = patterns, filterDescription = "Image/Msav files")
  echo openFileDialog(patterns = patterns, filterDescription = "Image/Msav files")