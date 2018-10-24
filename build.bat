@echo off

REM Powered by Adriel Freud...

echo [!] Compilando bootloader..

imagefs c test.img 720
copy boot\boot.bin .
imagefs b test.img boot.bin
del -f boot.bin
copy boot\2ndstage.bin .
imagefs a test.img 2ndstage.bin
del -f 2ndstage.bin
copy kernel\kernel.bin .
imagefs a test.img kernel.bin
del -f kernel.bin

echo [+] BootLoader Compilado com Sucesso!