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

import ./[
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

func readVar*[R: int32 | int64](data: openArray[byte], pos: var int): Result[R, int] =
  ## Reads a VarInt or a VarLong from the given byte sequence
  result = typeof(result)(isOk: false, err: 0)

  var
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

  return typeof(result)(isOk: true, ok: res)

func readRawPacket*(data: openArray[byte]): Result[tuple[packet: RawPacket, bytesRead: int], int] =
  var pos = 0
  let id = data.readVar[:int32](pos)

  if not id.isOk:
    return typeof(result)(isOk: false, err: id.err - data.len)

  let
    idPos = pos
    length = data.readVar[:int32](pos)

  if not length.isOk:
    return typeof(result)(isOk: false, err: length.err - data.len)

  if data.len < (pos + length.ok):
    return typeof(result)(isOk: false, err: (pos + length.ok) - data.len)

  return typeof(result)(isOk: true, ok: (RawPacket(id: id.ok, buf: newBuffer(data[idPos..<(pos + length.ok)])), pos + length.ok))