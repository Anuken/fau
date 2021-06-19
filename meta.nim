## macro utility

import macros


## asserts anything
func check*(node: NimNode, cond: bool,  message: string) =
  if cond:
    error(message, node)

## asserts length of node
func check*(node: NimNode, len: int, message: string = "") =
  check(node, node.len != len, message & "(lon != " & $len & ")")

## asserts kind of node
func check*(node: NimNode, kind: NimNodeKind, message: string = "") =
  check(node, node.kind != kind, message & "(kind != " & $kind & ")")   