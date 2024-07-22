import std/[
  streams,
]



type
  Dict* = ref object
    data: seq[uint8]
    index, length: int

proc newDict*(size: int): Dict =
  result.new
  result.data = newSeq[uint8](size)

proc add*(self: Dict, b: uint8) =
  self.data[self.index] = b
  self.index = (self.index + 1) mod self.data.len
  if self.length < self.data.len:
    self.length += 1

proc copy*(self: Dict, dist, runLen: int, os: Stream) =
  assert runLen >= 0 and dist in 1 .. self.length

  var ri = (self.index - dist + self.data.len) mod self.data.len

  for i in 0 ..< runLen:
    let b = self.data[ri]
    ri = (ri + 1) mod self.data.len
    os.write(b)
    self.add(b)
