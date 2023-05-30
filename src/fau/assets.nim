import os, streams, macros, strutils, tables

#for asset reading
when defined(Android):
  import glfm

## if true, assets are loaded statically instead of from a local folder
## this is always false by default on emscripten
const staticAssets* = not defined(localAssets) and not defined(emscripten) and not defined(Android)
## project root directory
const rootDir = if getProjectPath().endsWith("src"): getProjectPath()[0..^5] else: getProjectPath()
## maps asset names relative to the asset folder to static string data
let preloadedAssets* = newTable[string, string]()
## if staticAssets is false, assets are loaded from this directory relative to the executable.
var assetFolder* = when defined(Android): "" else: "assets/"

proc getSaveDir*(app: string): string =
  when defined(Android):
    return $glfmFilesDir()
  else: 
    getConfigDir() / app

macro preloadFolder*(path: static[string]): untyped =
  ## Non-recursively preloads all files in a directory into the static assets table. This embeds them into the executable for use in assetRead.
  result = newStmtList()

  when staticAssets:
    #can't use / because it fails with cross compilation
    for e in walkDir("assets/" & path):
      let file = e.path.substr("assets/".len)
      let path = rootDir  & "/" & e.path
      result.add quote do:
        const data = staticRead(`path`)
        preloadedAssets[`file`] = data

proc assetFile*(name: string): string =
  ## Resolves the asset to a specific file by name
  assetFolder / name

proc assetRead*(filename: string): string =

  ## Non-static version of asset reading; uses the preloaded assets table if static, filesystem if not.
  when staticAssets:
    if filename notin preloadedAssets:
      raise newException(IOError, "Asset not found (did you forget to pre-load it?): " & filename)
    return preloadedAssets[filename]
  elif defined(Android):
    let size = glfmReadFileSize(filename)

    var 
      assetData = cast[cstring](alloc(size))
      outString = newString(size)
    
    discard glfmReadFileBuffer(filename, assetData)
    copyMem(addr outString[0], assetData, size)
    dealloc(assetData)

    return outString
  else:
    #standard asset reading
    return readFile(filename.assetFile)

template assetReadStatic*(filename: string): string =
  when not staticAssets:
    assetRead(filename)
  else:
    ## Reads a static-only asset
    const realDir = rootDir & "/assets/" & filename
    const str = staticRead(realDir)
    str

proc assetExistsStatic*(filename: static string): bool =
  const realDir = rootDir & "/assets/" & filename
  return fileExists(realDir)

template staticReadStream*(filename: string): StringStream =
  newStringStream(assetReadStatic(filename))

proc assetStaticStream*(path: static[string]): StringStream =
  ## Fetches a stream from an asset path.
  when staticAssets: staticReadStream(path)
  elif defined(Android): newStringStream(assetRead(path))
  else: newStringStream(readFile(path.assetFile))