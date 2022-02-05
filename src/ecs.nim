import polymorph, core, strutils
export polymorph, core

# Wraps Polymorph with some utilities.
#TODO remove, this is no longer necessary - I'm not sure where to put it

macro whenComp*(entity: EntityRef, t: typedesc, body: untyped) =
  ## Runs the body with the specified lowerCase type when this entity has this component
  let varName = t.repr.toLowerAscii.ident
  result = quote do:
    if `entity`.alive:
      let `varName` {.inject.} = `entity`.fetch `t`
      if `varName`.valid:
        `body`

template launchFau*(title: string) =
  makeEcsCommit("run")
  initFau(run, windowTitle = `title`)