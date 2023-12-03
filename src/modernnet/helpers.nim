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

import "."/[
  exceptions,
  types
]

type
  PlayerSample* = object ## Used for creating the server list sample
    name*: string
    id*: UUID

func `%`(uuid: UUID): JsonNode = `%` $uuid

func buildServerListJson*(versionName: string, versionProtocol,
  maxPlayers, onlinePlayers: int, sample: seq[PlayerSample] = newSeq[PlayerSample](0),
  description: string = "", ext: JsonNode = nil): JsonNode =
  ## Creates a status JSON response for Java Edition servers.
  ##
  ## The `description` field is a Chat object, but is not currently handled as such.
  ##
  ## The `ext` field is an optional field used for passing other fields not specified,
  ## such as `modinfo` for Forge clients.
  runnableExamples:
    import modernnet

    let sample = @[PlayerSample(name: "VeryRealPlayer",
      id: "7f81c9a5-4aae-4ace-abd2-1586392441de".parseUUID())]
    
    let serverList = buildServerListJson("1.19.4", 762, 100,
      sample.len, sample, "Much wow")

    echo $serverList

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

  if ext != nil:
    if ext.kind != JObject:
      raise newException(MnInvalidJsonError, "Expected a JSON object!")

    for key, value in ext.pairs:
      result[key] = value

export json