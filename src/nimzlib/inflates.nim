import std/[
  algorithm,
  streams,
]

import io/bitstreams
import dicts, huffmans



const NO_COMPRESSION = 0b00
const FIXED_HUFFMAN = 0b01
const DYNAMIC_HUFFMAN = 0b10

type
  Inflator* = ref object
    input: BitStream
    output: Stream
    dict: Dict

proc newInflator*(bs: BitStream): Inflator =
  result.new
  result.input = bs
  result.output = newStringStream()
  result.dict = newDict(32768)

proc inflateUncompressed(self: Inflator): bool {.gcsafe.}
proc readHuffmans(self: Inflator): (HuffMan, HuffMan) {.gcsafe.}
proc inflateHuffman(self: Inflator, litLenHuffMan, distHuffman: Huffman) {.gcsafe.}
proc inflate*(self: Inflator, sin: InputStream = nil): Stream =
  if sin != nil:
    self.input = newBitStream(sin)
    self.output = newStringStream()

  var lastBlock = false
  while not lastBlock:
    let bfinal = self.input.readInt(1)
    lastBlock = bfinal != 0

    let btype = self.input.readInt(2)
    # echo (btype, self.output.getPosition)
    case btype:
    of NO_COMPRESSION:
      lastBlock = self.inflateUncompressed
    of FIXED_HUFFMAN:
      raise newException(ValueError, "fixed huffman")
    of DYNAMIC_HUFFMAN:
      let (litLenHuffman, distHuffman) = self.readHuffmans
      self.inflateHuffman(litLenHuffman, distHuffman)
    else:
      raise newException(ValueError, "Invalid btype: " & $btype)
  self.output.setPosition(0)
  self.output

proc inflateUncompressed(self: Inflator): bool {.gcsafe.} =
  # TODO: optimize
  while self.input.getBitPos != 0: discard self.input.readInt(1)
  let l = self.input.readInt(16)
  let nl = self.input.readInt(16)
  doAssert (l xor 0xffff) == nl, "Invalid length in uncompressed block"
  if l == 0: return true

  for i in 0 ..< l:
    let b = self.input.readInt(8).uint8
    self.output.write(b)
    self.dict.add(b)

const CODE_LEN_FILL_ORDER = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]

proc readHuffmans(self: Inflator): (HuffMan, HuffMan) {.gcsafe.} =
  let hlit = self.input.readInt(5) + 257
  let hdist = self.input.readInt(5) + 1
  let hclen = self.input.readInt(4) + 4

  var codeLenCodeLens = newSeq[int](CODE_LEN_FILL_ORDER.len)
  for i in 0 ..< hclen:
    codeLenCodeLens[CODE_LEN_FILL_ORDER[i]] = self.input.readInt(3)

  let codeLenHuffman = newHuffman(codeLenCodeLens)

  var codeLens = newSeq[int](hlit + hdist)
  var ci = 0
  while ci < codeLens.len:
    let s = codeLenHuffman.decode(self.input)
    if s in 0 .. 15:
      codeLens[ci] = s
      ci += 1
    else:
      var runLen, runVal: int
      if s == 16:
        assert ci > 0
        runLen = self.input.readInt(2) + 3
        runVal = codeLens[ci - 1]
      elif s == 17:
        runLen = self.input.readInt(3) + 3
      elif s == 18:
        runLen = self.input.readInt(7) + 11
      else:
        raise newException(ValueError, "Symbol out of range")
      let cj = ci + runLen
      if cj > codeLens.len: raise newException(ValueError, "Index out of range")
      codeLens.fill(ci, cj - 1, runVal)
      ci = cj

  var litLenCodeLens = codeLens[0 ..< hlit]
  let litLenHuffman = newHuffman(litLenCodeLens)

  var distCodeLens = codeLens[hlit ..< codeLens.len]
  if distCodeLens == @[0]: return (litLenHuffMan, nil)

  var ones, others = 0
  for x in distCodeLens:
    if x == 1: ones += 1
    elif x > 1: others += 1
  if (ones, others) == (1, 0):
    while distCodeLens.len < 32: distCodeLens.add 0
    distCodeLens = distCodeLens[0 ..< 32]
    distCodeLens[^1] = 1
  let distHuffman = newHuffman(distCodeLens)
  (litLenHuffman, distHuffman)

proc readRunLength(self: Inflator, s: int): int {.gcsafe.}
proc readDistance(self: Inflator, s: int): int {.gcsafe.}
proc inflateHuffman(self: Inflator, litLenHuffMan, distHuffman: Huffman) {.gcsafe.} =
  while true:
    let s = litLenHuffman.decode(self.input)
    if s == 256: break
    if s < 256:
      self.output.write(s.uint8)
      self.dict.add(s.uint8)
    else:
      assert distHuffman != nil

      let runLen = self.readRunLength(s)
      assert runLen in 3 .. 258

      let dist = self.readDistance(distHuffman.decode(self.input))
      assert dist in 1 .. 32768

      self.dict.copy(dist, runLen, self.output)

proc readRunLength(self: Inflator, s: int): int {.gcsafe.} =
  assert s in 257 .. 287

  if s <= 264:
    return s - 254

  if s <= 284:
    let b = (s - 261) shr 2
    return ((((s - 265) and 0b11) + 4) shl b) + 3 + self.input.readInt(b)

  if s == 285:
    return 258

  raise newException(ValueError, "Reserved run length: " & $s)

proc readDistance(self: Inflator, s: int): int {.gcsafe.} =
  assert s in 0 .. 31

  if s <= 3:
    return s + 1

  if s <= 29:
    let b = (s shr 1) - 1
    return (((s and 1) + 2) shl b) + 1 + self.input.readInt(b)

  raise newException(ValueError, "Reserved distance: " & $s)
