This repository contains a slightly modified version of the Propeller 2 compiler from the "PNut" Win32 program. The purpose is just to assemble the i386 assembly code in the file "p2com.asm" in a way that it can be easily linked into other tools that need a Propeller 2 Compiler.

The modifications to the assembly code are just what is necessary to make it assemble with the cross-platform [flat assembler (fasm)](http://flatassembler.net). Using fasm, linkable object code for the compiler can be easily built and used on most any host. Scripts are included for building on Linux (requires 'wine') and on Windows.

How To Build
------------

On Windows, crank.bat should be run. You will need to have fasm in your path.

On Unix like systems, use build.sh instead. Again, you will need fasm in your path. Because the code needs pre-assembled PASM code from modules (such as the Spin2 interpreter and the debugging features), the Windows "PNut" program is used to bootstrap this part. Therefore, you also need wine installed so that the build script can run "PNut" in a fake Win32 environment.

Related Projects
----------------

pmut - A multi-platorm multi-tool for Propeller 2 development.
