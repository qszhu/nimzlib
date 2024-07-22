import std/[
  endians,
  streams,
]

export streams



proc readBytes*(s: Stream, n: int): seq[uint8] =
  result = newSeq[uint8](n)
  for i in 0 ..< n: result[i] = s.readUint8

proc readUint32BE*(s: Stream): uint32 =
  var t = s.readUint32
  bigEndian32(addr(result), addr(t))

proc readUint8*(d: seq[uint8], o: var int): uint8 =
  result = d[o]
  o += 1

proc readUint32BE*(d: seq[uint8], o: var int): uint32 =
  result = d[o]
  result = result shl 8 or d[o + 1]
  result = result shl 8 or d[o + 2]
  result = result shl 8 or d[o + 3]
  o += 4

proc readStr*(d: seq[uint8], n: int, o: var int): string =
  result = newString(n)
  copyMem(result[0].addr, d[o].addr, n)
  o += n
