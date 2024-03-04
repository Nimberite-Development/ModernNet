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

type
  RawPacket* = object
    id*: int
    buf*: Buffer

  MnIoResult*[T] = object
    case isOk*: bool
    of true:
      ok*: T ## The value if the call was successful
    of false:
      err*: int ## How many bytes are needed to complete the call

proc read[R: SizedNum](_: typedesc[R], data: openArray[byte]): (MnIoResult[R], int) =
  ## Reads any numeric type or boolean from the provided bytes
  if data.len > sizeof(R):
    return (MnIoResult[R](isOk: false, err: data.len - sizeof(R)), 0)

  if data.len < sizeof(R):
    return (MnIoResult[R](isOk: false, err: sizeof(R) - data.len), 0)

  (MnIoResult[R](isOk: true, ok: data.extract(R)), sizeof(R))

proc readVar[R: int32 | int64](_: typedesc[R], data: openArray[byte]): (MnIoResult[R], int) =
  ## Reads a VarInt or a VarLong from the provided bytes
  var
    res: R = 0.R
    currentByte: MnIoResult[int8]
    position: int8 = 0

  while true:
    if data.len < position:
      return (MnIoResult[R](isOk: false, err: data.len - position + 1), 0)

    currentByte = read(int8, data)[0]

    if not currentByte.isOk:
      return (MnIoResult[R](isOk: false, err: currentByte.err), 0)

    res = res or ((currentByte.ok.R and SegmentBits) shl position)

    if (currentByte.ok and ContinueBit) == 0:
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

  (MnIoResult[R](isOk: true, ok: res), (position / 7).int)

proc readRawPacket*(data: openArray[byte]): MnIoResult[RawPacket] =
  let id = readVar(int32, data)

  if not id[0].isOk:
    return MnIoResult[RawPacket](isOk: false, err: id[0].err)

  let length = readVar(int32, data.toOpenArray(id[1] + 1, data.len - 1))

  if not length[0].isOk:
    return MnIoResult[RawPacket](isOk: false, err: length[0].err)

  MnIoResult[RawPacket](isOk: true,
    ok: RawPacket(id: id[0].ok, buf: newBuffer(data.toOpenArray(id[1] + length[1], id[1] + length[1] + length[0].ok)))
  )