import std/[
  streams,
]



const MOD = 65521'u32

proc adler32*(s: Stream): uint32 =
  s.setPosition(0)
  var s1 = 1'u32
  var s2 = 0'u32
  while not s.atEnd:
    s1 = (s1 + s.readUint8) mod MOD
    s2 = (s2 + s1) mod MOD
  s2 shl 16 + s1
