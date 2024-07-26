import std/[
  streams,
  net,
]



type
  InputStream* = ref object of RootObj

method atEnd*(self: InputStream): bool {.base.} = discard
method readUint8*(self: InputStream): uint8 {.base.} = discard
method readUint32BE*(self: InputStream): uint32 {.base.} = discard

type
  StreamInputStream* = ref object of InputStream
    s: Stream

proc newStreamInputStream*(s: Stream): StreamInputStream =
  result.new
  result.s = s

method atEnd*(self: StreamInputStream): bool =
  self.s.atEnd

method readUint8*(self: StreamInputStream): uint8 =
  self.s.readUint8

method readUint32BE*(self: StreamInputStream): uint32 =
  self.s.readUint32

type
  SocketInputStream* = ref object of InputStream
    s: Socket

proc newSocketInputStream*(s: Socket): SocketInputStream =
  result.new
  result.s = s

method atEnd*(self: SocketInputStream): bool =
  discard

method readUint8*(self: SocketInputStream): uint8 =
  self.s.recv(1)[0].uint8

method readUint32BE*(self: SocketInputStream): uint32 =
  for _ in 0 ..< 4:
    result = (result shl 8) or self.readUint8
