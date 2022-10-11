#!/bin/bash
mkdir -p bin
if ! [ -f Spin2_debugger.obj ]; then
    wine PNut_v36 Spin2_debugger -c
fi
if ! [ -f Spin2_interpreter.obj ]; then
wine PNut_v36 Spin2_interpreter -c
fi
if ! [ -f flash_loader.obj ]; then
wine PNut_v36 flash_loader -c
fi
if ! [ -f clock_setter.obj ]; then
wine PNut_v36 clock_setter -c
fi
PLATFORM=unix fasm p2com.asm bin/p2com.elf
PLATFORM=win32 fasm p2com.asm bin/p2com.coff
