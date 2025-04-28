--gc:arc

when not defined(fauTests):
  --d:strip
  --d:danger
  --d:lto
# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
