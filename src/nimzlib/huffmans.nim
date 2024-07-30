import std/[
  algorithm,
  tables,
]

import io/bitstreams



const MAX_CODE_LEN = 15

type
  BtNode = ref object
    hasVal: bool
    val: int
    child: array[2, BtNode]

proc set(self: BtNode, key, val: int) =
  var bits = newSeq[int]()
  var x = key
  while x != 0:
    bits.add(x and 1)
    x = x shr 1
  bits.reverse
  var n = self
  for b in bits:
    if n.child[b] == nil: n.child[b] = BtNode.new
    n = n.child[b]
  n.hasVal = true
  n.val = val



type
  Huffman* = ref object
    root: BtNode

proc newHuffman*(codeLens: var seq[int]): Huffman =
  for l in codeLens: assert l >= 0 and l <= MAX_CODE_LEN
  var root = BtNode.new

  var next = 0
  for cl in 1 .. MAX_CODE_LEN:
    next = next shl 1
    let start = 1 shl cl
    for s in 0 ..< codeLens.len:
      if codeLens[s] != cl: continue
      if next >= start: raise newException(ValueError, "Huffman over full")
      root.set(start or next, s)
      next += 1
  if next != 1 shl MAX_CODE_LEN: raise newException(ValueError, "Huffman under full")

  result.new
  result.root = root

proc decode*(self: Huffman, bs: BitStream): int =
  var n = self.root.child[1]
  while true:
    n = n.child[bs.readInt(1)]
    if n.hasVal: return n.val
