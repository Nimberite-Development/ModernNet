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

import ./stew/endians2

type SizedNum* = bool | byte | int8 | int16 | int32 | int64 | uint8 | uint16 | uint32 | uint64 | float32 | float64

template unsignedSize(T: typedesc): typedesc =
  when sizeof(T) == 1:
    uint8

  elif sizeof(T) == 2:
    uint16

  elif sizeof(T) == 4:
    uint32

  elif sizeof(T) == 8:
    uint64

  else:
    {.error: "Deserialisation of `" & $T & "` is not implemented!".}

func extract*[T: SizedNum](oa: openArray[byte], _: typedesc[T]): T {.raises: [ValueError].} =
  if oa.len < sizeof(T):
    raise newException(ValueError, "The buffer was to small to extract a " & $T & '!')

  elif oa.len > sizeof(T):
    raise newException(ValueError, "The buffer was to big to extract a " & $T & '!')

  cast[T](unsignedSize(T).fromBytesBE(oa.toOpenArray(0, sizeof(T) - 1)))

func deposit*[T: SizedNum](value: T, oa: var openArray[byte]) {.raises: [ValueError].} =
  if oa.len < sizeof(T):
    raise newException(ValueError, "The buffer was to small to deposit a " & $T & '!')

  let res = cast[unsignedSize(T)](value).toBytesBE()

  for i in 0..<sizeof(T):
    oa[i] = res[i]