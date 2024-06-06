# Taken from: https://github.com/nimgl/imgui
# Originally written by Leonardo Mariscal <leo@ldmd.mx>, 2019

import strutils, json, strformat, tables,
       algorithm, sets, re, os

const srcHeader = """

## Originally Written by Leonardo Mariscal <leo@ldmd.mx>, 2019
## 
## Updated to ImGUI 1.90.7 with the help of code from <https://github.com/nimgl/imgui/pull/10>
## 
## ImGUI Bindings
## ====
## WARNING: This is a generated file. Do not edit.
## Any edits will be overwritten by the generator.
##
## The aim is to achieve as much compatibility with C as possible.
##
## You can check the original documentation `here <https://github.com/ocornut/imgui/blob/master/imgui.cpp>`_.
##

import std/[compilesettings, strformat, strutils, os]

## Tentative workaround [start]
type
  uint32Ptr* = ptr uint32
  ImguiDockRequest* = distinct object
  ImGuiDockNodeSettings* = distinct object
  const_cstringPtr* {.pure, inheritable, bycopy.} = object
    Size*: cint
    Capacity*: cint
    Data*: ptr ptr cschar

## Tentative workaround [end]

const
  nimcache = querySetting(SingleValueSetting.nimcacheDir)

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

{.passC: "-I" & currentSourceDir() & "/cimgui" & " -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1".}

template compileCpp(file: string, name: string) =
  const objectPath = nimcache & "/" & name & "_" & hostOs & hostCPU & ".cpp.o"

  static:
    if not fileExists(objectPath):
      createDir(objectPath.parentDir.replace("\\", "/"))

      #TODO this is awful and hardcoded and I hate it

      const compilerName = when defined(Windows): "x86_64-w64-mingw32-g++" else: "g++"

      echo "Compiling... ", name
      echo staticExec(compilerName & " -std=c++14 -c -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 cimgui/" & file & " -o " & objectPath)

  {.passL: objectPath.}

compileCpp("cimgui.cpp", "cimgui.cpp")
compileCpp("imgui/imgui.cpp", "imgui.cpp")
compileCpp("imgui/imgui_draw.cpp", "imgui_draw.cpp")
compileCpp("imgui/imgui_tables.cpp", "imgui_tables.cpp")
compileCpp("imgui/imgui_widgets.cpp", "imgui_widgets.cpp")
compileCpp("imgui/imgui_demo.cpp", "imgui_demo.cpp")

{.passc: "-DCIMGUI_DEFINE_ENUMS_AND_STRUCTS".}
{.pragma: imgui_header, header: "cimgui.h".}
"""

const notDefinedStructs = """
  ImVector*[T] = object # Should I importc a generic?
    size* {.importc: "Size".}: int32
    capacity* {.importc: "Capacity".}: int32
    data* {.importc: "Data".}: ptr UncheckedArray[T]
  ImGuiStyleModBackup* {.union.} = object
    backup_int* {.importc: "BackupInt".}: int32 # Breaking naming convetion to denote "low level"
    backup_float* {.importc: "BackupFloat".}: float32
  ImGuiStyleMod* {.importc: "ImGuiStyleMod", imgui_header.} = object
    varIdx* {.importc: "VarIdx".}: ImGuiStyleVar
    backup*: ImGuiStyleModBackup
  ImGuiStoragePairData* {.union.} = object
    val_i* {.importc: "val_i".}: int32 # Breaking naming convetion to denote "low level"
    val_f* {.importc: "val_f".}: float32
    val_p* {.importc: "val_p".}: pointer
  ImGuiStoragePair* {.importc: "ImGuiStoragePair", imgui_header.} = object
    key* {.importc: "key".}: ImGuiID
    data*: ImGuiStoragePairData
  ImPairData* {.union.} = object
    val_i* {.importc: "val_i".}: int32 # Breaking naming convetion to denote "low level"
    val_f* {.importc: "val_f".}: float32
    val_p* {.importc: "val_p".}: pointer
  ImPair* {.importc: "Pair", imgui_header.} = object
    key* {.importc: "key".}: ImGuiID
    data*: ImPairData
  ImGuiInputEventData* {.union.} = object
    mousePos*: ImGuiInputEventMousePos
    mouseWheel*: ImGuiInputEventMouseWheel
    mouseButton*: ImGuiInputEventMouseButton
    key*: ImGuiInputEventKey
    text*: ImGuiInputEventText
    appFocused*: ImGuiInputEventAppFocused
  ImGuiInputEvent* {.importc: "ImGuiInputEvent", imgui_header.} = object
    `type`* {.importc: "`type`".}: ImGuiInputEventType
    source* {.importc: "Source".}: ImGuiInputSource
    data*: ImGuiInputEventData
    addedByTestEngine* {.importc: "AddedByTestEngine".}: bool

  # Undefined data types in cimgui

  ImDrawListPtr* = object
  ImChunkStream* = ptr object
  ImPool* = object
  ImSpanAllocator* = object # A little lost here. It is referenced in imgui_internal.h
  ImSpan* = object # ^^
  ImVectorImGuiColumns* {.importc: "ImVector_ImGuiColumns".} = object

  #
"""

