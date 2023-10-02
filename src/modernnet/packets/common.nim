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
  streams
]

import ".."/serialisation

type Packet* = ref object of RootObj
  ## Base packet type that's inherited from
  id: int32
  data: seq[byte]

proc new*(_: typedesc[Packet], id: int32, data: seq[byte]): Packet = Packet(id: id, data: data)
proc new*(_: typedesc[Packet], strm: Stream): Packet = Packet(id: strm.readVarNum[:int32](),
  data: cast[seq[byte]](strm.readAll()))