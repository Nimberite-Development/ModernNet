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

proc writeNum*[R: SomeNumber | bool](s: Stream, value: R) =
  ## Sends a boolean or any numeric primitive type to a stream
  s.write(value.toBytesBE)


proc writeVarNum*[R: int32 | int64](s: Stream, num: R) =
  ## Writes a VarInt or a VarLong to a stream
  when R is int32:
    var val: int32 = num

    while true:
      if (val and (not SEGMENT_BITS)) == 0:
        s.writeNum(val.uint8)
        break

      s.write(cast[int8]((val and SEGMENT_BITS) or CONTINUE_BIT))
      val = val shr 7

  when R is int64:
    var val: int64 = num

    while true:
      if (val and (not SEGMENT_BITS)) == 0:
        s.writeNum(val.uint8)
        break

      s.write(cast[int8]((val and SEGMENT_BITS) or CONTINUE_BIT))
      val = val shr 7


proc writeString*(s: Stream, val: string) =
  ## Writes a string to the socket
  let text = val

  if text.len > 32767:
    raise newException(MnPacketConstructionError, "The length of the provided string is too long!")

  s.writeVarNum[:int32](text.len.int32)
  s.write(text)


template writeIdentifier*(s: Stream, i: Identifier) =
  ## Writes an identifier to the stream
  s.write($i)


template writePosition*[T: Position](s: Stream, p: Position, format = XZY) =
  ## Writes a Position to a stream
  s.writeNum[:int64](toPos(p, format))