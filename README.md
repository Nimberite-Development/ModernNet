# ModernNet
ModernNet is a barebones library to interact with the Minecraft Java Edition protocol!

A very basic skeleton of a server is written here, however it does not handle logging into the server at all.

```nim
import std/[asyncdispatch, asyncnet, streams]

import modernnet

proc processClient(client: AsyncSocket) {.async.} =
  while not client.isClosed():
    let
      packetLength = await client.readVarInt()
      packet = await client.read(packetLength)
      packetId = packet.readVarNum[:int32]()
    
    if packetLength <= 0: return

    if packetId == 0x00:
      var response = newStringStream()

      response.writeVarNum[:int32](0x00)
      response.writeString $buildServerListJson("1.7.10", 5, 0, 0)

      await client.write(response)

    if packetId == 0x01:
        let payload = packet.readNum[:int64]()

        var pingRes = newStringStream()
        pingRes.writeVarNum[:int32](0x01)
        pingRes.writeNum[:int64](payload)

        await client.write(pingRes)
        client.close()


proc serve() {.async.} =
  var server = newAsyncSocket()
  server.setSockOpt(OptReuseAddr, true)
  server.bindAddr(Port(12345))
  server.listen()
  
  while true:
    let client = await server.accept()
    
    asyncCheck processClient(client)

asyncCheck serve()
runForever()
```

## Useful Notes
An empty packet with size 0 needs to be handled by the user currently,
in the example code, `if packetLength <= 0: return` is enough for
this to not have an effect.

## To-Dos
- [ ] Rewrite code to avoid streams (unnecessary overhead)

- [ ] Wrap packets for MC various MC versions
  - 1.7.10 upwards may be a good start

- [ ] Work on better documentation, with more examples.

- [ ] Implement MC auth for the library.
  - This isn't a *must*, *but* it would improve the QoL of developers who use this library.

- [ ] Wrap all packets and relating data for each MC version (and sharing the types/code when possible).
  - Not a requirement but would be nice: Create an API to parse a packet from a socket/stream
    without any other manual code.

- [ ] Add more tests for verifying everything is working correctly.

- [ ] Allow for the full API of encoding and decoding to be used even
  on sockets.
  - Not necessary but may be liked by some?

## Completed Goals
- [x] Allow for `Socket` *or* `AsyncSocket` to be used in `network.nim`.

