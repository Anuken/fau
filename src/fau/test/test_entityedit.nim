
import polymorph, ../../core, ../g2/imgui, ../util/entityedit, ../assets

type 
  aNestedObject = object
    thing: int
    thing2: int
    str: string = "layer 3"
  aNestedObject2 = object
    thing: int
    thing2: int
    str: string = "layer 2"
    nest: aNestedObject
  aNestedObject3 = object
    thing: int
    thing2: int
    str: string = "layer 1"
    nest2: aNestedObject2

register defaultCompOpts:
  type
    Pos = object
      x, y: float32
    Vel = object
      x, y: float32
    VariousProperties = object
      str: string = "asdfgdfas"
      aVeryLongPropertyNameThatMightCauseProblems: int
      aVec2: Vec2
      aiVec2: Vec2i
      aRect: Rect
      someColor: Color = colorCoral
      abool: bool
      aint: int
      obj: aNestedObject3

makeSystem "move", [Pos, Vel]:
  all:
    pos.x += vel.x
    pos.y += vel.y

makeSystem "draw", [Pos, VariousProperties]:
  all:
    fillPoly(pos.vec2, 4, 10f, color = variousProperties.someColor)

makeEcsCommit "runSystems"

proc init() =
  assetFolder = "res"
  imguiInitFau(theme = themeMaterialFlat, appName = "imguiTest", font = "Ubuntu-Light.ttf")

  for i in 0..<3:
    discard newEntityWith(
      Pos(x: i * 20f, y: 0),
      Vel(x: 0, y: 0),
      VariousProperties()
    )

proc run() =
  fau.cam.use()

  runSystems()
  
  if keyEscape.tapped:
    quitApp()

  igShowDemoWindow()

  showEntityEditor()


initFau(run, init, initParams(title = "Entity Edit Test"))