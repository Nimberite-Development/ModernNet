# ModernNet
ModernNet is a barebones library to interact with the Minecraft Java Edition protocol!

A very basic skeleton of a server is written here, however it does not handle logging into the server at all.

```nim
import std/[asyncdispatch, asyncnet, strutils]

import modernnet

proc processClient(client: AsyncSocket) {.async.} =
  var state = 0

  while not client.isClosed():
    let
      packetLength = await client.readVarNum[:int32]()
      packet = await client.read(packetLength)
      packetId = packet.readVarNum[:int32]()

    echo "Packet ID: " & $packetId

    if packetId == 0x00:
      if state == 0:
        let
          version = packet.readVarNum[:int32]()
          address = packet.readString()
          port = packet.readNum[:uint16]

        state = packet.readVarNum[:int32]()
        continue

      elif state == 1:
        var response = newBuffer()
        response.writeVarNum(0x00)
        response.writeString($buildServerListJson("1.7.10", 5, 10, 0))

        await client.write(response)
        continue

      else:
        echo "Unimplemented state: " & $state
        continue

    elif packetId == 0x01:
      let payload = packet.readNum[:int64]()

      var b = newBuffer()
      b.writeNum(payload)

      await client.write(b)

      client.close()

      continue

    else:
      echo "Unimplemented packet: " & $packetId
      continue


proc serve() {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(12345))
  server.listen()
  
  while true:
    let client = await server.accept()
    asyncCheck processClient(client)

asyncCheck serve()
echo "Started server"
runForever()
```

## Useful Notes
An empty packet with size 0 needs to be handled by the user currently,
in the example code, `if packetLength <= 0: return` is enough for
this to not have an effect.

## To-Dos
- [ ] Work on better documentation, with more examples.

- [ ] Implement MC auth for the library.
  - This isn't a *must*, *but* it would improve the QoL of developers who use this library.

- [ ] Wrap all packets and relating data for each MC version (and sharing the types/code when possible).
  - Not a requirement but would be nice: Create an API to parse a packet from a socket/buffer
    without any other manual code.
  - https://github.com/PrismarineJS/minecraft-data would likely be a very good starting point for
    automating generation of the packet wrappers.

- [ ] Add more tests for verifying everything is working correctly.
  - A W.I.P server is being made with this library so that more tests can be added.

## Completed Goals
- [x] Allow for `Socket` *or* `AsyncSocket` to be used in `network.nim`.

- [X] Rewrite code to avoid streams (unnecessary overhead).
  - Look at `src/modernnet/buffer.nim` for this functionality.

## Unplanned/Scrapped
- Allow for the full API of encoding and decoding to be used even on sockets.
  - I've decided that doing everything via `Buffer`s is much better as it allows for us to
    handle errors more gracefully.