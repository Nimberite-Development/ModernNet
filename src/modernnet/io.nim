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

import std/options

import "."/[
  exceptions,
  buffer
]
import ./private/[
  constants
]

type
  Result*[T, E] = object
    case isOk*: bool
    of true:
      when T isnot void:
        ok*: T

    of false:
      when E isnot void:
        err*: E

  RawPacket* = object
    id*: int
    buf*: Buffer


func readVar*[R: int32 | int64](data: openArray[byte]): Result[tuple[num: R, bytesRead: int], int] =
  ## Reads a VarInt or a VarLong from the given byte sequence
  result = typeof(result)(isOk: false, err: 0)

  var
    pos = 0
    res: R
    position: int8
    currentByte: byte

  while true:
    if pos >= data.len:
      result.err = pos + 1
      return

    currentByte = data[pos]
    res = res or ((currentByte.R and SegmentBits) shl position)

    pos += 1

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

  return typeof(result)(isOk: true, ok: (res, pos))


func readRawPacket*(data: openArray[byte]): Result[tuple[packet: RawPacket, bytesRead: int], int] =
  ## Reads a packet from the given byte sequence and returns a `RawPacket` that has the ID and the buffer.
  ## Returns an error if the packet is too short.
  let length = data.readVar[:int32]()

  if not length.isOk:
    # Returns how many bytes we need to continue.
    return typeof(result)(isOk: false, err: length.err)

  if data.len < length.ok.num - length.ok.bytesRead:
    # Returns how many bytes that we expect, based on the given length.
    return typeof(result)(isOk: false, err: length.ok.num + length.ok.bytesRead - data.len)

  let id = data[length.ok.bytesRead..^1].readVar[:int32]()

  if not id.isOk:
    return typeof(result)(isOk: false, err: id.err)

  typeof(result)(isOk: true, ok: (
    RawPacket(id: id.ok.num, buf: newBuffer(data[(length.ok.bytesRead + id.ok.bytesRead)..^1])),
    length.ok.bytesRead + length.ok.num
  ))