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
  json # Used for building the server list response
]

type
  PlayerSample* = object ## Used for creating the server list sample
    name*, id*: string


proc buildServerListJson*(versionName: string, versionProtocol, maxPlayers, onlinePlayers: int,
  sample: seq[PlayerSample], description: string): JsonNode =
  ## Creates a status JSON response for Java Edition servers
  result = %*{
    "version": {
      "name": versionName,
      "protocol": versionProtocol
    },
    "players": {
      "max": maxPlayers,
      "online": onlinePlayers,
      "sample": sample
    },
    "description": {
      "text": description
    }
  }

export json