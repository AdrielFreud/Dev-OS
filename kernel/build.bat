
@echo off

REM Powered by Adriel Freud...

echo [!] Compilando bootloader..

as -o kernel.o kernel.s
as -o idt_asm.o idt_asm.s
as -o irq_asm.o irq_asm.s
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o main.o -c main.c
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o system.o -c system.c
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o mem.o -c mem.c
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o display.o -c display.c	
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o port.o -c port.c	
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o string.o -c string.c	
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o idt.o -c idt.c	
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o isr.o -c isr.c	
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o irq.o -c irq.c	
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -o pit.o -c pit.c	
gcc -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32 -T link.ld -o kernel.out kernel.o idt_asm.o irq_asm.o main.o system.o mem.o display.o port.o string.o idt.o isr.o irq.o pit.o -e start
objcopy -O binary kernel.out kernel.bin

echo [+] BootLoader Compilado com Sucesso!