#!/bin/bash
mkdir -p bin
wine PNut_v36 Spin2_debugger -c
wine PNut_v36 Spin2_interpreter -c
wine PNut_v36 flash_loader -c
wine PNut_v36 clock_setter -c
PLATFORM=unix fasm p2com.asm bin/p2com.elf
PLATFORM=win32 fasm p2com.asm bin/p2com.coff
