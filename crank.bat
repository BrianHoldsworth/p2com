@echo off

md bin
set /A ERR = 0

PNut_v36 Spin2_debugger -c
set /A ERR = %ERR% + %ERRORLEVEL%
type error.txt

PNut_v36 Spin2_interpreter -c
set /A ERR = %ERR% + %ERRORLEVEL%
type error.txt

PNut_v36 flash_loader -c
set /A ERR = %ERR% + %ERRORLEVEL%
type error.txt

PNut_v36 clock_setter -c
set /A ERR = %ERR% + %ERRORLEVEL%
type error.txt

fasm -d linux=1 p2com.asm bin\p2com.elf
fasm -d win32=1 p2com.asm bin\p2com.coff

if %ERR% NEQ 0 (
    set /P input="ERROR: Press enter to continue: "
)