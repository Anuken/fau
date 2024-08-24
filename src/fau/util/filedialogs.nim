import tinyfd/tinyfd

proc saveFileDialog*(title = "Save File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files"): string =
  var patList = patterns
  #does not work properly on macos
  when defined(macosx): patList.insert("", 0)
  
  when defined(Windows):
    var 
      pats: seq[WideCString]
      #needed to delay destruction, otherwise the WideCString gets dealloc'd
      patsdata: seq[WideCStringObj]

    for s in patList:
      patsdata.add s.newWideCString
      pats.add patsdata[^1].toWideCString

    let data = tinyfd_saveFileDialogW(title.newWideCString, defaultPathAndFile.newWideCString, pats.len.cint, addr pats[0], filterDescription.newWideCString)
    result = if data == nil: "" else: $data
  else:
    var pats = allocCStringArray(patList)
    result = $tinyfd_saveFileDialog(title.cstring, defaultPathAndFile.cstring, patList.len.cint, pats, filterDescription.cstring)
    pats.deallocCStringArray

proc openFileDialog*(title = "Open File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files", multiSelect = false): string =
  var patList = patterns
  #does not work properly on macos
  when defined(macosx): patList.insert("", 0)
  
  when defined(Windows):
    var 
      pats: seq[WideCString]
      #needed to delay destruction, otherwise the WideCString gets dealloc'd
      patsdata: seq[WideCStringObj]

    for s in patList:
      patsdata.add s.newWideCString
      pats.add patsdata[^1].toWideCString
    
    let data = tinyfd_openFileDialogW(title.newWideCString, defaultPathAndFile.newWideCString, pats.len.cint, addr pats[0], filterDescription.newWideCString, multiSelect.cint)
    result = if data == nil: "" else: $data
  else:
    var pats = allocCStringArray(patList)
    result = $tinyfd_openFileDialog(title.cstring, defaultPathAndFile.cstring, patList.len.cint, pats, filterDescription.cstring, multiSelect.cint)
    pats.deallocCStringArray

when isMainModule:
  var patterns = @["*.png", "*.msav"]
  echo saveFileDialog(patterns = patterns, filterDescription = "Image/Msav files")
  echo openFileDialog(patterns = patterns, filterDescription = "Image/Msav files")