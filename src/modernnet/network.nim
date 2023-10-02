#! Copyright 2023 Yu-Vitaqua-fer-Chronos
#!
#! Licensed under the Apache License, Version 2.0 (the "License");
#! you may not use this file except in compliance with the License.
#! You may obtain a copy of the License at
#!
#!     http://www.apache.org/licenses/LICENSE-2.0
#!
#! Unless required by applicable law or agreed to in writing, software
#! distributed under the License is distributed on an "AS IS" BASIS,
#! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#! See the License for the specific language governing permissions and
#! limitations under the License.

import std/[
  asyncdispatch, # Used for our asynchronous programming
  asyncnet, # Used for the networking
  streams,       # Use this to decode and encode data for encoding and decoding packets
]

import ./serialisation/common

import "."/[
  exceptions, # Used for raising errors
  constants   # Used for unchanging values
]

#[ Networking specific procs for serialising and deserialising, not all are implemented here as ]#
#[ the stream-oriented API is preferred ]#
proc writeNum*[R: SomeNumber | bool](s: AsyncSocket, value: R) {.async.} =
  ## Sends a boolean or any numeric primitive type to a socket.
  let val = value.toBigEndian

  await s.send(unsafeAddr val, val.sizeof)


proc writeVarNum*[R: int32 | int64](s: AsyncSocket, num: R) {.async.} =
  ## Writes a VarInt or a VarLong to a socket.
  when R is int32:
    var val: int32 = num

    while true:
      if (val and (not SEGMENT_BITS)) == 0:
        await s.writeNum(val.uint8)
        break

      await s.writeNum(cast[int8]((val and SEGMENT_BITS) or CONTINUE_BIT))
      val = val shr 7

  when R is int64:
    var val: int64 = num

    while true:
      if (val and (not SEGMENT_BITS)) == 0:
        await s.writeNum(val.uint8)
        break

      await s.writeNum(cast[int8]((val and SEGMENT_BITS) or CONTINUE_BIT))
      val = val shr 7


proc write*(s: AsyncSocket, strm: Stream) {.async.} =
  ## Writes all data from a stream to a socket.
  strm.setPosition(0)
  let data = strm.readAll()

  await s.writeVarNum[:int32](data.len.int32)
  await s.send(data)


proc readVarInt*(s: AsyncSocket): Future[int32] {.async.} =
  ## Reads a VarInt from a socket.
  var
    position: int8 = 0
    currentByte: int8

  while true:
    discard s.recvInto(addr currentByte, 1).await

    result = result or ((currentByte.int32 and SEGMENT_BITS) shl position)

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    if position >= 32:
      raise newException(MnPacketParsingError, "VarNum is too big!")


proc readVarLong*(s: AsyncSocket): Future[int64] {.async.} =
  ## Reads a VarLong from a socket.
  var
    position: int8 = 0
    currentByte: int8

  while true:
    discard s.recvInto(addr currentByte, 1).await

    result = result or ((currentByte.int64 and SEGMENT_BITS) shl position)

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    if position >= 64:
      raise newException(MnPacketParsingError, "VarNum is too big!")


proc read*(s: AsyncSocket, size: int): Future[Stream] {.async.} =
  ## Reads data from a socket and returns a stream.
  result = newStringStream()

  var data = await s.recv(size)

  if data == "":
    raise newException(MnConnectionClosedError, "Connection closed!")

  result = newStringStream(data)


proc read*(s: AsyncSocket, buf: var Stream, size: int) {.async.} =
  ## Reads data from a socket using an existing stream.
  var data = await s.recv(size)

  if data == "":
    raise newException(MnConnectionClosedError, "Connection closed!")

  buf.write(data)