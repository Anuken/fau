import core, fau/assets, os
import wrapper

#loosely based on https://github.com/ocornut/imgui/blob/master/backends/imgui_impl_glfw.cpp

converter toImVec2*(vec: Vec2): ImVec2 = cast[ImVec2](vec)
converter toFauVec2*(vec: ImVec2): Vec2 = cast[Vec2](vec)
converter toImVec4*(color: Color): ImVec4 = ImVec4(x: color.r, y: color.g, z: color.b, w: color.a)

proc imvec4*(x, y, z, w: float32): ImVec4 = ImVec4(x: x, y: y, z: z, w: w) 
proc imvec2*(x, y: float32): ImVec2 = ImVec2(x: x, y: y) 

proc `or`*(f1, f2: ImguiWindowFlags): ImguiWindowFlags =
  ((f1.int32) or (f2.int32)).ImguiWindowFlags

const uiScaleFactor = 1f

proc igInputFloat2*(label: cstring, v: var Vec2, format: cstring = "%g", flags: ImGuiInputTextFlags = 0.ImGuiInputTextFlags): bool {.discardable, inline} =
  var arr = [v.x, v.y]
  result = igInputFloat2(label, arr, format, flags)
  v = arr.vec2

proc igInputFloat4*(label: cstring, v: var Rect, format: cstring = "%g", flags: ImGuiInputTextFlags = 0.ImGuiInputTextFlags): bool {.discardable, inline} =
  var arr = [v.x, v.y, v.w, v.h]
  result = igInputFloat4(label, arr, format, flags)
  v = rect(arr[0], arr[1], arr[2], arr[3])

proc igInputInt2*(label: cstring, v: var Vec2i, flags: ImGuiInputTextFlags = 0.ImGuiInputTextFlags): bool {.discardable, inline} =
  var arr = [v.x.int32, v.y.int32]
  result = igInputInt2(label, arr, flags)
  v = arr.vec2i

proc igColorEdit4*(label: cstring, col: var Color, flags: ImGuiColorEditFlags = ImGuiColorEditFlags.AlphaBar): bool {.discardable, inline} =
  var arr = [col.r, col.g, col.b, col.a]

  result = igColorEdit4(label, arr, flags)

  col = rgba(arr[0], arr[1], arr[2], arr[3])

#int version. not int32
#note that this truncates to the int32 range, but who needs numbers this big in text fields anyway?
proc igInputInt*(label: cstring, v: ptr int, step: int32 = 1, step_fast: int32 = 100, flags: ImGuiInputTextFlags = 0.ImGuiInputTextFlags): bool {.discardable, inline.} =
  var i32 = v[].int32

  result = igInputInt(label, addr i32, step, step_fast, flags)

  v[] = i32

proc igInputText*(label: cstring, text: var string, bufSize = 64, flags: ImGuiInputTextFlags = 0.ImGuiInputTextFlags, callback: ImGuiInputTextCallback = nil, user_data: pointer = nil): bool {.discardable, inline.} =
  var buff = newString(max(bufSize, text.len))
  buff[0..text.high] = text

  result = igInputText(label, buff.cstring, bufSize.uint, flags, callback, user_data)

  #I'm sure there's a better way to do this, but right now I don't care.
  let len = buff.cstring.len
  buff.setLen(len)
  text = buff

proc igInputTextWithHint*(label: cstring, hint: cstring, text: var string, bufSize = 64, flags: ImGuiInputTextFlags = 0.ImGuiInputTextFlags, callback: ImGuiInputTextCallback = nil, user_data: pointer = nil): bool {.discardable, inline.} =
  var buff = newString(max(bufSize, text.len))
  buff[0..text.high] = text

  result = igInputTextWithHint(label, hint, buff.cstring, bufSize.uint, flags, callback, user_data)

  #I'm sure there's a better way to do this, but right now I don't care.
  let len = buff.cstring.len
  buff.setLen(len)
  text = buff

proc igCombo*(label: cstring, current_item: ptr int, items: openArray[string], popup_max_height_in_items: int32 = -1): bool {.discardable.} =
  let itemArray = allocCStringArray(items)
  var cur = current_item[].int32
  result = igCombo(label, addr cur, cast[ptr cstring](itemArray), items.len.int32, popup_max_height_in_items)
  current_item[] = cur
  deallocCStringArray(itemArray)

