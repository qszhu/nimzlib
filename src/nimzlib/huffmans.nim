import std/[
  tables,
]

import io/bitstreams



const MAX_CODE_LEN = 15

type
  Huffman* = ref object
    codeMapping: Table[int, int]

proc newHuffman*(codeLens: var seq[int]): Huffman =
  for l in codeLens: assert l >= 0 and l <= MAX_CODE_LEN

  var codeMapping = initTable[int, int]()
  var next = 0
  for cl in 1 .. MAX_CODE_LEN:
    next = next shl 1
    let start = 1 shl cl
    for s in 0 ..< codeLens.len:
      if codeLens[s] != cl: continue
      if next >= start: raise newException(ValueError, "Huffman over full")
      codeMapping[start or next] = s
      next += 1
  if next != 1 shl MAX_CODE_LEN: raise newException(ValueError, "Huffman under full")

  result.new
  result.codeMapping = codeMapping

proc decode*(self: Huffman, bs: BitStream): int =
  # TODO: tree lookup
  var c = 1
  while true:
    c = c shl 1 or bs.readInt(1)
    if c in self.codeMapping: return self.codeMapping[c]