const preProcs = """
# Procs
{.push warning[HoleEnumConv]: off.}
{.push nodecl, discardable,header: currentSourceDir() & "/cimgui/cimgui.h".}
"""

const postProcs = """
{.pop.} # push dynlib / nodecl, etc...
{.pop.} # push warning[HoleEnumConv]: off
"""

let reservedWordsDictionary = [
"end", "type", "out", "in", "ptr", "ref"
]

let blackListProc = [ "" ]

const cherryTheme = """
proc igStyleColorsCherry*(dst: ptr ImGuiStyle = nil): void =
  ## To conmemorate this bindings this style is included as a default.
  ## Style created originally by r-lyeh
  var style = igGetStyle()
  if dst != nil:
    style = dst

  const ImVec4 = proc(x: float32, y: float32, z: float32, w: float32): ImVec4 = ImVec4(x: x, y: y, z: z, w: w)
  const igHI = proc(v: float32): ImVec4 = ImVec4(0.502f, 0.075f, 0.256f, v)
  const igMED = proc(v: float32): ImVec4 = ImVec4(0.455f, 0.198f, 0.301f, v)
  const igLOW = proc(v: float32): ImVec4 = ImVec4(0.232f, 0.201f, 0.271f, v)
  const igBG = proc(v: float32): ImVec4 = ImVec4(0.200f, 0.220f, 0.270f, v)
  const igTEXT = proc(v: float32): ImVec4 = ImVec4(0.860f, 0.930f, 0.890f, v)

  style.colors[ImGuiCol.Text.int32]                 = igTEXT(0.88f)
  style.colors[ImGuiCol.TextDisabled.int32]         = igTEXT(0.28f)
  style.colors[ImGuiCol.WindowBg.int32]             = ImVec4(0.13f, 0.14f, 0.17f, 1.00f)
  style.colors[ImGuiCol.PopupBg.int32]              = igBG(0.9f)
  style.colors[ImGuiCol.Border.int32]               = ImVec4(0.31f, 0.31f, 1.00f, 0.00f)
  style.colors[ImGuiCol.BorderShadow.int32]         = ImVec4(0.00f, 0.00f, 0.00f, 0.00f)
  style.colors[ImGuiCol.FrameBg.int32]              = igBG(1.00f)
  style.colors[ImGuiCol.FrameBgHovered.int32]       = igMED(0.78f)
  style.colors[ImGuiCol.FrameBgActive.int32]        = igMED(1.00f)
  style.colors[ImGuiCol.TitleBg.int32]              = igLOW(1.00f)
  style.colors[ImGuiCol.TitleBgActive.int32]        = igHI(1.00f)
  style.colors[ImGuiCol.TitleBgCollapsed.int32]     = igBG(0.75f)
  style.colors[ImGuiCol.MenuBarBg.int32]            = igBG(0.47f)
  style.colors[ImGuiCol.ScrollbarBg.int32]          = igBG(1.00f)
  style.colors[ImGuiCol.ScrollbarGrab.int32]        = ImVec4(0.09f, 0.15f, 0.16f, 1.00f)
  style.colors[ImGuiCol.ScrollbarGrabHovered.int32] = igMED(0.78f)
  style.colors[ImGuiCol.ScrollbarGrabActive.int32]  = igMED(1.00f)
  style.colors[ImGuiCol.CheckMark.int32]            = ImVec4(0.71f, 0.22f, 0.27f, 1.00f)
  style.colors[ImGuiCol.SliderGrab.int32]           = ImVec4(0.47f, 0.77f, 0.83f, 0.14f)
  style.colors[ImGuiCol.SliderGrabActive.int32]     = ImVec4(0.71f, 0.22f, 0.27f, 1.00f)
  style.colors[ImGuiCol.Button.int32]               = ImVec4(0.47f, 0.77f, 0.83f, 0.14f)
  style.colors[ImGuiCol.ButtonHovered.int32]        = igMED(0.86f)
  style.colors[ImGuiCol.ButtonActive.int32]         = igMED(1.00f)
  style.colors[ImGuiCol.Header.int32]               = igMED(0.76f)
  style.colors[ImGuiCol.HeaderHovered.int32]        = igMED(0.86f)
  style.colors[ImGuiCol.HeaderActive.int32]         = igHI(1.00f)
  style.colors[ImGuiCol.ResizeGrip.int32]           = ImVec4(0.47f, 0.77f, 0.83f, 0.04f)
  style.colors[ImGuiCol.ResizeGripHovered.int32]    = igMED(0.78f)
  style.colors[ImGuiCol.ResizeGripActive.int32]     = igMED(1.00f)
  style.colors[ImGuiCol.PlotLines.int32]            = igTEXT(0.63f)
  style.colors[ImGuiCol.PlotLinesHovered.int32]     = igMED(1.00f)
  style.colors[ImGuiCol.PlotHistogram.int32]        = igTEXT(0.63f)
  style.colors[ImGuiCol.PlotHistogramHovered.int32] = igMED(1.00f)
  style.colors[ImGuiCol.TextSelectedBg.int32]       = igMED(0.43f)

  style.windowPadding     = ImVec2(x: 6f, y: 4f)
  style.windowRounding    = 0.0f
  style.framePadding      = ImVec2(x: 5f, y: 2f)
  style.frameRounding     = 3.0f
  style.itemSpacing       = ImVec2(x: 7f, y: 1f)
  style.itemInnerSpacing  = ImVec2(x: 1f, y: 1f)
  style.touchExtraPadding = ImVec2(x: 0f, y: 0f)
  style.indentSpacing     = 6.0f
  style.scrollbarSize     = 12.0f
  style.scrollbarRounding = 16.0f
  style.grabMinSize       = 20.0f
  style.grabRounding      = 2.0f

  style.windowTitleAlign.x = 0.50f

  style.colors[ImGuiCol.Border.int32] = ImVec4(0.539f, 0.479f, 0.255f, 0.162f)
  style.frameBorderSize  = 0.0f
  style.windowBorderSize = 1.0f

  style.displaySafeAreaPadding.y = 0
  style.framePadding.y = 1
  style.itemSpacing.y = 1
  style.windowPadding.y = 3
  style.scrollbarSize = 13
  style.frameBorderSize = 1
  style.tabBorderSize = 1
"""

