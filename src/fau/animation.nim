import atlas, patch, globals, math

type Animation* = object
  frames: seq[Patch]
  durations: seq[float32]
  delay: float32
  duration*: float32

proc frame*(anim: Animation, time = fau.time): Patch = 
  if anim.frames.len == 0: #you messed up
    fau.atlas.error
  elif anim.delay > 0f: #easy, optimized case - all frames same length, just divide to get it
    anim.frames[(time / anim.delay).int.mod(anim.frames.len)]
  else: #slow case: iterate through frames and find one based on duration
    let real = time mod anim.duration
    var counter = 0f
    for i in 0..<anim.frames.len:
      counter += anim.durations[i]
      if real < counter:
        return anim.frames[i]

    anim.frames[0]

proc `[]`*(anim: Animation, time = fau.time): Patch = anim.frame(time)

proc loadAnimation*(atlas: Atlas, name: string, delay = 0f): Animation =
  result.delay = delay
  var 
    i = 0
    lastDelay = -1
    allSame = true
  
  while atlas[name & $i].found:
    let delay = atlas.getDuration(name & $i)

    if lastDelay != -1 and lastDelay != delay:
      allSame = false

    result.frames.add(atlas[name & $i])
    result.duration += delay
    result.durations.add delay / 1000f
    lastDelay = delay
    i.inc
  
  #since it's in milliseconds...
  result.duration /= 1000f
  
  #all durations are the same
  if delay <= 0f and allSame:
    result.delay = lastDelay / 1000f

  if i == 0:
    result.frames.add(atlas[name])