proc igComboEnum*[T: Ordinal](label: cstring, current: var T, popup_max_height_in_items: int32 = -1): bool =
  var 
    values: seq[string]
    index = current.int
  for i, val in low(T)..high(T):
    values.add($val)
  
  result = igCombo(label, index, values, popup_max_height_in_items)

  current = index.T

type IVert = object
  pos: Vec2
  uv: Vec2
  color: Color

var
  fontTexture: Texture
  mesh: Mesh[IVert]
  shader: Shader
  cursors: array[ImGuiMouseCursor.high.int + 1, Cursor]
  initialized = false
  changeCursor = true
  iniFile: string

proc mapKey(key: KeyCode): ImGuiKey =
  #TODO: number and numpad keys?
  return case key:
  of keyA: ImGuiKey.A
  of keyB: ImGuiKey.B
  of keyC: ImGuiKey.C
  of keyD: ImGuiKey.D
  of keyE: ImGuiKey.E
  of keyF: ImGuiKey.F
  of keyG: ImGuiKey.G
  of keyH: ImGuiKey.H
  of keyI: ImGuiKey.I
  of keyJ: ImGuiKey.J
  of keyK: ImGuiKey.K
  of keyL: ImGuiKey.L
  of keyM: ImGuiKey.M
  of keyN: ImGuiKey.N
  of keyO: ImGuiKey.O
  of keyP: ImGuiKey.P
  of keyQ: ImGuiKey.Q
  of keyR: ImGuiKey.R
  of keyS: ImGuiKey.S
  of keyT: ImGuiKey.T
  of keyU: ImGuiKey.U
  of keyV: ImGuiKey.V
  of keyW: ImGuiKey.W
  of keyX: ImGuiKey.X
  of keyY: ImGuiKey.Y
  of keyZ: ImGuiKey.Z
  of keyTab: ImGuiKey.Tab
  of keyLeft: ImGuiKey.LeftArrow
  of keyRight: ImGuiKey.RightArrow
  of keyUp: ImGuiKey.UpArrow
  of keyDown: ImGuiKey.DownArrow
  of keyPageUp: ImGuiKey.PageUp
  of keyPageDown: ImGuiKey.PageDown
  of keyHome: ImGuiKey.Home
  of keyEnd: ImGuiKey.End
  of keyInsert: ImGuiKey.Insert
  of keyDelete: ImGuiKey.Delete
  of keyBackspace: ImGuiKey.Backspace
  of keySpace: ImGuiKey.Space
  of keyReturn: ImGuiKey.Enter
  of keyEscape: ImGuiKey.Escape
  of keyLCtrl: ImGuiKey.LeftCtrl
  of keyLShift: ImGuiKey.LeftShift
  of keyLalt: ImGuiKey.LeftAlt
  of keyLsuper: ImGuiKey.LeftSuper
  of keyRCtrl: ImGuiKey.RightCtrl
  of keyRshift: ImGuiKey.RightShift
  of keyRalt: ImGuiKey.RightAlt
  of keyRsuper: ImGuiKey.RightSuper
  of keyApostrophe: ImGuiKey.Apostrophe
  of keyComma: ImGuiKey.Comma
  of keyMinus: ImGuiKey.Minus
  of keyPeriod: ImGuiKey.Period
  of keySlash: ImGuiKey.Slash
  of keySemicolon: ImGuiKey.Semicolon
  of keyEquals: ImGuiKey.Equal
  of keyLeftBracket: ImGuiKey.LeftBracket
  of keyBackSlash: ImGuiKey.Backslash
  of keyRightBracket: ImGuiKey.RightBracket
  of keyGrave: ImGuiKey.GraveAccent
  of keyCapsLock: ImGuiKey.CapsLock
  of keyScrollLock: ImGuiKey.ScrollLock
  of keyNumlockclear: ImGuiKey.NumLock
  of keyPrintScreen: ImGuiKey.PrintScreen
  of keyPause: ImGuiKey.Pause
  of keyF1: ImGuiKey.F1
  of keyF2: ImGuiKey.F2
  of keyF3: ImGuiKey.F3
  of keyF4: ImGuiKey.F4
  of keyF5: ImGuiKey.F5
  of keyF6: ImGuiKey.F6
  of keyF7: ImGuiKey.F7
  of keyF8: ImGuiKey.F8
  of keyF9: ImGuiKey.F9
  of keyF10: ImGuiKey.F10
  of keyF11: ImGuiKey.F11
  of keyF12: ImGuiKey.F12
  else: ImGuiKey.None

