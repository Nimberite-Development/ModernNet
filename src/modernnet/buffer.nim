import "."/[
  exceptions,
  types
]

import ./private/[
  constants,
  utils
]

type
  Buffer* = ref object
    buf*: seq[byte]
    pos*: int

func len*(b: Buffer): int = b.buf.len

func newBuffer*(data: openArray[byte] = newSeq[byte]()): Buffer =
  Buffer(buf: @data)

# Writing
func writeNum*[R: SizedNum](b: Buffer, value: R) {.raises: [ValueError].} =
  ## Writes any numeric type or boolean to a buffer
  if (b.pos + sizeof(R)) > b.len:
    b.buf.setLen(b.pos + sizeof(R))

  deposit(value, b.buf.toOpenArray(b.pos, b.pos + sizeof(R) - 1))

  b.pos += sizeof(R)

func writeVar*[R: int32 | int64](b: Buffer, value: R) {.raises: [ValueError].} =
  ## Writes a VarInt or a VarLong to a buffer
  var val = value

  while true:
    if (val and (not SegmentBits)) == 0:
      b.writeNum(cast[uint8](val))
      break

    b.writeNum(cast[uint8]((val and SegmentBits) or ContinueBit))
    val = val shr 7

func writeUUID*(b: Buffer, uuid: UUID) =
  ## Writes a UUID to a buffer
  b.writeNum[:int64](uuid.mostSigBits())
  b.writeNum[:int64](uuid.leastSigBits())

func writeString*(b: Buffer, s: string) =
  ## Writes a string to a buffer
  b.writeVar[:int32](s.len.int32)
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
func readNum*[R: SizedNum](b: Buffer): R {.raises: [MnEndOfBufferError, ValueError].} =
  ## Reads any numeric type or boolean from a buffer
  if (b.pos + sizeof(R)) > b.buf.len:
    raise newException(MnEndOfBufferError, "Reached the end of the buffer while trying to read a " & $R & '!')

  result = b.buf.toOpenArray(b.pos, b.pos + sizeof(R) - 1).extract(R)

  b.pos += sizeof(R)

func readVar*[R: int32 | int64](b: Buffer): R {.raises: [MnEndOfBufferError, ValueError, MnPacketParsingError].} =
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

func readUUID*(b: Buffer): UUID =
  ## Reads a UUID from a buffer
  initUUID(b.readNum[:int64](), b.readNum[:int64]())

func readString*(b: Buffer, maxLength = 32767): string {.raises: [MnEndOfBufferError, ValueError, MnPacketParsingError].} =
  ## Reads a string from a buffer
  let length = b.readVar[:int32]()

  if length > maxLength * 3:
    raise newException(MnStringTooLongParsingError, "String is too long!")

  result.setLen(length)

  let data = b.buf[b.pos..<(b.pos+length)]
  result = cast[string](data)

  if result.len > maxLength:
    raise newException(MnStringTooLongParsingError, "String is too long!")

  b.pos += length

template readIdentifier*(b: Buffer): Identifier =
  ## Reads an Identifier from a buffer
  identifier(s.decodeString())

template readPosition*(b: Buffer, format = XZY): Position =
  ## Reads a Position from a buffer using the specified encoding format
  fromPos(s.readNum[:int64](), format)