import filedialogs, ../async

## This module has async wrappers for file dialogs - when you don't want to freeze the whole window to open something.

type FileDialogParams = tuple[title: string, defaultPathAndFile: string, patterns: seq[string], filterDescription: string]

#wrapper that accepts a params object
proc saveFileDialogParams(params: FileDialogParams): string = saveFileDialog(params.title, params.defaultPathAndFile, params.patterns, params.filterDescription)

proc saveFileDialogAsync*(handler: proc(path: string), title = "Save File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files") =
  runAsync((title, defaultPathAndFile, patterns, filterDescription), saveFileDialogParams) do(path: string):
    if path != "":
      handler(path)

#wrapper that accepts a params object
proc openFileDialogParams(params: FileDialogParams): string = openFileDialog(params.title, params.defaultPathAndFile, params.patterns, params.filterDescription)

proc openFileDialogMultiParams(params: FileDialogParams): seq[string] = openFileDialogMulti(params.title, params.defaultPathAndFile, params.patterns, params.filterDescription)

proc openFileDialogAsync*(handler: proc(path: string), title = "Save File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files") =
  runAsync((title, defaultPathAndFile, patterns, filterDescription), openFileDialogParams) do(path: string):
    if path != "":
      handler(path)

proc openFileDialogMultiAsync*(handler: proc(paths: seq[string]), title = "Save File", defaultPathAndFile = "", patterns: seq[string] = @["*.*"], filterDescription = "All Files") =
  runAsync((title, defaultPathAndFile, patterns, filterDescription), openFileDialogMultiParams) do(paths: seq[string]):
    if paths.len > 0:
      handler(paths)