# Package

version     = "0.1.0"
author      = "Yu-Vitaqua-fer-Chronos"
description = "ModernNet implements a packet reading and writing system, as well as some useful tools for implementing this into your own project!"
license     = "Apache-2.0"
srcDir      = "src"


# Dependencies

requires "nim >= 1.6.12"   # May work on earlier versions, only tested on latest stable versions
requires "zippy >= 0.10.9" # Used for handling compressed MC packets
requires "regex >= 0.20.2" # Pure Nim regex engine, used for verifying identifiers