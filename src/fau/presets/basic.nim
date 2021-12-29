## basic components, such as position

import ../../ecs

registerComponents(defaultComponentOptions):
  type
    Main* = object
    Pos* = object
      x*, y*: float32
    Timed* = object
      time*, lifetime*: float32

template makeTimedSystem*() =
  sys("timed", [Timed]):
    all:
      item.timed.time += fau.delta
      if item.timed.time >= item.timed.lifetime:
        item.timed.time = item.timed.lifetime
        item.entity.delete()