type Bitset* = object
  bits: seq[int64]
  len: int

proc `[]`*(b: Bitset, i: int): bool = (b.bits[i shr 6] and (1'i64 shl i)).bool

proc `[]=`*(b: var Bitset, i: int, value: bool) =
  var w = addr b.bits[i shr 6]

  if value: w[] = w[] or (1'i64 shl (i and 63))
  else: w[] = w[] and not (1'i64 shl (i and 63))

proc len*(b: Bitset): int {.inline.} = b.len

proc clear*(b: var Bitset) =
  zeroMem(addr b.bits[0], 8 * b.bits.len)

proc newBitset*(n: int, b: bool = false): Bitset =
  ## New bit packed booleean array, initialized to b bool value
  result = Bitset(len: n, bits: newSeq[int64](max(n shl 6, 1)))
  if b:
    for i in 0..n:
      result[i] = true
