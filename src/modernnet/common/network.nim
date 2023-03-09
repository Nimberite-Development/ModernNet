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
  streams,       # Use this to decode and encode data for encoding and decoding packets
  endians,       # Since Minecraft stores most data types as big endians, we need to swap endianness
]

when defined(nbPlugin):
  import dynlib                   # Export this since we need to expose the send proc
  import std/asyncnet except send # Used for the networking and exclude the send proc for shared library shenannigans

else:
  import std/asyncnet # Used for the networking

import "."/[
  exceptions, # Used for raising errors
  constants   # Used for unchanging values
]


#[ Nim doesn't exactly like using networking from a shared library, so there's a workaround here, but it needs ]#
#[ to be explicitly used ]#
when defined(nbPlugin):
  type
    SetSendProcs* = proc(sBf: SendBuffer, sSt: SendString) {.nimcall.}
    SendBuffer* = proc(socket: AsyncSocket, buf: pointer, size: int, flags = {SafeDisconn}) {.nimcall, async.}
    SendString* = proc(socket: AsyncSocket, data: string, flags = {SafeDisconn}) {.nimcall, async.}

  var
    sendBuf: SendBuffer
    sendStr: SendString

  proc setSendProcs(sBf: SendBuffer, sSt: SendString) {.exportc, dynlib.} =
    sendBuf = sBf
    sendStr = sSt

  template send(socket: AsyncSocket, buf: pointer, size: int, flags = {SafeDisconn}): Future[void] =
    socket.sendBuf(buf, size, flags)

  template send(socket: AsyncSocket, data: string, flags = {SafeDisconn}): Future[void] =
    socket.sendStr(data, flags)


#[ Networking specific procs for serialising and deserialising, not all are implemented here as ]#
#[ the stream-oriented API is preferred ]#
proc writeNum*[R: SomeNumber | bool](s: AsyncSocket, value: R) {.async.} =
  ## Sends a boolean or any numeric primitive type to a socket
  var val = value
  var data: R

  case R.sizeof

  of 2:
    bigEndian16(addr data, addr val)

  of 4:
    bigEndian32(addr data, addr val)

  of 8:
    bigEndian64(addr data, addr val)

  else:
    data = val

  await s.send(addr data, data.sizeof)


proc writeVarNum*[R: int32 | int64](s: AsyncSocket, num: R) {.async.} =
  ## Writes a VarInt or a VarLong to a stream
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
  ## Writes all data from a stream to a socket
  strm.setPosition(0)
  let data = strm.readAll()

  await s.writeVarNum[:int32](data.len.int32)
  await s.send(data)


proc readVarInt*(s: AsyncSocket): Future[int32] {.async.} =
  ## Reads a VarInt from the socket
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
  ## Reads a VarLong from the socket
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


proc read*(s: AsyncSocket, buf: Stream, size: int) {.async.} =
  ## Reads data from a stream using an existing stream
  var data = await s.recv(size)

  if data == "":
    raise newException(MnConnectionClosedError, "Connection closed!")

  buf.write(data)


proc read*(s: AsyncSocket, size: int): Future[Stream] {.async.} =
  ## Reads data from a stream and returns a stream
  result = newStringStream()

  var data = await s.recv(size)

  if data == "":
    raise newException(MnConnectionClosedError, "Connection closed!")

  result = newStringStream(data)