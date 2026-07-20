
# Wrapper around malebolgia with a conditional dummy wrapper for web releases

when compileOption("threads"):
  import pkg/malebolgia
  export malebolgia
else:
  #dummy implementation that doesn't do anything
  import std/macros

  type Master* = object

  proc createMaster*(): Master = Master()

  template awaitAll*(m: Master, body: untyped): untyped =
    body
  
  macro spawn*(a: Master; b: untyped) =
    if b.len == 3:
      let
        left = b[2]
        right = b[1]
      result = quote do:
        `left` = `right`
    else:
      result = b