proc igGlfwGetClipboardText(userData: pointer): cstring {.cdecl.} =
  getClipboardString().cstring

proc igGlfwSetClipboardText(userData: pointer, text: cstring): void {.cdecl.} =
  setClipboardString($text)

proc reloadFontTexture =
  let io = igGetIO()

  var 
    pixels: ptr uint8
    width: int32
    height: int32
  
  io.fonts.getTexDataAsRGBA32(pixels.addr, width.addr, height.addr)
  fontTexture = loadTexturePtr(vec2i(width, height), pixels, filter = tfLinear)
  io.fonts.texID = fontTexture.addr

proc imguiLoadFont*(path: static string, size: float32) =
  let io = igGetIO()

  let fontData = assetReadStatic(path)

  var cfg = newImFontConfig()
  cfg.fontDataOwnedByAtlas = false

  io.fonts.clear()
  io.fonts.addFontFromMemoryTTF(addr fontData[0], fontData.len.int32, size, fontCfg = cfg);
  io.fonts.build()
  
  reloadFontTexture()

proc createRenderer(font: static string, fontSize: float32) =
  when font.len > 0:
    imguiLoadFont(font, fontSize)
  else:
    reloadFontTexture()

  #this is basically the spritebatch shader without mixcol
  shader = newShader(
    """
    attribute vec4 a_pos;
    attribute vec4 a_color;
    attribute vec2 a_uv;

    uniform mat4 u_proj;
    varying vec4 v_color;
    varying vec2 v_uv;

    void main(){
      v_color = a_color;
      v_uv = a_uv;
      gl_Position = u_proj * a_pos;
    }
    """,
    """
    varying lowp vec4 v_color;
    varying vec2 v_uv;
    uniform sampler2D u_texture;

    void main(){
      gl_FragColor = texture2D(u_texture, v_uv) * v_color;
    }
    """
  )

  mesh = newMesh[IVert](update = false, indexed = true)

proc imguiUpdateFau =
  let io = igGetIO()

  io.displaySize = fau.size / uiScaleFactor
  io.displayFramebufferScale = vec2(uiScaleFactor)

  io.deltaTime = max(fau.rawDelta.float32, 0.001f)

  io.addKeyEvent(Ctrl, keyLCtrl.down or keyRCtrl.down)
  io.addKeyEvent(Shift, keyLShift.down or keyRShift.down)
  io.addKeyEvent(Alt, keyLAlt.down or keyRAlt.down)
  io.addKeyEvent(Super, keyLsuper.down or keyRsuper.down)

  io.addMousePosEvent(fau.mouse.x/uiScaleFactor, (fau.size.y - 1f - fau.mouse.y)/uiScaleFactor)

  if changeCursor and io.wantCaptureMouse:
    let cursor = igGetMouseCursor()
    if cursor == ImGuiMouseCursor.None or io.mouseDrawCursor:
      setCursorHidden(true)
    else:
      setCursor(cursors[cursor.int])
      setCursorHidden(false)

  igNewFrame()

  fau.captureMouse = igGetIO().wantCaptureMouse
  fau.captureKeyboard = igGetIO().wantCaptureKeyboard

