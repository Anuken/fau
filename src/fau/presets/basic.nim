## basic components, such as position

import ../../ecs

register(defaultComponentOptions):
  type
    Pos* = object
      vec*: Vec2
    Timed* = object
      time*, lifetime*: float32

template makeTimedSystem*() =
  makeSystem("timed", [Timed]):
    all:
      item.timed.time += fau.delta
      if item.timed.time >= item.timed.lifetime:
        item.timed.time = item.timed.lifetime
        item.entity.delete()