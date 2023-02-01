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
macro with_interpreter 	{	interpreter:	}
macro with_debugger 	{	debugger:		}
macro with_flash_loader	{	flash_loader:	}
macro with_clock_setter	{	clock_setter:	}
