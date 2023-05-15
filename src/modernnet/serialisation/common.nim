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

import std/[
  endians # Used for swapping endians, as Minecraft requires data to be sent in BE over network typically
]

when cpuEndian == bigEndian:
  template toBigEndian*(num: SomeNumber): SomeNumber = num
  template fromBigEndian*(num: SomeNumber): SomeNumber = num

else:
  proc fromBigEndian*[T: uint8 | int8](num: T): T = num
  proc fromBigEndian*[T: uint16 | int16](num: T): T = swapEndian16(addr result, unsafeAddr num)
  proc fromBigEndian*[T: uint32 | int32](num: T): T = swapEndian32(addr result, unsafeAddr num)
  proc fromBigEndian*[T: uint64 | int64](num: T): T = swapEndian64(addr result, unsafeAddr num)

  proc toBigEndian*[T: uint8 | int8](num: T): T = num
  proc toBigEndian*[T: uint16 | int16](num: T): T = swapEndian16(addr result, unsafeAddr num)
  proc toBigEndian*[T: uint32 | int32](num: T): T = swapEndian32(addr result, unsafeAddr num)
  proc toBigEndian*[T: uint64 | int64](num: T): T = swapEndian64(addr result, unsafeAddr num)