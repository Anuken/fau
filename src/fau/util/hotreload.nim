import ../globals, std/[times, os]

proc listenFileChange*(file: string, callback: proc()) =
  var
    currentModified = file.getFileInfo().lastWriteTime
    lastChangeTime: Time
    waiting = false

  addFauListener(feFrame):
    if fau.frameId mod 3 == 1:
      try:
        let newModified = file.getFileInfo().lastWriteTime
        if currentModified != newModified:
          currentModified = newModified
          lastChangeTime = getTime()
          waiting = true
      except OSError:
        discard

    if waiting and (getTime() - lastChangeTime).inMilliseconds >= 100:
      waiting = false
      callback()

proc listenFileChangeSafe*(file: string, callback: proc()) =
  ## Listens to file reloads, but handles any exceptions (e.g. due to in-progress writes or invalid data)
  listenFileChange(file) do():
    try:
      callback()
    except Exception as e:
      echo "Failed to reload file: ", file, ": ", e.msg

proc listenFileLoad*(file: string, callback: proc()) =
  ## Invokes the callback, then calls listenFileChangeSafe.
  callback()
  listenFileChangeSafe(file, callback)
  