var enums: HashSet[string]
var enumsCount: Table[string, int]

const rootDir = currentSourcePath().parentDir() / "../imgui"

proc translateType(name: string): string # translateProc needs this

proc uncapitalize(str: string): string =
  if str.len < 1:
    result = ""
  else:
    result = toLowerAscii(str[0]) & str[1 ..< str.len]

proc isUpper(str: string): bool =
  for c in str:
    if not c.isUpperAscii():
      return false
  return true

proc translateProc(name: string): string =
  var nameSplit = name.replace(";", "").split("(*)", 1)
  let procType = nameSplit[0].translateType()

  nameSplit[1] = nameSplit[1][1 ..< nameSplit[1].len - 1]
  var isVarArgs = false
  var argsSplit = nameSplit[1].split(',')
  var argSeq: seq[tuple[name: string, kind: string]]
  var unnamedArgCounter = 0
  for arg in argsSplit:
    let argPieces = arg.replace(" const", "").rsplit(' ', 1)
    if argPieces[0] == "...":
      isVarArgs = true
      continue
    var argName = if argPieces.len == 1:
      inc(unnamedArgCounter)
      "unamed_arg_{unnamedArgCounter}".fmt
    else:
      argPieces[1]
    var argType = argPieces[0]
    if argName.contains('*'):
      argType.add('*')
      argName = argName.replace("*", "")
    if reservedWordsDictionary.contains(argName):
      argName = "`{argName}`".fmt
    argType = argType.translateType()
    argSeq.add((name: argName, kind: argType))

  result = "proc("
  for arg in argSeq:
    result.add("{arg.name}: {arg.kind}, ".fmt)
  if argSeq.len > 0:
    result = result[0 ..< result.len - 2]
  if isVarArgs:
    result.add("): {procType} {{.cdecl.}}".fmt)
  else:
    result.add("): {procType} {{.cdecl, varargs.}}".fmt)

