#!/bin/bash
mkdir -p bin
if ! [ -f bin/p2com.elf ]; then
PLATFORM=unix fasm p2com.asm bin/p2com.elf
PLATFORM=win32 fasm p2com.asm bin/p2com.coff
fi
if ! [ -f p2c ]; then
~/fpcupdeluxe/lazarus/lazbuild -B p2c.lpi
#~/fpcupdeluxe/lazarus/lazbuild -B --operating-system=win32 p2c.lpi
fi
if ! [ -f Spin2_debugger.obj ]; then
./p2c Spin2_debugger
fi
if ! [ -f Spin2_interpreter.obj ]; then
./p2c Spin2_interpreter
fi
if ! [ -f flash_loader.obj ]; then
./p2c flash_loader
fi
if ! [ -f clock_setter.obj ]; then
./p2c clock_setter
fi
PLATFORM=unix_full fasm p2com.asm bin/p2com.elf
~/fpcupdeluxe/lazarus/lazbuild -B p2c.lpi
#PLATFORM=win32_full fasm p2com.asm bin/p2com.coff
#~/fpcupdeluxe/lazarus/lazbuild -B --operating-system=win32 p2c.lpi
