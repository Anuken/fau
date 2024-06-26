
import polymorph, ../../core, ../g2/imgui, ../util/entityedit, ../assets, ../util/animation

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
    EmptyComponent = object
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
      aPatch: Patch
      animation: Animation

makeSystem "move", [Pos, Vel]:
  all:
    pos.x += vel.x
    pos.y += vel.y

makeSystem "draw", [Pos, VariousProperties]:
  all:
    draw(variousProperties.aPatch, pos.vec2, vec2(14f), color = variousProperties.someColor)

makeEcsCommit "runSystems"

proc init() =
  assetFolder = "res"
  imguiInitFau(theme = themeMaterialFlat, appName = "imguiTest", font = "Ubuntu-Light.ttf")

  for i in 0..<3:
    discard newEntityWith(
      EmptyComponent(),
      Pos(x: i * 20f, y: 0),
      Vel(x: 0, y: 0),
      VariousProperties(aPatch: "error".patch, animation: Animation())
    )

proc run() =
  fau.cam.use()

  runSystems()
  
  if keyEscape.tapped:
    quitApp()

  igShowDemoWindow()

  showEntityEditor()


initFau(run, init, initParams(title = "Entity Edit Test"))