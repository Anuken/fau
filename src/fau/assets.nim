import os, streams, macros, strutils

## if true, assets are loaded statically instead of from a local folder
## this is always true by default on emscripten
const staticAssets* = not defined(localAssets) and not defined(emscripten)

## if staticAssets is false, assets are loaded from this directory relative to the executable.
var assetFolder* = "assets/"

## project root directory
const rootDir = if getProjectPath().endsWith("src"): getProjectPath()[0..^5] else: getProjectPath()

proc assetFile*(name: string): string =
  ## Resolves the asset to a specific file by name
  assetFolder / name

template staticReadString*(filename: string): string = 
  const realDir = rootDir & "/assets/" & filename
  const str = staticRead(realDir)
  str

template staticReadStream*(filename: string): StringStream =
  newStringStream(staticReadString(filename))

proc assetStream*(path: static[string]): StringStream =
  ## Fetches a stream from an asset path.
  when staticAssets: staticReadStream(path)
  else: newStringStream(readFile(path.assetFile))