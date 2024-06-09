## This module is completely broken unless you include it. I've tried workarounds. None of them work.

macro loadShaders() =
  result = newStmtList()

  var reload = newStmtList()

  for name, value in shaders.fieldPairs:
    let 
      vertVal = 
        if fileExists("assets/shaders/" & name & ".vert"):
          quote do:
            assetReadStatic("shaders/" & name & ".vert")
        elif value.hasCustomPragma(screenShader): 
          "screenspaceVertex".ident 
        else: 
          "defaultVertShader".ident
      
      fragVal = "shaders/" & name & ".frag"

    result.add quote do:
      value = newShader(`vertVal`, assetReadStatic(`fragVal`), `name`)
    
    when defined(debug):
      let 
        writeVal = ("lastWriteTime_" & name).ident
        fragValFile = "assets/shaders/" & name & ".frag"

      reload.add quote do:
        block:
          let i = getFileInfo(`fragValFile`)
          if i.lastWriteTime != `writeVal`:
            `writeVal` = i.lastWriteTime
            let prev = value
            try:
              value = newShader(`vertVal`, assetReadStatic(`fragVal`), `name`)
            except GLError as e:
              echo name, ".frag: ", e.msg
              value = prev
  
  when defined(debug):
    for name, value in shaders.fieldPairs:
      let writeVal = ("lastWriteTime_" & name).ident

      result.add quote do:
        var `writeVal`: Time

    result.add quote do:
      addFauListener(feFrame):
        if fau.frameId mod 10 == 0:
          `reload`