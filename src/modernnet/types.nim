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
  strformat,     # Used for pretty error printing
  strutils,      # Used for basic text manipulation (`split` for idents)
  json,          # JSON hooks for UUIDs
  re             # Use this to validate identifiers via regex
]

import regex
import uuids

import "."/[
  exceptions # Imported so we can raise specific errors
]

const
  IdentifierNamespaceRegex = re2"[a-z0-9.-_]"
  IdentifierValueRegex = re2"[a-z0-9.-_/]"

type
  Identifier* = object
    ## An MC identifier.
    namespace*, value*: string

  PositionFormat* = enum
    ## An enum that allows for users to choose how a Position is encoded/decoded.
    XYZ = 0'u8, XZY

  Position* = object ## Stores a position to an entity within a world.
    pos: int64
    format: PositionFormat

proc `$`*(i: Identifier): string =
  ## Get an identifier as a string.
  return i.namespace & ":" & i.value

proc new*(_: typedesc[Identifier], identStr: string): Identifier =
  ## Constructs a minecraft identifier from a string
  var ident = identStr.split(':')

  case ident.len:
  of 1:
    result.namespace = "minecraft"
    result.value = ident[0]

  of 2:
    result.namespace = ident[0]
    result.value = ident[1]

    if not match(result.namespace, IdentifierNamespaceRegex):
      raise newException(MnInvalidIdentifierError,
        fmt"`{identStr}` is not a valid identifier and contains an invalid character in the namespace!")

  else:
    raise newException(MnInvalidIdentifierError,
      fmt"`{identStr}` has too many colons, making it an invalid identifier!")

  if not match(result.value, IdentifierValueRegex):
    raise newException(MnInvalidIdentifierError,
      fmt"`{identStr}` is not a valid identifier and contains an invalid character in the value/key!")

func x*(pos: Position): int32 =
  ## Gets the X value of a position.
  (pos.pos shr 38).int32

func y*(pos: Position): int16 =
  ## Gets the Y value of a position.
  if pos.format == XZY:
    (pos.pos shl 52 shr 52).int16

  else:
    ((pos.pos shr 26) and 0xFFF).int16

func z*(pos: Position): int32 =
  ## Gets the Z value of a position.
  if pos.format == XZY:
    ((pos.pos shl 26).ashr 38).int32

  else:
    ((pos.pos shl 38) shr 38).int32

proc toPos*(val: int64, format = XZY): Position =
  ## Parses an int64 value to get the position, by default uses XZY,
  ## as that is what is used for modern MC versions (1.14+).
  Position(pos: val, format: format)

proc fromPos*(pos: Position, format = XZY): int64 =
  ## Returns an int64 from a `Position`, by default uses XZY,
  ## as that is what is used for modern MC versions (1.14+).
  if (pos.x > 67108863) or (pos.z > 67108863) or (pos.y > 4095):
    raise newException(MnInvalidPositionConstructionError,
      fmt"`{result}` is too large to be constructed!")

  if pos.format == format:
    return pos.pos

  elif format == XZY:
    return ((pos.x.int64 and 0x3FFFFFF) shl 38) or ((pos.z.int64 and 0x3FFFFFF) shl 12) or (pos.y.int64 and 0xFFF)

  elif format == XYZ:
    return ((pos.x.int64 and 0x3FFFFFF) shl 38) or ((pos.y.int64 and 0xFFF) shl 26) or (pos.z.int64 and 0x3FFFFFF)

  else:
    raise newException(MnInvalidPositionConstructionError, "How did you *get* here?")

func fromJsonHook*(uuid: var UUID, node: JsonNode) =
  ## Converts a UUID from JSON.
  uuid = node.getStr().parseUUID()

func toJsonHook*(uuid: UUID): JsonNode =
  ## Converts a UUID to JSON.
  newJString($uuid)

export UUID, parseUUID, uuids.`$`, mostSigBits, leastSigBits, initUUID