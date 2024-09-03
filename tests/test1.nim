# TODO: Implement these tests!

import std/[
  unittest # Used for creating test suites
]

import modernnet

test "`readNum` and `writeNum`":
  var
    a: int8 = high(int8)
    b: int16 = high(int16)
    c: int32 = high(int32)
    d: int64 = high(int64)
    e: uint8 = high(uint8) # logic behind these are the same so they should return the same value either way
    f: uint64 = high(uint64)
    g: bool = true
    h: bool = false

  var buffer = newBuffer()

  buffer.writeNum(a)
  buffer.writeNum(b)
  buffer.writeNum(c)
  buffer.writeNum(d)
  buffer.writeNum(e)
  buffer.writeNum(f)
  buffer.writeNum(g)
  buffer.writeNum(h)

  buffer.pos = 0

  check buffer.readNum[:int8]() == a
  check buffer.readNum[:int16]() == b
  check buffer.readNum[:int32]() == c
  check buffer.readNum[:int64]() == d
  check buffer.readNum[:uint8]() == e
  check buffer.readNum[:uint64]() == f
  check buffer.readNum[:bool]() == g
  check buffer.readNum[:bool]() == h

test "VarNum tests":
  var
    a: int32 = high(int32)
    b: int32 = high(int16)
    c: int64 = high(int64)
    d: int64 = high(int32)

  var buffer = newBuffer()

  buffer.writeVar(a)
  buffer.writeVar(b)
  buffer.writeVar(c)
  buffer.writeVar(d)

  buffer.pos = 0

  assert buffer.readVar[:int32]() == a, "VarInt test 1 failed!"
  assert buffer.readVar[:int32]() == b, "VarInt test 2 failed!"
  assert buffer.readVar[:int64]() == c, "VarLong test 1 failed!"
  assert buffer.readVar[:int64]() == d, "VarLong test 2 failed!"

test "UUID parsing/serialising":
  var buffer = newBuffer()

  var a = parseUUID("7f81c9a5-4aae-4ace-abd2-1586392441de")

  buffer.writeUUID(a)

  buffer.pos = 0

  assert buffer.readUUID() == a, "UUID test failed!"

test "String parsing/serialising":
  var buffer = newBuffer()

  var a = "Hello world!"

  buffer.writeString(a)

  buffer.pos = 0

  assert buffer.readString() == a, "String test failed!"

test "Position serialising and deserialising":
  const xzy = 0b01000110000001110110001100_10110000010101101101001000_001100111111
  const xyz = 0b01000110000001110110001100_001100111111_10110000010101101101001000

  let xzyPos = toPos(xzy, XZY)
  let xyzPos = toPos(xyz, XYZ)

  assert xzyPos.x == 18357644, "X coord failed (XZY)"
  assert xzyPos.y == 831, "Y coord failed (XZY)"
  assert xzyPos.z == -20882616, "Z coord failed (XZY)"

  assert xyzPos.x == 18357644, "X coord failed (XYZ)"
  assert xyzPos.y == 831, "Y coord failed (XYZ)"
  assert xyzPos.z == -20882616, "Z coord failed (XYZ)"

  assert fromPos(xzyPos, XZY) == xzy, "XZY position did not match!"
  assert fromPos(xzyPos, XYZ) == xyz, "XZY position did not match the XYZ when converted!"
  assert fromPos(xyzPos, XYZ) == xyz, "XYZ position did not match!"
  assert fromPos(xyzPos, XZY) == xzy, "XYZ position did not match the XZY when converted!"

test "IO read/write test":
  # Set up the buffer
  var buffer = newBuffer()

  # Packet size
  buffer.writeVar[:int32](9)
  # Packet ID
  buffer.writeVar[:int32](0x27)
  # Some data
  buffer.writeNum[:int64](23142)

  buffer.pos = 0

  # Commence tests~
  var b: seq[byte] # Pretend this is a buffered socket

  var
    res = readRawPacket(b)
    counter = 0

  while not res.isOk:
    inc counter

    for i in 0..<res.err: b.add(buffer.readNum[:byte]())

    if counter < 2:
      check res.err == 1
    else:
      check res.err == 9

    res = readRawPacket(b)

  # Check packet ID
  check res.ok.packet.id == 0x27

  # Use parsed buffer
  buffer = res.ok.packet.buf

  # Length should be omitted in parsed buffer.
  check buffer.readNum[:int64]() == 23142

  # Check if the total bytes read was also correct
  check res.ok.bytesRead == 10