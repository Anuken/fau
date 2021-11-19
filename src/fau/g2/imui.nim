import ../draw, ../globals, ../color, ../patch, ../fmath, ../input, font, macros, hashes

# https://github.com/rxi/microui/blob/master/src/microui.h

type 
  Uid = int

type ClipResult = enum
  crNone,
  crPart,
  crAll

type LayoutType = enum
  ltNone,
  ltRelative,
  ltAbsolute

#TODO ref or not?
type Layout = ref object
  body, next: Rect
  pos, size, max: Vec2
  widths: seq[float32] #TODO replace with static array?
  items: int
  itemIndex: int
  nextType: LayoutType
  nextRow, indent: float32

#TODO pool containers so allocations don't happen?
type Container = ref object
  #TODO
  rect, body: Rect
  size, scroll: Vec2
  zindex: int #TODO float?

  #TODO this allocates, so it would be nice if it were just an enum of the container type instead... probably won't happen though
  drawProc: proc()

type Style = object
  size: Vec2
  padding, spacing, indent, titleHeight, scrollbarSize, thumbSize: float32
  #mu_Font font;
  #mu_Vec2 size;
  #mu_Color colors[MU_COLOR_MAX];

type Context = object
  style: Style

  hover, focus, lastId: Uid

  lastRect: Rect
  lastZindex: int
  updatedFocus: bool
  #frame: int #TODO remove? use fau state

  hoverRoot, nextHoverRoot, scrollTarget: Container
  numberEdit: Uid

  rootList: seq[Container]
  containerStack: seq[Container]
  clipStack: seq[Rect]
  idStack: seq[Uid]
  layoutStack: seq[Layout]


#globals
var context = Context()

# https://github.com/rxi/microui/blob/master/src/microui.c

proc beginUi() =
  context.rootList.setLen(0)
  context.scrollTarget = nil
  context.hoverRoot = context.nextHoverRoot
  context.nextHoverRoot = nil
  #is delta necessary, or can external input handle that?

proc endUi() =
  #TODO
  discard

proc setFocus(id: Uid) =
  context.focus = id
  context.updatedFocus = true

# Calculates ID of an element. This uses several data points:
# 1. previous ID in stack (if present)
# 2. some unique data (usually a string)
# 3. unique element ID based on callsite (is this necessary yet? investigate)

## IDs

proc getId[T](data: T, callsite = 0): Uid = 
  var hash = data.hash
  hash !& (if context.idStack.len == 0: 2166136261 else: context.idStack[^1])
  #TODO
  #hash !& callsite
  result = (!$hash).Uid
  context.lastId = result

proc pushId[T](data: T, callsite = 0) =
  context.idStack.add(getId(data, callsite))

proc popId() =
  discard context.idStack.pop()

## CLIPPING

proc getClipRect(): Rect = 
  if context.clipStack.len > 0: context.clipStack[^1] else: rect(vec2(0), fau.size)

proc pushClip(rect: Rect) =
  context.clipStack.add(getClipRect().intersect(rect))

proc popClip() = discard context.clipStack.pop()

proc checkClip(r: Rect): ClipResult =
  let cr = getClipRect()

  return if r.x > cr.x + cr.w or r.x + r.w < cr.x or r.y > cr.y + cr.h or r.y + r.h < cr.y: crAll
  elif r.x >= cr.x and r.x + r.w <= cr.x + cr.w and r.y >= cr.y and r.y + r.h <= cr.y + cr.h: crNone
  else: crPart


## LAYOUT

proc getLayout(): Layout = context.layoutStack[^1]

proc nextLayout(): Rect =
  let layout = getLayout()
  #TODO use context style
  let style = Style()

  if layout.nextType != ltNone:
    let ltype = layout.nextType
    layout.nextType = ltNone
    result = layout.next
    if ltype == ltAbsolute:
      context.lastRect = result
      return result
  else:
    if layout.itemIndex == layout.items:
      discard
      #TODO
      #layoutRow(layout.items, nil, layout.size.y)
    result.xy = layout.pos
    result.w = if layout.items > 0: layout.widths[layout.itemIndex] else: layout.size.x
    result.h = layout.size.y

    if result.w == 0f: result.w = style.size.x + style.padding * 2
    if result.h == 0f: result.h = style.size.y + style.padding * 2
    if result.w < 0: result.w += layout.body.w - result.x + 1
    if result.y < 0: result.h += layout.body.h - result.y + 1

    layout.itemIndex.inc
  
  layout.pos.x += result.w + style.spacing
  layout.nextRow = max(layout.nextRow, result.y + result.h + style.spacing)

  result.x += layout.body.x
  result.y += layout.body.y

  layout.max = vec2(max(layout.max.x, result.x2), max(layout.max.y, result.y2))

  context.lastRect = result

