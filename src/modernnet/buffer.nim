import ./[
  exceptions,
  constants,
  types
]

import ./private/stew/endians2

type
  Buffer* = ref object
    buf*: seq[byte]
    pos*: int

  NumberN* = byte | int8 | int16 | int32 | int64 | uint8 | uint16 | uint32 | uint64 | float32 | float64

func newBuffer*(data: openArray[byte] = newSeq[byte]()): Buffer =
  Buffer(buf: @data)

# Writing
func writeNum*[R: NumberN | bool](b: Buffer, value: R) =
  ## Writes any numeric type or boolean to a buffer
  if (b.pos + sizeof(R)) > b.buf.len:
    b.buf.setLen(b.pos + sizeof(R))

  when sizeof(R) == 1:
    b.buf[b.pos] = cast[byte](value)
  elif sizeof(R) == 2:
    b.buf[b.pos..<(b.pos+sizeof(R))] = cast[uint16](value).toBytesBE
  elif sizeof(R) == 4:
    b.buf[b.pos..<(b.pos+sizeof(R))] = cast[uint32](value).toBytesBE
  elif sizeof(R) == 8:
    b.buf[b.pos..<(b.pos+sizeof(R))] = cast[uint64](value).toBytesBE
  else:
    {.error: "Serialisation of `" & $R & "` is not implemented!".}

  b.pos += sizeof(R)

func writeVarNum*[R: int32 | int64](b: Buffer, value: R) =
  ## Writes a VarInt or a VarLong to a buffer
  var val = value

  while true:
    if (val and (not SegmentBits)) == 0:
      b.writeNum(cast[uint8](val))
      break

    b.writeNum(cast[uint8]((val and SegmentBits) or ContinueBit))
    val = val shr 7

func writeString*(b: Buffer, s: string) =
  b.writeVarNum[:int32](s.len.int32)
  if (b.pos + s.len) > b.buf.len:
    b.buf.setLen(b.pos + s.len)

  b.buf[b.pos..<(b.pos+s.len)] = cast[seq[byte]](s)
  b.pos += s.len

template writeIdentifier*(b: Buffer, i: Identifier) =
  ## Writes an identifier to a buffer
  b.writeString($i)

template writePosition*(b: Buffer, p: Position, format = XZY) =
  ## Writes a Position to a buffer using the specified encoding format
  s.writeNum[:int64](toPos(p, format))


# Reading
func readNum*[R: NumberN | bool](b: Buffer): R {.raises: [MnEndOfBufferError].} =
  ## Reads any numeric type or boolean from a buffer
  if (b.pos + sizeof(R)) > b.buf.len:
    raise newException(MnEndOfBufferError, "Reached the end of the buffer while trying to read a " & $R & '!')

  result = when sizeof(R) == 1:
    cast[R](b.buf[b.pos])
  elif sizeof(R) == 2:
    cast[R](fromBytesBE(uint16, b.buf[b.pos..<(b.pos+sizeof(R))]))
  elif sizeof(R) == 4:
    cast[R](fromBytesBE(uint32, b.buf[b.pos..<(b.pos+sizeof(R))]))
  elif sizeof(R) == 8:
    cast[R](fromBytesBE(uint64, b.buf[b.pos..<(b.pos+sizeof(R))]))
  else:
    {.error: "Deserialisation of `" & $R & "` is not implemented!".}

  b.pos += sizeof(R)

func readVarNum*[R: int32 | int64](b: Buffer): R {.raises: [MnEndOfBufferError, MnPacketParsingError].} =
  ## Reads a VarInt or a VarLong from a buffer
  var
    position: int8 = 0
    currentByte: int8

  while true:
    currentByte = b.readNum[:int8]()
    result = result or ((currentByte.R and SegmentBits) shl position)

    if (currentByte and ContinueBit) == 0:
      break

    position += 7

    when R is int32:
      if position >= VarIntBits:
        raise newException(MnPacketParsingError, "VarInt is too big!")

    elif R is int64:
      if position >= VarLongBits:
        raise newException(MnPacketParsingError, "VarLong is too big!")

    else:
      {.error: "Deserialisation of `" & $R & "` is not implemented!".}

func readString*(b: Buffer): string {.raises: [MnEndOfBufferError, MnPacketParsingError].} =
  ## Reads a string from a buffer
  let length = b.readVarNum[:int32]()
  result.setLen(length)

  let data = b.buf[b.pos..<(b.pos+length)]
  result = cast[string](data)

  b.pos += length

template readIdentifier*(b: Buffer): Identifier =
  ## Reads an Identifier from a buffer
  identifier(s.decodeString())

template readPosition*(b: Buffer, format = XZY): Position =
  ## Reads a Position from a buffer using the specified encoding format
  fromPos(s.readNum[:int64](), format)