# Package

version     = "0.2.0"
author      = "Yu-Vitaqua-fer-Chronos"
description = "ModernNet implements basic packet parsing and serialising, as well as containing Nimberite plugins"
license     = "Apache-2.0"
srcDir      = "src"


# Dependencies

requires "nim >= 1.6.10"

# Tasks
import strformat, os

task buildAllPlugins, "Builds all of the plugins for ModernNet":
  # This requires you to have installed the `Nimberite` module manually!

  let flags = "--define:nbPlugin"

  let
    coreName = DynlibFormat % "modernnet-core"
    n1_19_3Name = DynlibFormat % "modernnet-1.19.3"

  selfExec(fmt"c {flags} --out:build/{coreName} src/modernnet/core.nim")
  selfExec(fmt"c {flags} --out:build/{n1_19_3Name} src/modernnet/n1_19_3.nim")