proc layoutEndColumn() =
  let b = getLayout()
  discard context.layoutStack.pop()
  let a = getLayout()

  a.pos.x = max(a.pos.x, b.pos.x + b.body.x - a.body.x)
  a.nextRow = max(a.nextRow, b.nextRow + b.body.y - a.body.y)
  a.max.x = max(a.max.x, b.max.x)
  a.max.y = max(a.max.y, b.max.y)

proc layoutRow(items: int, widths: openArray[float32], height: float32) =
  let layout = getLayout()

  #TODO can likely be optimized.
  if widths.len > 0:
    for i in 0..widths.len:
      layout.widths[i] = widths[i]
  
  layout.items = items
  layout.pos = vec2(layout.indent, layout.nextRow)
  layout.size.y = height
  layout.itemIndex = 0

#TODO better ways to write this
proc layoutWidth(width: float32) = getLayout().size.x = width

proc layoutHeight(height: float32) = getLayout().size.y = height

proc setNextLayout(r: Rect, relative: bool) =
  let layout = getLayout()
  layout.next = r
  layout.nextType = if relative: ltRelative else: ltAbsolute

proc pushLayout(body: Rect, scroll: Vec2) =
  let layout = Layout()
  layout.body = rect(body.x - scroll.x, body.y - scroll.y, body.w, body.h);
  #TODO what does this even mean?
  layout.max = vec2(-0x1000000, -0x1000000)
  context.layoutStack.add(layout)
  layoutRow(1, [0f], 0);

proc layoutBeginColumn() = pushLayout(nextLayout(), vec2(0, 0))

## CONTAINER

proc getCurrentContainer(): Container = context.containerStack[^1]

proc popContainer() =
  let cnt = getCurrentContainer()
  let layout = getLayout()
  cnt.size = layout.max - layout.body.xy

  discard context.containerStack.pop()
  discard context.layoutStack.pop()
  popId()

proc toFront(cont: Container) =
  cont.zIndex = context.lastZindex + 1
  context.lastZindex.inc

#TODO is memory pool stuff important?
proc getContainer(id: Uid): Container =
  result = Container()
  result.zIndex = context.lastZindex + 1
  result.toFront()

#TODO does not take into account callsite
proc getContainer[T](data: T) =
  let id = getId(data)
  return getContainer(id)


# so should I implement these?

#[
  void mu_draw_text(mu_Context *ctx, mu_Font font, const char *str, int len,
  mu_Vec2 pos, mu_Color color)
{
  mu_Command *cmd;
  mu_Rect rect = mu_rect(
    pos.x, pos.y, ctx->text_width(font, str, len), ctx->text_height(font));
  int clipped = mu_check_clip(ctx, rect);
  if (clipped == MU_CLIP_ALL ) { return; }
  if (clipped == MU_CLIP_PART) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
  /* add command */
  if (len < 0) { len = strlen(str); }
  cmd = mu_push_command(ctx, MU_COMMAND_TEXT, sizeof(mu_TextCommand) + len);
  memcpy(cmd->text.str, str, len);
  cmd->text.str[len] = '\0';
  cmd->text.pos = pos;
  cmd->text.color = color;
  cmd->text.font = font;
  /* reset clipping if it was set */
  if (clipped) { mu_set_clip(ctx, unclipped_rect); }
}


void mu_draw_icon(mu_Context *ctx, int id, mu_Rect rect, mu_Color color) {
  mu_Command *cmd;
  /* do clip command if the rect isn't fully contained within the cliprect */
  int clipped = mu_check_clip(ctx, rect);
  if (clipped == MU_CLIP_ALL ) { return; }
  if (clipped == MU_CLIP_PART) { mu_set_clip(ctx, mu_get_clip_rect(ctx)); }
  /* do icon command */
  cmd = mu_push_command(ctx, MU_COMMAND_ICON, sizeof(mu_IconCommand));
  cmd->icon.id = id;
  cmd->icon.rect = rect;
  cmd->icon.color = color;
  /* reset clipping if it was set */
  if (clipped) { mu_set_clip(ctx, unclipped_rect); }
}
]#

#[
  void mu_draw_rect(mu_Context *ctx, mu_Rect rect, mu_Color color) {
  mu_Command *cmd;
  rect = intersect_rects(rect, mu_get_clip_rect(ctx));
  if (rect.w > 0 && rect.h > 0) {
    cmd = mu_push_command(ctx, MU_COMMAND_RECT, sizeof(mu_RectCommand));
    cmd->rect.rect = rect;
    cmd->rect.color = color;
  }
}


void mu_draw_box(mu_Context *ctx, mu_Rect rect, mu_Color color) {
  mu_draw_rect(ctx, mu_rect(rect.x + 1, rect.y, rect.w - 2, 1), color);
  mu_draw_rect(ctx, mu_rect(rect.x + 1, rect.y + rect.h - 1, rect.w - 2, 1), color);
  mu_draw_rect(ctx, mu_rect(rect.x, rect.y, 1, rect.h), color);
  mu_draw_rect(ctx, mu_rect(rect.x + rect.w - 1, rect.y, 1, rect.h), color);
}

]#