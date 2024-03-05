# ModernNet
ModernNet is a barebones library to interact with the Minecraft Java Edition protocol!

To support IO, I've taken the [Sans-I/O](https://sans-io.readthedocs.io/how-to-sans-io.html)
approach, separating the protocol from the IO, it can easily be implemented in any library with
this code:
```nim
# Set up the buffer
var buffer = newBuffer()

buffer.writeVarNum[:int32](0x27)
buffer.writeVarNum[:int32](8)
buffer.writeNum[:int64](23142)

buffer.pos = 0

# Commence tests~
var b: seq[byte] # Pretend this is a buffered socket

var res = readRawPacket(b)

while not res.isOk:
  b.add buffer.readNum[:byte]()
  res = readRawPacket(b)

assert res.ok.packet.id == 0x27
assert res.ok.packet.buf.readVarNum[:int32]() == 8
assert res.ok.packet.buf.readNum[:int64]() == 23142
assert res.ok.bytesRead == 10 # The ID, length and the data in the buffer
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