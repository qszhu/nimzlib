import std/[
  bitops,
  streams,
]

export streams



type
  BitStream* = ref object
    s: Stream
    curByte: uint8
    remainBits: int

proc newBitStream*(s: Stream): BitStream =
  result.new
  result.s = s

proc getBitPos*(self: BitStream): int =
  doAssert self.remainBits in 0 ..< 8
  (8 - self.remainBits) mod 8

proc readBit(self: BitStream): bool =
  if self.remainBits == 0:
    if self.s.atEnd: raise newException(IOError, "EOF")
    self.curByte = self.s.readUint8
    self.remainBits = 8
  self.remainBits -= 1
  self.curByte.testBit(7 - self.remainBits)

proc readInt*(self: BitStream, n: int): int =
  for i in 0 ..< n:
    if self.readBit:
      result = result or (1 shl i)
