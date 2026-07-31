## Unlike spawning.nim, this system handles handing off tasks to a thread pool and accepting the results on the main game loop thread.
## Just like spawning.nim, it is replaced with a dummy implementation when threads are off.

when compileOption("threads"):
  import std/[sequtils, isolation]
  import globals
  import pkg/taskpools
  
  export isolation
  
  #prevent memory usage from growing due to all the allocations in other threads - this may cause serious performance if malloc is called often in the task thread, so beware!
  when not defined(noThreadMallocTuning) and defined(Linux):
    proc mallopt(param: cint, value: cint): cint {.importc, header: "<malloc.h>".}
    discard mallopt(cint(-8), 1) #set M_ARENA_MAX (-8) to 1
  
  var
    taskPool = Taskpool.new()
    pollers: seq[proc(): bool]
    initialized: bool
  
  type
    AsyncBox[R] = ref object
      chan: Channel[R]
  
    TaskArgs[T, R] = object
      params: T
      chan: ptr Channel[(R, bool)]
      processor: proc(p: T): R {.nimcall, gcsafe.}
  
  proc taskJob[T, R](args: TaskArgs[T, R]) {.nimcall, gcsafe.} =
    try:
      args.chan[].send((args.processor(args.params), true))
    except Exception as e:
      echo "[Fau] Error executing async task: ", e.name, ": ", e.msg
      args.chan[].send((default(R), false))
  
  proc pollMainThreadTasks() =
    var i = 0
    while i < pollers.len:
      if pollers[i]():
        inc i
      else:
        pollers[i] = pollers[^1]
        pollers.setLen(pollers.len - 1)

  proc runAsync*[T, R](params: T, processor: proc(p: T): R {.nimcall, gcsafe.}, mainThreadRunner: proc(r: R)) =
    ## Runs a task in a separate thread, handling the result on the main thread.
    ## :params: Argument to the processor function.
    ## :processor: Function that does the actual long-running task.
    ## :mainThreadRunner: Function that handles the result on the main thread (e.g. uploading a texture)
    
    if not initialized:
      addFauListener do(ev: FauEvent):
        case ev.kind:
        of feFrame: pollMainThreadTasks()
        of feDestroy: taskPool.shutdown()
        else: discard
      initialized = true
    
    var box = AsyncBox[(R, bool)]()
    box.chan.open()
    let args = TaskArgs[T, R](params: params, chan: addr box.chan, processor: processor)
    taskPool.spawn taskJob(args)
    pollers.add(proc(): bool =
      let (ok, v) = box.chan.tryRecv()
      if ok:
        if v[1]: mainThreadRunner(v[0])
        box.chan.close()
        return false
      return true
    )
  
else:
  #non-threaded fallback functions (emscripten)
  
  proc runAsync*[T, R](params: T, processor: proc(p: T): R {.nimcall, gcsafe.}, mainThreadRunner: proc(r: R)) =
    mainThreadRunner(processor(params))