proc translateArray(name: string): tuple[size: string, name: string] =
  let nameSplit = name.rsplit('[', 1)
  var arraySize = nameSplit[1]
  arraySize = arraySize[0 ..< arraySize.len - 1]
  if arraySize.contains("COUNT") or arraySize.contains("SIZE"):
    arraySize = $enumsCount[arraySize]
  if arraySize == "(0xFFFF+1)/4096/8": # If more continue to appear automate it
    arraySize = "2"
  result.size = arraySize
  result.name = nameSplit[0]

proc translateType(name: string): string =
  if name.contains("(") and name.contains(")"):
    return name.translateProc()
  if name == "const char* const[]":
    return "ptr cstring"

  result = name.replace("const ", "")
  result = result.replace("unsigned ", "u")
  result = result.replace("signed ", "")

  var depth = result.count('*')
  result = result.replace(" ", "")
  result = result.replace("*", "")
  result = result.replace("&", "")

  result = result.replace("int", "int32")
  result = result.replace("size_t", "uint") # uint matches pointer size just like size_t
  result = result.replace("int3264_t", "int64")
  result = result.replace("float", "float32")
  result = result.replace("double", "float64")
  result = result.replace("short", "int16")
  result = result.replace("_Simple", "")
  if result.contains("char") and not result.contains("Wchar"):
    if result.contains("uchar"):
      result = "uint8"
    elif depth > 0:
      result = result.replace("char", "cstring")
      depth.dec
      if result.startsWith("u"):
        result = result[1 ..< result.len]
    else:
      result = result.replace("char", "int8")
  if depth > 0 and result.contains("void"):
    result = result.replace("void", "pointer")
    depth.dec

  result = result.replace("ImBitArrayForNamedKeys", "ImU32")
  result = result.replace("ImBitArray", "ImU32")
  result = result.replace("ImGuiWindowPtr", "ptr ImGuiWindow")
  result = result.replace("ImS8", "int8") # Doing it a little verbose to avoid issues in the future.
  result = result.replace("ImS16", "int16")
  result = result.replace("ImS32", "int32")
  result = result.replace("ImS64", "int64")
  result = result.replace("ImU8", "uint8")
  result = result.replace("ImU16", "uint16")
  result = result.replace("ImU32", "uint32")
  result = result.replace("ImU64", "uint64")
  result = result.replace("Pair", "ImPair")
  result = result.replace("ImFontPtr", "ptr ImFont")

  if result.startsWith("ImVector_"):
    result = result["ImVector_".len ..< result.len]
    result = "ImVector[{result}]".fmt

  result = result.replace("ImChunkStream_T", "ImChunkStream")

  result = result.replace("ImGuiStorageImPair", "ImGuiStoragePair")

  for d in 0 ..< depth:
    result = "ptr " & result
    if result == "ptr ptr ImDrawList":
      result = "UncheckedArray[ptr ImDrawList]"

  if result == "":
    result = "void"

