import polymorph, fusecore, strutils
export polymorph, fusecore

var definitions {.compileTime.}: seq[tuple[name: string, body: NimNode]]

#fires a new event
template fireEvent*[T](val: T) = discard newEntityWith(Event(), val)

#define system
macro sys*(name: static[string], componentTypes: openarray[typedesc], body: untyped): untyped =
  definitions.add (name, body)

  result = quote do:
    defineSystem(`name`, `componentTypes`, defaultSystemOptions)

#create system that listens to an event
macro onEvent*(T: typedesc, body: untyped) =

  let 
    line = body.lineInfoObj
    fname = line.filename.substr(line.filename.rfind('/') + 1)
    typeName = ident(($T)[0].toLowerAscii & ($T).substr(1))
    sysName = fname[0..^5] & $T & $line.line

  result = quote do:
    sys(`sysName`, [`T`]):
      all:
        let event {.inject.} = item.`typeName`
        `body`

registerComponents(defaultComponentOptions):
  type Event* = object

sys("clearEvents", [Event]):
  all:
    item.entity.delete()

macro launchFuse*(title: string, body: untyped) =

  result = newStmtList().add quote do:
    makeEcs()
    `body`
  
  for def in definitions:
    result.add newCall(
      ident("makeSystemBody"),
      newLit(def.name),
      def.body
    )
  
  result.add quote do:
    commitSystems("run")
    initFuse(run, windowTitle = `title`)
  