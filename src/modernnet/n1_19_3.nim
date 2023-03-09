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
  asyncdispatch, # Used for asynchronous code
  asyncnet,      # Used for networking
  streams,       # Used for writing packets
  dynlib         # Needed for importing procs from another plugin
]

import nimberite/api/[
  pluginmanager, # Used for managing plugins
  interfaces     # Used for the NbPlugin
]

import ../modernnet     # Needed for packet handling
import ./common/helpers # Used for easy serverlist creation

when not defined(nbPlugin): # Small stub just for development
  type
    SendBuffer* = proc(socket: AsyncSocket, buf: pointer, size: int, flags = {SafeDisconn}) {.nimcall, async.}
    SendString* = proc(socket: AsyncSocket, data: string, flags = {SafeDisconn}) {.nimcall, async.}

  proc setSendProcs(sBf: SendBuffer, sSt: SendString) {.exportc, dynlib.} = discard

proc plugin*(): NbPlugin {.dynlib, exportc.} = NbPlugin(
  name: "modernnet-1.19.3",
  displayname: "ModernNet 1.19.3",
  semver: (0, 1, 0),
  requires: @["modernnet-core"],
  description: "A plugin implementing the Minecraft 1.19.3 protocol",
  reloadable: true, # Could probably be true
  async: true
)

const
  PROTOCOL_NAME: string = "1.19.3"
  PROTOCOL_VERSION: int32 = 761

if not defined(nbPlugin):
  quit("'modernnet-1.19.3' wasn't compiled with `nbPlugin`!", 1)

var modernnetPlugin: NbPlugin


proc initHandshake*(srv: NbServer, s: AsyncSocket, servAddr: string, port: uint16,
  nextState: int32) {.async.} =
  template pingPacket(strm: Stream) =
    let payload = strm.readNum[:int64]()

    var resp = newStringStream()

    resp.writeVarNum[:int32](1)

    resp.writeNum[:int64](payload)

    s.close()

  echo "I'm alive for now"

  if nextState == 1:
    var
      length: int
      strm: Stream
      packetId: int32

    try:
      length = await s.readVarInt()
      strm = await s.read(length)
      packetId = strm.readVarNum[:int32]()
    except MnConnectionClosedError:
      s.close()
      return

    echo "still alive!"

    if packetId == 0:
      var status = $buildServerListJson(PROTOCOL_NAME, PROTOCOL_VERSION, 10, 0, newSeq[PlayerSample](0),
        "Hello world!", false)

      var
        resp = newStringStream()

      resp.writeVarNum[:int32](0) # The packet ID
      resp.writeString(status)

      await s.write(resp)
      await sleepAsync(1000)

      try:
        length = await s.readVarInt()
        strm = await s.read(length)
        packetId = strm.readVarNum[:int32]()

      except MnConnectionClosedError:
        echo "We died for some reason"
        s.close()
        return

      pingPacket(strm)

    if packetId == 1:
      pingPacket(strm)


proc setup(plugin: NbPlugin) {.async, exportc, dynlib.} =
  modernnetPlugin = plugin.server.requestPlugin("modernnet-core")

  let setSendProcs = cast[SetSendProcs](modernnetPlugin.libhandle.symAddr("setSendProcs"))

  setSendProcs(
    cast[SendBuffer](modernnetPlugin.libhandle.symAddr("sendBuf")),
    cast[SendString](modernnetPlugin.libhandle.symAddr("sendStr"))
  )


proc teardown(plugin: NbPlugin) {.async, exportc, dynlib.} =
  modernnetPlugin = nil


proc enable(plugin: NbPlugin) {.async, exportc, dynlib.} = discard
proc disable(plugin: NbPlugin) {.async, exportc, dynlib.} = discard