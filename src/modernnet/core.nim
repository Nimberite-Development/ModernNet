#! Copyright 2022 Yu-Vitaqua-fer-Chronos
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
  tables,        # Used for registering and unregistering modern protocol support
  dynlib         # Used for exposing the API
]

# Since this is a plugin for Nimberite, we need to actually depend on Nimberite
import nimberite/api/interfaces

# Import the common modules used for parsing and handling packets
import ../modernnet

# Simple procedure that returns the plugin data
proc plugin*(): NbPlugin {.dynlib, exportc.} = NbPlugin(
  name: "modernnet-core",
  displayname: "ModernNet Core",
  semver: (0, 1, 0),
  description: "A plugin that acts as the manager/head of plugins implementing a modern MC version's protocol",
  reloadable: true,
  async: true
)

type
  HandshakeProc = proc(srv: NbPlugin, s: AsyncSocket, servAddr: string, port: uint16,
    nextState: int32) {.nimcall, async.}

# Used to keep track of supported protocol versions
var protocolPluginTable: TableRef[int32, NbPlugin]

proc registerProtocolPlugin*(version: int32, plug: NbPlugin) {.async, exportc, dynlib.} =
  ## Registers a protocol plugin
  protocolPluginTable[version] = plug

proc unregisterProtocolPlugin*(version: int32) {.async, exportc, dynlib.} =
  ## Registers a protocol plugin
  protocolPluginTable.del(version)

var tcpServer: AsyncSocket

proc initiateHandshake(srv: NbServer, s: AsyncSocket) {.async.} =
  ## Initiates the handshake for modern clients, needs to be rewritten
  var
    pSize: int = await s.readVarNum[:int32]()
    packet = await s.read(pSize)

    packetId = packet.readVarNum[:int32]()

  if packetId != 0:
    s.close()
    return

  var
    protocolVer = packet.readVarNum[:int32]()
    servAddr = packet.readString()
    servPort = packet.readNum[:uint16]()
    nextState = packet.readVarNum[:int32]()

  if protocolPluginTable.hasKey(protocolVer):
    asyncCheck cast[HandshakeProc](
      protocolPluginTable[protocolVer].libhandle.symAddr("initiateHandshake"))(protocolPluginTable[protocolVer],
        s, servAddr, servPort, nextState)

  else:
    s.close()


proc startServer(srv: NbServer) {.async.} =
  tcpServer.bindAddr(25565.Port, "0.0.0.0")
  tcpServer.listen()

  while true:
    var connection = await tcpServer.accept()

    asyncCheck srv.initiateHandshake(connection)

proc setup*(plugin: NbPlugin) {.dynlib, exportc, async.} = discard

proc teardown*(plugin: NbPlugin) {.dynlib, exportc, async.} = discard

proc enable*(plugin: NbPlugin) {.dynlib, exportc, async.} =
  tcpServer = newAsyncSocket(inheritable = true)

  asyncCheck plugin.server.startServer()

proc disable*(plugin: NbPlugin) {.dynlib, exportc, async.} = discard