proc genEnums(output: var string) =
  let file = readFile(rootDir / "cimgui/generator/output/structs_and_enums.json")
  let data = file.parseJson()

  output.add("\n# Enums\ntype\n")

  var tableNamedKeys: Table[string, int]

  for name, obj in data["enums"].pairs:
    var enumName = name
    if enumName.endsWith("_"):
      enumName = name[0 ..< name.len - 1]
    output.add("  {enumName}* {{.pure, size: int32.sizeof.}} = enum\n".fmt)
    enums.incl(enumName)
    var table: Table[int, string]
    for data in obj:
      var dataName = data["name"].getStr()
      let dataValue = data["calc_value"].getInt()
      dataName = dataName.replace("__", "_")
      dataName = dataName.split("_", 1)[1]
      if dataName.endsWith("_"):
        dataName = dataName[0 ..< dataName.len - 1]
      if dataName.match(re"^[0-9]"):
        dataName = "`\"" & dataName & "\"`"
      if dataName.match(re".*COUNT$") or dataName.match(re".*SIZE$"):
        enumsCount[data["name"].getStr()] = data["calc_value"].getInt()
        continue
      if table.hasKey(dataValue):
        echo "Notice: Enum {enumName}.{dataName} already exists as {enumName}.{table[dataValue]} with value {dataValue}, use constant {enumName}_{dataName} to access it".fmt
        tableNamedKeys[enumName & "_" & dataName] = dataValue
        continue
      table[dataValue] = dataName

    var tableOrder: OrderedTable[int, string] # Weird error where data is erased if used directly
    for k, v in table.pairs:
      tableOrder[k] = v
    tableOrder.sort(system.cmp)

    for k, v in tableOrder.pairs:
      output.add("    {v} = {k}\n".fmt)

  if tableNamedKeys.len > 0:
    output.add("\n# Duplicate enums as consts\n")
    for k, v in tableNamedKeys.pairs:
      output.add("const {k}* = {v}\n".fmt)

proc genTypeDefs(output: var string) =
  # Must be run after genEnums
  let file = readFile(rootDir / "cimgui/generator/output/typedefs_dict.json")
  let data = file.parseJson()

  output.add("\n# TypeDefs\ntype\n")

  for name, obj in data.pairs:
    let ignorable = ["const_iterator", "iterator", "value_type", "ImS8",
                     "ImS16", "ImS32", "ImS64", "ImU8", "ImU16", "ImU32",
                     "ImU64", "ImBitArrayForNamedKeys"]
    if obj.getStr().startsWith("struct") or enums.contains(name) or ignorable.contains(name):
      continue

    output.add("  {name}* = {obj.getStr().translateType()}\n".fmt)

proc genTypes(output: var string) =
  # Does not add a `type` keyword
  # Must be run after genEnums
  let file = readFile(rootDir / "cimgui/generator/output/structs_and_enums.json")
  let data = file.parseJson()

  output.add("\n")
  output.add(notDefinedStructs)

  for name, obj in data["structs"].pairs:
    if name == "Pair" or name == "ImGuiStoragePair" or name == "ImGuiStyleMod" or name == "ImGuiInputEvent":
      continue

    if name == "ImDrawChannel":
      output.add("  ImDrawChannel* {.importc: \"ImDrawChannel\", imgui_header.} = ptr object\n")
      continue

    output.add("  {name}* {{.importc: \"{name}\", imgui_header.}} = object\n".fmt)
    for member in obj:
      var memberName = member["name"].getStr()
      if memberName == "Ptr":
        memberName = "`ptr`"
      if memberName == "Type":
        memberName = "`type`"
      var memberImGuiName = "{{.importc: \"{memberName}\".}}".fmt
      if memberName.startsWith("_"):
        memberName = memberName[1 ..< memberName.len]
      if memberName.isUpper():
        memberName = memberName.normalize()
      memberName = memberName.uncapitalize()

      if memberImGuiName.contains('['):
        memberImGuiName = memberImGuiName[0 ..< memberImGuiName.find('[')] & "\".}"

      if not memberName.contains("["):
        if not member.contains("template_type"):
          output.add("    {memberName}* {memberImGuiName}: {member[\"type\"].getStr().translateType()}\n".fmt)
        else:
          # Assuming all template_type containers are ImVectors
          var templateType = member["template_type"].getStr()
          if templateType == "ImGui*OrIndex":
            templateType = "ImGuiPtrOrIndex"
          templateType = templateType.translateType()

          if templateType == "ImGuiTabBar": # Hope I don't regret this hardocoded if
            output.add("    {memberName}* {memberImGuiName}: ptr ImPool\n".fmt)
          elif templateType == "ImGuiColumns":
            output.add("    {memberName}* {memberImGuiName}: ImVectorImGuiColumns\n".fmt)
          else:
            output.add("    {memberName}* {memberImGuiName}: ImVector[{templateType}]\n".fmt)
        continue

      let arrayData = memberName.translateArray()
      output.add("    {arrayData[1]}* {memberImGuiName}: array[{arrayData[0]}, {member[\"type\"].getStr().translateType()}]\n".fmt)

