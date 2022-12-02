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
