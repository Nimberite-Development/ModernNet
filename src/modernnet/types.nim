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
  re             # Use this to validate identifiers via regex
]

import regex

import "."/[
  exceptions # Imported so we can raise specific errors
]

const
  IDENTIFIER_NAMESPACE_REGEX = re"[a-z0-9.-_]"
  IDENTIFIER_VALUE_REGEX = "[a-z0-9.-_/]"

type
  Identifier* = object
    namespace*, value*: string

  Position* = object ## Stores a position to anything in a world, 
    x*, z*: int32
    y*: int16

proc `$`*(i: Identifier): string =
  ## A simple proc to get the serialised identifier as a string
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

    if not match(result.namespace, IDENTIFIER_NAMESPACE_REGEX):
      raise newException(MnInvalidIdentifierError,
        fmt"`{identStr}` is not a valid identifier and contains an invalid character in the namespace!")

  else:
    raise newException(MnInvalidIdentifierError,
      fmt"`{identStr}` has too many colons, making it an invalid identifier!")

  if not match(result.value, IDENTIFIER_VALUE_REGEX):
    raise newException(MnInvalidIdentifierError,
      fmt"`{identStr}` is not a valid identifier and contains an invalid character in the value/key!")


proc toPos*(val: int64): Position =
  ## Parses an int64 value to get the position
  result.x = (val shr 38).int32
  result.y = (val shl 52 shr 52).int16
  result.z = (val shl 26 shr 38).int32

  if (result.x > 67108863) or (result.z > 67108863) or (result.y > 4095):
    raise newException(MnInvalidIncomingPositionError,
      fmt"`{result}` is too big to be used as a valid position!")

proc fromPos*(pos: Position): int64 =
  ## Returns a serialised position object
  if (pos.x > 67108863) or (pos.z > 67108863) or (pos.y > 4095):
    raise newException(MnInvalidOutgoingPositionError,
      fmt"`{result}` is too large to be constructed!")

  return ((pos.x and 0x3FFFFFF) shl 38) or ((pos.z and 0x3FFFFFF) shl 12) or (pos.y and 0xFFF)
