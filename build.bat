REM Powered by Adriel Freud...

@echo off

echo [!] Compilando bootloader..

as -o boot.o boot.s
ld -o boot.out boot.o -Ttext 0x7c00
objcopy -O binary -j .text boot.out boot.bin
as -o 2ndstage.o 2ndstage.s
ld -o 2ndstage.out 2ndstage.o -Ttext 0x0
objcopy -O binary -j .text 2ndstage.out 2ndstage.bin
imagefs c iso.img 720
imagefs b iso.img boot.bin
imagefs a iso.img 2ndstage.bin

echo [+] BootLoader Compilado com Sucesso!
