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

  assert buffer.readNum[:int8]() == a, "int8 test failed!"
  assert buffer.readNum[:int16]() == b, "int16 test failed!"
  assert buffer.readNum[:int32]() == c, "int32 test failed!"
  assert buffer.readNum[:int64]() == d, "int64 test failed!"
  assert buffer.readNum[:uint8]() == e, "uint8 test failed!"
  assert buffer.readNum[:uint64]() == f, "uint64 test failed!"
  assert buffer.readNum[:bool]() == g, "bool test (true) failed!"
  assert buffer.readNum[:bool]() == h, "bool test (false) failed!"

test "VarNum tests":
  var
    a: int32 = high(int32)
    b: int32 = high(int16)
    c: int64 = high(int64)
    d: int64 = high(int32)

  var buffer = newBuffer()

  buffer.writeVarNum(a)
  buffer.writeVarNum(b)
  buffer.writeVarNum(c)
  buffer.writeVarNum(d)

  buffer.pos = 0

  assert buffer.readVarNum[:int32]() == a, "VarInt test 1 failed!"
  assert buffer.readVarNum[:int32]() == b, "VarInt test 2 failed!"
  assert buffer.readVarNum[:int64]() == c, "VarLong test 1 failed!"
  assert buffer.readVarNum[:int64]() == d, "VarLong test 2 failed!"

test "String parsing":
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