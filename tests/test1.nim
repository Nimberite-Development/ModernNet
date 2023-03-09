# TODO: Implement these tests!

import std/[
  unittest, # Used for creating test suites
  streams   # Used for the stream API used by ModernNet
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

  var strm = newStringStream()

  strm.writeNum(a)
  strm.writeNum(b)
  strm.writeNum(c)
  strm.writeNum(d)
  strm.writeNum(e)
  strm.writeNum(f)
  strm.writeNum(g)
  strm.writeNum(h)

  strm.setPosition(0)

  assert strm.readNum[:int8]() == a, "int8 test failed!"
  assert strm.readNum[:int16]() == b, "int16 test failed!"
  assert strm.readNum[:int32]() == c, "int32 test failed!"
  assert strm.readNum[:int64]() == d, "int64 test failed!"
  assert strm.readNum[:uint8]() == e, "uint8 test failed!"
  assert strm.readNum[:uint64]() == f, "uint64 test failed!"
  assert strm.readNum[:bool]() == g, "bool test (true) failed!"
  assert strm.readNum[:bool]() == h, "bool test (false) failed!"

test "VarNum tests":
  var
    a: int32 = high(int32)
    b: int32 = high(int16)
    c: int64 = high(int64)
    d: int64 = high(int32)

  var strm = newStringStream()

  strm.writeVarNum(a)
  strm.writeVarNum(b)
  strm.writeVarNum(c)
  strm.writeVarNum(d)

  strm.setPosition(0)

  assert strm.readVarNum[:int32]() == a, "VarInt test 1 failed!"
  assert strm.readVarNum[:int32]() == b, "VarInt test 2 failed!"
  assert strm.readVarNum[:int64]() == c, "VarLong test 1 failed!"
  assert strm.readVarNum[:int64]() == d, "VarLong test 2 failed!"

test "String parsing":
  var strm = newStringStream()

  var a = "Hello world!"

  strm.writeString(a)

  strm.setPosition(0)

  assert strm.readString() == a, "String test failed!"