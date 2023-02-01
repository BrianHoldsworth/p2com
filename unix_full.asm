format ELF
; Cross platform code/data sections
macro codeseg
{
		section '.TEXT' executable
}
macro udataseg
{
		section '.BSS' writable
}
macro with_interpreter
{
    interpreter:	file "Spin2_interpreter.obj"
}
macro with_debugger
{
    debugger:	    file "Spin2_debugger.obj"
}
macro with_flash_loader
{
    flash_loader:	file "flash_loader.obj"
}
macro with_clock_setter
{
    clock_setter:	file "clock_setter.obj"
}