proc genProcs(output: var string) =
  let file = readFile(rootDir / "cimgui/generator/output/definitions.json")
  let data = file.parseJson()

  output.add("\n{preProcs}\n".fmt)

  for name, obj in data.pairs:
    var isNonUDT = false
    var isConstructor = false
    var nonUDTNumber = 0
    for variation in obj:
      if variation.contains("nonUDT"):
        nonUDTNumber.inc
        isNonUDT = true
      if blackListProc.contains(variation["cimguiname"].getStr()):
        continue

      # Name
      var funcname = ""
      if variation.contains("stname") and variation["stname"].getStr() != "":
        if variation.contains("destructor"):
          funcname = "destroy"
        else:
          funcname = variation["funcname"].getStr()
      else:
        funcname = variation["cimguiname"].getStr()
        #funcname = funcname.rsplit("_", 1)[1]

      if isNonUDT:
        funcname = funcname & "NonUDT"
        if nonUDTNumber != 1:
          funcname = funcname & $nonUDTNumber

      if variation.contains("constructor"):
        if funcname.startsWith("ImVector"):
          continue
        funcname = "new" & funcname.capitalizeAscii()
        isConstructor = true

      if funcname.isUpper():
        funcname = funcname.normalize()
      funcname = funcname.uncapitalize()

      if funcname.startsWith("_"):
        funcname = funcname[1 ..< funcname.len]

      if reservedWordsDictionary.contains(funcname):
        funcname = "`{funcname}`".fmt

      output.add("proc {funcname}*".fmt)

      var isGeneric = false
      var isVarArgs = variation.contains("isvararg") and variation["isvararg"].getBool()
      var argsOutput = ""
      # Args
      for arg in variation["argsT"]:
        var argName = arg["name"].getStr()
        var argType = arg["type"].getStr().translateType()
        var argDefault = ""
        if variation.contains("defaults") and variation["defaults"].kind == JObject and
           variation["defaults"].contains(argName):
          argDefault = variation["defaults"][argName].getStr()
          argDefault = argDefault.replace("4294967295", "high(uint32)")
          argDefault = argDefault.replace("(((ImU32)(255)<<24)|((ImU32)(255)<<16)|((ImU32)(255)<<8)|((ImU32)(255)<<0))", "high(uint32)")
          argDefault = argDefault.replace("(((ImU32)(255)<<24)|((ImU32)(0)<<16)|((ImU32)(0)<<8)|((ImU32)(255)<<0))", "4278190335")
          argDefault = argDefault.replace("4278190335", "4278190335'u32")
          argDefault = argDefault.replace("FLT_MAX", "high(float32)")
          argDefault = argDefault.replace("((void*)0)", "nil")
          argDefault = argDefault.replace("NULL", "nil")
          argDefault = argDefault.replace("-FLT_MIN", "0")
          argDefault = argDefault.replace("~0", "-1")
          argDefault = argDefault.replace("sizeof(float)", "sizeof(float32).int32")
          argDefault = argDefault.replace("ImDrawCornerFlags_All", "ImDrawCornerFlags.All")
          argDefault = argDefault.replace("ImGuiPopupPositionPolicy_Default", "ImGuiPopupPositionPolicy.Default")
          argDefault = argDefault.replace("ImGuiPopupFlags_None", "ImGuiPopupFlags.None")
          argDefault = argDefault.replace("ImGuiTypingSelectFlags_None", "ImGuiTypingSelectFlags.None")
          argDefault = argDefault.replace("ImGuiNavHighlightFlags_None", "ImGuiNavHighlightFlags.None")
          argDefault = argDefault.replace("ImGuiNavHighlightFlags_TypeDefault", "ImGuiNavHighlightFlags.TypeDefault")

          if argDefault.startsWith("ImVec"):
            let letters = ['x', 'y', 'z', 'w']
            var argPices = argDefault[7 ..< argDefault.len - 1].split(',')
            argDefault = argDefault[0 ..< 7]
            for p in 0 ..< argPices.len:
              argDefault.add("{letters[p]}: {argPices[p]}, ".fmt)
            argDefault = argDefault[0 ..< argDefault.len - 2] & ")"

          if (argType.startsWith("ImGui") or argType.startsWith("Im")) and not argType.contains("Callback") and not argType.contains("ImVec"): # Ugly hack, should fix later
            argDefault.add(".{argType}".fmt)

        if argName.startsWith("_"):
          argName = argName[1 ..< argName.len]
        if argName.isUpper():
          argName = argName.normalize()
        argName = argName.uncapitalize()

        if reservedWordsDictionary.contains(argName):
          argName = "`{argName}`".fmt

        if argType.contains('[') and not argType.contains("ImVector[") and not argType.contains("UncheckedArray["):
          let arrayData = argType.translateArray()
          if arrayData[1].contains("cstringconst"):
            echo "{name}\n{obj.pretty}".fmt
          argType = "var array[{arrayData[0]}, {arrayData[1]}]".fmt
        argType = argType.replace(" {.cdecl.}", "")

        if argName == "..." or argType == "..." or argType == "va_list":
          isVarArgs = true
          continue
        if argType == "T" or argType == "ptr T":
          isGeneric = true

        if argDefault == "":
          argsOutput.add("{argName}: {argType}, ".fmt)
        else:
          argsOutput.add("{argName}: {argType} = {argDefault}, ".fmt)
      if variation["argsT"].len > 0:
        argsOutput = argsOutput[0 ..< argsOutput.len - 2]

      # Ret
      var argRet = "void"
      if variation.contains("ret"):
        argRet = variation["ret"].getStr().translateType()
      if argRet == "T" or argRet == "ptr T":
        isGeneric = true
      if argRet == "explicit":
        argRet = "ptr ImVec2ih" # Ugly solution for a temporal problem
      if isConstructor:
        # Here "funcname" is assumed "newConstrucorName" so,
        var retType = funcname.split("new")[1]
        if retType == "ImBitArray": # Exception
           retType &=  "Ptr"
        argRet = "ptr " & retType

      output.add(if isGeneric: "[T](" else: "(")
      output.add(argsOutput)
      output.add("): ")
      output.add(argRet)

      # Pragmas
      var pragmaName = variation["cimguiname"].getStr()
      if variation.contains("ov_cimguiname"):
        pragmaName = variation["ov_cimguiname"].getStr()
      output.add(" {" & ".importc: \"{pragmaName}\"".fmt)
      if isVarArgs:
        output.add(", varargs")
      output.add(".}")

      output.add("\n")

      # Checking if it doesn't exist already
      let outSplit = output.rsplit("\n", 3)
      if outSplit[1] == outSplit[2] or outSplit[1].split('{')[0] == outSplit[2].split('{')[0]:
        output = "{outSplit[0]}\n{outSplit[1]}\n".fmt

  output.add("\n{postProcs}\n".fmt)

proc igGenerate*() =
  var output = srcHeader

  output.genEnums()
  output.genTypeDefs()
  output.genTypes()
  output.genProcs()
  output.add("\n" & cherryTheme)

  writeFile(rootDir / "wrapper.nim", output)

when isMainModule:
  igGenerate()