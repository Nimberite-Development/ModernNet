#! Copyright 2023 horizon
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

import ../private/stew/endians2

type
  UnsignedInts* = uint16 | uint32 | uint64
  SignedInts* = int16 | int32 | int64
  Floats* = float32 | float64
  SingleByte* = bool | byte | uint8 | int8

func toBytesBESigned[R: SignedInts](value: R): array[sizeof(R), byte] =
  when R is int16:
    cast[uint16](value).toBytesBE
  elif R is int32:
    cast[uint32](value).toBytesBE
  elif R is int64:
    cast[uint64](value).toBytesBE

func toBytesBEFloat[R: Floats](value: R): array[sizeof(R), byte] =
  when R is float32:
    cast[uint32](value).toBytesBE
  elif R is float64:
    cast[uint64](value).toBytesBE

func toBytesBESingle[R: SingleByte](value: R): array[1, byte] = [cast[byte](value)]

func toBytesBE*[R: UnsignedInts | SignedInts | Floats | SingleByte](value: R): array[sizeof(R), byte] =
  when R is UnsignedInts:
    endians2.toBytesBE(value)
  elif R is SignedInts:
    toBytesBESigned(value)
  elif R is Floats:
    toBytesBEFloat(value)
  elif R is SingleByte:
    toBytesBESingle(value)
  else:
    endians2.toBytesBE(value)


func fromBytesBE*[R: UnsignedInts | SignedInts | Floats | SingleByte](x: openArray[byte]): R =
  when sizeof(R) == 1:
    doAssert x.len >= sizeof(R), "Not enough bytes"
    return cast[R](x[0])

  elif sizeof(R) == 2:
    doAssert x.len >= sizeof(R), "Not enough bytes for endian conversion"
    return cast[R](endians2.fromBytesBE(uint16, x))

  elif sizeof(R) == 4:
    doAssert x.len >= sizeof(R), "Not enough bytes for endian conversion"
    return cast[R](endians2.fromBytesBE(uint32, x))

  elif sizeof(R) == 8:
    doAssert x.len >= sizeof(R), "Not enough bytes for endian conversion"
    return cast[R](endians2.fromBytesBE(uint64, x))

  else:
    {.error: "Advancement Made: How did we get here?".}