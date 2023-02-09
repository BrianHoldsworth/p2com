This repository contains a slightly modified version of the Propeller 2 compiler from the "PNut" Win32 program. It assembles the code in file ['p2com.asm'](p2com.asm), and links it into the executable p2c - a P2 compiler that can build itself in two passes on Linux or Windows, and includes a "-v/--verify" option for using it for automated testing.

The code modifications to the original i386 assembly code in p2com.asm are just what is necessary to make it assemble with the cross-platform [flat assembler (fasm)](http://flatassembler.net). Most of the line-for-line changes are done by running ['fasm.sh'](fasm.sh) on the PNut version, This will modify the format of the assembly code so it is fasm-freindly. The rest of the assembly conversion is done with judicious use of fasm macros.

How To Build
------------

Use build.sh, or crank.bat on Windows. You will need to have fasm in your path to build the assembly code, and 'lazbuild' to build the Pascal code for p2c. It is best if you use [fpcupdeluxe](https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases) to manage your Lazarus and Free Pascal installation.

TODO
----

- [ ] Automated functional tests using p2c --verify mode
- [ ] Compatibility with x64 ISA and binaries

Related Projects
----------------

[pmut](https://github.com/BrianHoldsworth/pmut) - A Linux multi-tool for Propeller 2 development, based off "PNut" for Windows.
