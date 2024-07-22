# https://datatracker.ietf.org/doc/html/rfc1951
import std/[
  bitops,
]

import nimzlib/checksums/adlers
import nimzlib/io/[bitstreams, readers]
import nimzlib/inflates

export streams



proc inflate*(s: Stream): Stream =
  let cmf = s.readUint8
  let cm = cmf and 0xf
  let cinfo = cmf shr 4
  doAssert (cm, cinfo) == (8'u8, 7'u8)

  let flg = s.readUint8
  doAssert (cmf.uint16 shl 8 or flg) mod 31 == 0

  let fdict = flg.testBit(5)
  # let flevel = flg shr 6
  doAssert fdict == false

  let bs = newBitStream(s)
  let os = newInflator(bs).inflate
  doAssert os.adler32 == s.readUint32BE

  os.setPosition(0)
  os

type
  StreamInflator* = ref object
    inflator: Inflator

proc newStreamInflator*(s: Stream): StreamInflator =
  let cmf = s.readUint8
  let cm = cmf and 0xf
  let cinfo = cmf shr 4
  doAssert (cm, cinfo) == (8'u8, 7'u8)

  let flg = s.readUint8
  doAssert (cmf.uint16 shl 8 or flg) mod 31 == 0

  let fdict = flg.testBit(5)
  # let flevel = flg shr 6
  doAssert fdict == false

  let bs = newBitStream(s)
  result.new
  result.inflator = newInflator(bs)

proc inflate*(self: StreamInflator, sin: Stream = nil): Stream {.inline.} =
  result = self.inflator.inflate(sin)
  result.setPosition(0)

when isMainModule:
  let si = newStreamInflator(newFileStream("out1.zlib"))
  var data = si.inflate().readAll
  echo data.len

  data = si.inflate(newFileStream("out2.zlib")).readAll
  echo data.len