proc imguiRenderFau =
  #pending fau draw operations need to be flushed
  drawFlush()

  #does this need to be called multiple times...? should it be moved out?
  igRender()

  let 
    io = igGetIO()
    data = igGetDrawData()

  data.scaleClipRects(io.displayFramebufferScale)

  let 
    #It's flipped and I don't know why.
    matrix = ortho(data.displayPos + vec2(0f, data.displaySize.y), data.displaySize * vec2(1f, -1f))
    pos = data.displayPos

  for n in 0..<data.cmdListsCount:
    var commands = data.cmdLists.data[n]
    var indexBufferOffset: int = 0

    mesh.updateData(
      0..commands.vtxBuffer.size.int,
      0..commands.idxBuffer.size.int,
      vertexPtr = commands.vtxBuffer.data[0].addr, 
      indexPtr = commands.idxBuffer.data[0].addr
    )

    for commandIndex in 0..<commands.cmdBuffer.size:
      var pcmd = commands.cmdBuffer.data[commandIndex]

      if pcmd.userCallback != nil:
        pcmd.userCallback(commands, pcmd.addr)
      else:
        var clipRect = rect(pcmd.clipRect.x - pos.x, pcmd.clipRect.y - pos.y, pcmd.clipRect.z - pcmd.clipRect.x - pos.x, pcmd.clipRect.w - pcmd.clipRect.y - pos.y)

        clipRect.y = (fau.size.y - clipRect.y) - clipRect.h

        if (clipRect.x < fau.size.x and clipRect.y < fau.size.y and clipRect.w > 0f and clipRect.h > 0f):
       
          mesh.render(shader, meshParams(
              clip = rect(clipRect.x, clipRect.y, clipRect.w, clipRect.h),
              offset = pcmd.idxOffset.int,
              count = pcmd.elemCount.int,
              blend = blendNormal
            )):
            proj = matrix
            #should use pcmd.textureId, but I only supplied one texture so I will use that for now
            texture = fontTexture.sampler(7)
        
        indexBufferOffset += pcmd.elemCount.int

proc imguiInitFau*(appName: string = "", useCursor = true, theme: proc() = nil, font: static string = "", fontSize = 22f) =
  if initialized: return

  initialized = true
  changeCursor = useCursor

  let context = igCreateContext()
  let io = igGetIO()

  if theme != nil:
    theme()

  if useCursor:
    io.backendFlags = (io.backendFlags.int32 or ImGuiBackendFlags.HasMouseCursors.int32).ImGuiBackendFlags
  
  if appName == "":
    io.iniFilename = nil
  else:
    let folder = getSaveDir(appName)

    try:
      folder.createDir()
      #save to global variable to prevent GC
      iniFile = (folder / "imgui.ini")
      io.iniFilename = iniFile.cstring
    except:
      echo "Failed to create save directory: ", getCurrentExceptionMsg()
      io.iniFilename = nil

  cursors[ImGuiMouseCursor.Arrow.int] = newCursor(cursorArrow)
  cursors[ImGuiMouseCursor.TextInput.int] = newCursor(cursorIbeam)
  cursors[ImGuiMouseCursor.ResizeNS.int] = newCursor(cursorResizeV)
  cursors[ImGuiMouseCursor.ResizeEW.int] = newCursor(cursorResizeH)
  cursors[ImGuiMouseCursor.Hand.int] = newCursor(cursorHand)
  cursors[ImGuiMouseCursor.ResizeAll.int] = newCursor(cursorResizeAll)
  cursors[ImGuiMouseCursor.ResizeNESW.int] = newCursor(cursorResizeNesw)
  cursors[ImGuiMouseCursor.ResizeNWSE.int] = newCursor(cursorResizeNwse)
  cursors[ImGuiMouseCursor.NotAllowed.int] = newCursor(cursorNotAllowed)

  createRenderer(font, fontSize)

  io.setClipboardTextFn = igGlfwSetClipboardText
  io.getClipboardTextFn = igGlfwGetClipboardText

  addFauListener do(e: FauEvent):
    case e.kind:
    of feFrame:
      imguiUpdateFau()
    of feEndFrame:
      imguiRenderFau()
    of feDestroy:
      context.igDestroyContext()
      initialized = false
    of feKey:
      let mapped = mapKey(e.key)
      if mapped != ImGuiKey.None:
        io.addKeyEvent(mapped, e.keyDown)
    of feText:
      io.addInputCharacter(e.text)
    of feTouch:
      if e.touchButton in {keyMouseLeft, keyMouseRight, keyMouseMiddle}:
        let code = case e.touchButton:
        of keyMouseLeft: ImGuiMouseButton.Left
        of keyMouseRight: ImGuiMouseButton.Right
        of keyMouseMiddle: ImGuiMouseButton.Middle
        else: ImGuiMouseButton.Left

        io.addMouseButtonEvent(code.int32, e.touchDown)
    of feScroll:
      io.addMouseWheelEvent(e.scroll.x, e.scroll.y)
    else: discard
