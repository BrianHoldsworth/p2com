format MS COFF
; Cross platform code/data sections
macro codeseg
{
		section '.text' code readable executable
}
macro udataseg
{
		section '.bss' data writable
}
