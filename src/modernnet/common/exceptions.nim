type
  MnInvalidIdentifierError* = object of CatchableError

  MnInvalidIncomingPositionError* = object of CatchableError
  MnInvalidOutgoingPositionError* = object of CatchableError

  MnPacketConstructionError* = object of CatchableError
  MnPacketParsingError* = object of CatchableError

  MnConnectionClosedError* = object of CatchableError