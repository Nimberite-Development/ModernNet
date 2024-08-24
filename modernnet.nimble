# Package

version     = "3.1.1"
author      = "Luyten Orion"
description = "ModernNet implements a packet reading and writing system, as well as some useful tools for implementing this into your own project!"
license     = "Apache-2.0"
srcDir      = "src"


# Dependencies

requires "nim >= 2.0.0"    # May work on earlier versions, only tested on latest stable versions
requires "zippy >= 0.10.9" # Used for handling compressed MC packets
requires "uuids >= 0.1.12" # Used for handling UUIDs