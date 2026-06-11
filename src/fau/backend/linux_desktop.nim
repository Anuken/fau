import std/[os, strutils]
import ../[assets]

from posix import nil

proc createDesktopFile*(appName: string, appTitle: string, hidden = false) =
  ## Linux-specific utility function to auto-generate a .desktop file to give the application an icon.
  ## This is useful for testing, but probably annoying for real users.

  when assetExistsStatic("icon.png"):
    let dir = getHomeDir() / ".local/share/applications"
    if dir.dirExists:
      try:
        const len = 2000

        var path = newString(len)
        
        #grab the current executable path
        let read = posix.readlink("/proc/self/exe", cast[cstring](addr path[0]).cstring, len)

        if read != -1:
          path.setLen(read)

          let 
            appFile = dir / (appName & ".desktop")
            iconPath = dir / (appName & ".png")
          
          if not iconPath.fileExists:
            writeFile(iconPath, assetReadStatic("icon.png"))

          const temp = """
          [Desktop Entry] 
          Version=1.0
          Type=Application
          Terminal=false
          Icon=%ICON_PATH%
          Name=%APP_TITLE%
          Exec=%APP_PATH%
          Hidden=%HIDDEN%
          StartupWMClass=%APP_CLASS_NAME%
          """.unindent

          let formatted = temp
          .replace("%APP_NAME%", appName)
          .replace("%APP_TITLE%", appTitle)
          .replace("%APP_PATH%", path)
          .replace("%ICON_PATH%", iconPath)
          .replace("%HIDDEN%", $hidden)
          .replace("%APP_CLASS_NAME%", appName.toLowerAscii())

          writeFile(appFile, formatted)
      except:
        echo "Failed to create .desktop file: ", getCurrentExceptionMsg()