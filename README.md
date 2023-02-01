This repository contains a slightly modified version of the Propeller 2 compiler from the "PNut" Win32 program. The purpose is just to assemble the i386 assembly code in the file "p2com.asm" and link it to executable file p2c - a P2 compiler that can build itself in two passes, and includes a "verify" command line option for use in automated testing.

The modifications to the original "PNut" assembly code are just what is necessary to make it assemble with the cross-platform [flat assembler (fasm)](http://flatassembler.net). Most of the line-for-line changes are done by running 'fasm.sh' to modify the format of x86 assembly code so it is fasm-freindly (PNut uses TASM32.EXE). The rest of the assembly conversion is done with judicious use of macros.

How To Build
------------

Use build.sh, or crank.bat on Windows. You will need to have fasm in your path.

TODO
----

- [ ] Automated functional tests for compiler
- [ ] Compatibility with x64 ISA and binaries

Related Projects
----------------

[pmut](https://github.com/BrianHoldsworth/pmut) - A Linux multi-tool for Propeller 2 development, based off "PNut" for Windows.
