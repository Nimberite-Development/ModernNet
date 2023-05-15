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
  streams, # Use this to decode and encode data for encoding and decoding packets
]

import ".."/[
  exceptions, # Used for errors such as `MnPacketConstructionError`
  constants,  # Used for unchanging values
  types       # Used for storing more complicated data types easily
]

import "."/[
  common # Used for any common code between the modules
]

proc readNum*[R: SomeNumber | bool](s: Stream): R =
  ## Reads a boolean or any numeric primitive type from a stream
  s.read(result)

  return result.fromBigEndian


proc readVarNum*[R: int32 | int64](s: Stream): R =
  ## Reads a VarInt or a VarLong from a stream
  var
    position: int8 = 0
    currentByte: uint8

  while true:
    currentByte = s.readNum[:uint8]()
    when R is int32:
      result = result or ((currentByte.int32 and SEGMENT_BITS) shl position)
    when R is int64:
      result = result or ((currentByte.int64 and SEGMENT_BITS) shl position)

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    if position >= (8 * R.sizeof):
      raise newException(MnPacketParsingError, "VarNum is too big!")


proc readString*(s: Stream): string =
  ## Reads a string from a stream
  var length = s.readVarNum[:int32]() # Length is implicitly checked
    # only allowing a value of at maximum 32767

  s.readStr(length, result)


template readIdentifier*(s: Stream): Identifier =
  ## Reads an Identifier from the stream
  identifier(s.decodeString())


template readPosition*[T: Position](s: Stream): Position =
  ## Reads a Position from a stream
  return fromPos(s.readNum[:int64]())