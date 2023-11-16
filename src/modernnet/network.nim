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
  asyncnet,      # Used for the networking
  streams,       # Use this to decode and encode data for encoding and decoding packets
  net
]

import "."/[
  exceptions, # Used for raising errors
  constants,  # Used for unchanging values
  buffer      # Used for encoding and decoding
]

#[ Networking specific procs for serialising and deserialising, not all are implemented here as ]#
#[ the stream-oriented API is preferred ]#
proc write*(s: AsyncSocket | Socket, b: Buffer) {.multisync.} =
  ## Writes all data from a buffer to a socket.
  var buf = newBuffer()
  buf.writeVarNum[:int32](b.buf.len.int32)
  await s.send(cast[string](buf.buf & b.buf))


proc readVarNum*[R: int32 | int64](s: AsyncSocket | Socket): Future[R] {.multisync.} =
  ## Reads a VarInt or VarLong from a socket.
  var
    position: int8 = 0
    currentByte: int8

  while true:
    when s is AsyncSocket:
      discard await s.recvInto(addr currentByte, 1)
    else:
      discard s.recv(addr currentByte, 1)

    result = result or ((currentByte.R and SEGMENT_BITS) shl position)

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    when R is int32:
      if position >= VarIntBits:
        raise newException(MnPacketParsingError, "VarInt is too big!")

    elif R is int64:
      if position >= VarIntBits:
        raise newException(MnPacketParsingError, "VarLong is too big!")

    else:
      {.error: "Achievement Made: How did we get here?".}


proc readVarInt*(s: AsyncSocket | Socket): Future[int32] {.multisync, deprecated: "Use `readVarNum` instead".} =
  ## Reads a VarInt from a socket.
  await s.readVarNum[:int32]()


proc readVarLong*(s: AsyncSocket | Socket): Future[int64] {.multisync, deprecated: "Use `readVarNum` instead".} =
  ## Reads a VarLong from a socket.
  await s.readVarNum[:int64]()


proc read*(s: AsyncSocket | Socket, size: int): Future[Buffer] {.multisync.} =
  ## Reads data from a socket and returns a stream.
  newBuffer(cast[seq[byte]](await s.recv(size)))