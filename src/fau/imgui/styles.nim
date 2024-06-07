import impl, wrapper

proc `[]=`(colors: var array[0..54, ImVec4], t: ImGuiCol, color: ImVec4)  {.inline.} =
  colors[t.int32] = color

#https://github.com/ocornut/imgui/issues/707#issuecomment-917151020
proc igStyleColorsDeepDark*() =
  var 
    style = igGetStyle()
  
  template colors: array[0..54, ImVec4] = style.colors

  colors[ImGuiCol.Text]                   = imvec4(1.00f, 1.00f, 1.00f, 1.00f)
  colors[ImGuiCol.TextDisabled]           = imvec4(0.50f, 0.50f, 0.50f, 1.00f)
  colors[ImGuiCol.WindowBg]               = imvec4(0.10f, 0.10f, 0.10f, 1.00f)
  colors[ImGuiCol.ChildBg]                = imvec4(0.00f, 0.00f, 0.00f, 0.00f)
  colors[ImGuiCol.PopupBg]                = imvec4(0.19f, 0.19f, 0.19f, 0.92f)
  colors[ImGuiCol.Border]                 = imvec4(0.19f, 0.19f, 0.19f, 0.29f)
  colors[ImGuiCol.BorderShadow]           = imvec4(0.00f, 0.00f, 0.00f, 0.24f)
  colors[ImGuiCol.FrameBg]                = imvec4(0.05f, 0.05f, 0.05f, 0.54f)
  colors[ImGuiCol.FrameBgHovered]         = imvec4(0.19f, 0.19f, 0.19f, 0.54f)
  colors[ImGuiCol.FrameBgActive]          = imvec4(0.20f, 0.22f, 0.23f, 1.00f)
  colors[ImGuiCol.TitleBg]                = imvec4(0.00f, 0.00f, 0.00f, 1.00f)
  colors[ImGuiCol.TitleBgActive]          = imvec4(0.06f, 0.06f, 0.06f, 1.00f)
  colors[ImGuiCol.TitleBgCollapsed]       = imvec4(0.00f, 0.00f, 0.00f, 1.00f)
  colors[ImGuiCol.MenuBarBg]              = imvec4(0.14f, 0.14f, 0.14f, 1.00f)
  colors[ImGuiCol.ScrollbarBg]            = imvec4(0.05f, 0.05f, 0.05f, 0.54f)
  colors[ImGuiCol.ScrollbarGrab]          = imvec4(0.34f, 0.34f, 0.34f, 0.54f)
  colors[ImGuiCol.ScrollbarGrabHovered]   = imvec4(0.40f, 0.40f, 0.40f, 0.54f)
  colors[ImGuiCol.ScrollbarGrabActive]    = imvec4(0.56f, 0.56f, 0.56f, 0.54f)
  colors[ImGuiCol.CheckMark]              = imvec4(0.33f, 0.67f, 0.86f, 1.00f)
  colors[ImGuiCol.SliderGrab]             = imvec4(0.34f, 0.34f, 0.34f, 0.54f)
  colors[ImGuiCol.SliderGrabActive]       = imvec4(0.56f, 0.56f, 0.56f, 0.54f)
  colors[ImGuiCol.Button]                 = imvec4(0.05f, 0.05f, 0.05f, 0.54f)
  colors[ImGuiCol.ButtonHovered]          = imvec4(0.19f, 0.19f, 0.19f, 0.54f)
  colors[ImGuiCol.ButtonActive]           = imvec4(0.20f, 0.22f, 0.23f, 1.00f)
  colors[ImGuiCol.Header]                 = imvec4(0.00f, 0.00f, 0.00f, 0.52f)
  colors[ImGuiCol.HeaderHovered]          = imvec4(0.00f, 0.00f, 0.00f, 0.36f)
  colors[ImGuiCol.HeaderActive]           = imvec4(0.20f, 0.22f, 0.23f, 0.33f)
  colors[ImGuiCol.Separator]              = imvec4(0.28f, 0.28f, 0.28f, 0.29f)
  colors[ImGuiCol.SeparatorHovered]       = imvec4(0.44f, 0.44f, 0.44f, 0.29f)
  colors[ImGuiCol.SeparatorActive]        = imvec4(0.40f, 0.44f, 0.47f, 1.00f)
  colors[ImGuiCol.ResizeGrip]             = imvec4(0.28f, 0.28f, 0.28f, 0.29f)
  colors[ImGuiCol.ResizeGripHovered]      = imvec4(0.44f, 0.44f, 0.44f, 0.29f)
  colors[ImGuiCol.ResizeGripActive]       = imvec4(0.40f, 0.44f, 0.47f, 1.00f)
  colors[ImGuiCol.Tab]                    = imvec4(0.00f, 0.00f, 0.00f, 0.52f)
  colors[ImGuiCol.TabHovered]             = imvec4(0.14f, 0.14f, 0.14f, 1.00f)
  colors[ImGuiCol.TabActive]              = imvec4(0.20f, 0.20f, 0.20f, 0.36f)
  colors[ImGuiCol.TabUnfocused]           = imvec4(0.00f, 0.00f, 0.00f, 0.52f)
  colors[ImGuiCol.TabUnfocusedActive]     = imvec4(0.14f, 0.14f, 0.14f, 1.00f)
  colors[ImGuiCol.DockingPreview]         = imvec4(0.33f, 0.67f, 0.86f, 1.00f)
  colors[ImGuiCol.DockingEmptyBg]         = imvec4(1.00f, 0.00f, 0.00f, 1.00f)
  colors[ImGuiCol.PlotLines]              = imvec4(1.00f, 0.00f, 0.00f, 1.00f)
  colors[ImGuiCol.PlotLinesHovered]       = imvec4(1.00f, 0.00f, 0.00f, 1.00f)
  colors[ImGuiCol.PlotHistogram]          = imvec4(1.00f, 0.00f, 0.00f, 1.00f)
  colors[ImGuiCol.PlotHistogramHovered]   = imvec4(1.00f, 0.00f, 0.00f, 1.00f)
  colors[ImGuiCol.TableHeaderBg]          = imvec4(0.00f, 0.00f, 0.00f, 0.52f)
  colors[ImGuiCol.TableBorderStrong]      = imvec4(0.00f, 0.00f, 0.00f, 0.52f)
  colors[ImGuiCol.TableBorderLight]       = imvec4(0.28f, 0.28f, 0.28f, 0.29f)
  colors[ImGuiCol.TableRowBg]             = imvec4(0.00f, 0.00f, 0.00f, 0.00f)
  colors[ImGuiCol.TableRowBgAlt]          = imvec4(1.00f, 1.00f, 1.00f, 0.06f)
  colors[ImGuiCol.TextSelectedBg]         = imvec4(0.20f, 0.22f, 0.23f, 1.00f)
  colors[ImGuiCol.DragDropTarget]         = imvec4(0.33f, 0.67f, 0.86f, 1.00f)
  colors[ImGuiCol.NavHighlight]           = imvec4(1.00f, 0.00f, 0.00f, 1.00f)
  colors[ImGuiCol.NavWindowingHighlight]  = imvec4(1.00f, 0.00f, 0.00f, 0.70f)
  colors[ImGuiCol.NavWindowingDimBg]      = imvec4(1.00f, 0.00f, 0.00f, 0.20f)
  colors[ImGuiCol.ModalWindowDimBg]       = imvec4(1.00f, 0.00f, 0.00f, 0.35f)

  style.windowPadding                     = imvec2(8.00f, 8.00f)
  style.framePadding                      = imvec2(5.00f, 2.00f)
  style.cellPadding                       = imvec2(6.00f, 6.00f)
  style.itemSpacing                       = imvec2(6.00f, 6.00f)
  style.itemInnerSpacing                  = imvec2(6.00f, 6.00f)
  style.touchExtraPadding                 = imvec2(0.00f, 0.00f)
  style.indentSpacing                     = 25
  style.scrollbarSize                     = 15
  style.grabMinSize                       = 10
  style.windowBorderSize                  = 1
  style.childBorderSize                   = 1
  style.popupBorderSize                   = 1
  style.frameBorderSize                   = 1
  style.tabBorderSize                     = 1
  style.windowRounding                    = 7
  style.childRounding                     = 4
  style.frameRounding                     = 3
  style.popupRounding                     = 4
  style.scrollbarRounding                 = 9
  style.grabRounding                      = 3
  style.logSliderDeadzone                 = 4
  style.tabRounding                       = 4

proc igStyleColorsCherry*(dst: ptr ImGuiStyle = nil): void =
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