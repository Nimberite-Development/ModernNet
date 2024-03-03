#! Copyright 2024 Yu-Vitaqua-fer-Chronos
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

import ./[
  exceptions,
  buffer
]
import ./private/[
  constants,
  utils
]

using receive_bytes: proc(_: int): seq[byte]

proc read[R: SizedNum](_: typedesc[R], receive_bytes): R =
  ## Reads any numeric type or boolean from the callback
  let bytes = receive_bytes(sizeof(R))
  bytes.extract(R)

proc readVar[R: int32 | int64](_: typedesc[R], receive_bytes): R =
  ## Reads a VarInt or a VarLong from the callback
  var
    position: int8 = 0
    currentByte: int8

  while true:
    currentByte = read(int8, receive_bytes)
    result = result or ((currentByte.R and SegmentBits) shl position)

    if (currentByte and ContinueBit) == 0:
      break

    position += 7

    when R is int32:
      if position >= VarIntBits:
        raise newException(MnPacketParsingError, "VarInt is too big!")

    elif R is int64:
      if position >= VarLongBits:
        raise newException(MnPacketParsingError, "VarLong is too big!")

    else:
      {.error: "Deserialisation of `" & $R & "` is not implemented!".}

proc readRawPacket*(receive_bytes): (int, Buffer) =
  let packetId = readVar(int32, receive_bytes)
  let length = readVar(int32, receive_bytes)

  return (packetId.int, newBuffer(receive_bytes(length)))