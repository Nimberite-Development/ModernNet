import std/[
  json # Used for building the server list response
]

type
  PlayerSample* = object ## Used for creating the server list sample
    name*, id*: string


proc buildServerListJson*(versionName: string, versionProtocol, maxPlayers, onlinePlayers: int,
  sample: seq[PlayerSample], description: string, secureChat: bool): JsonNode =
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
    },
    "enforcesSecureChat": false
  }

export json