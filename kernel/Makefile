AS  := as
RM	:= rm
CC  := gcc
CFLAGS	:= -Wall -fno-builtin -nostdlib -ffreestanding -nostdinc -m32

all:	kernel.bin

kernel.bin: kernel.out
	objcopy -O binary kernel.out kernel.bin

kernel.out: kernel.o idt_asm.o irq_asm.o main.o system.o mem.o display.o port.o string.o idt.o isr.o irq.o pit.o
	$(CC) $(CFLAGS) -T link.ld -o kernel.out kernel.o idt_asm.o irq_asm.o main.o system.o mem.o display.o port.o string.o idt.o isr.o irq.o pit.o -e start

pit.o: pit.c
	$(CC) $(CFLAGS) -o pit.o -c pit.c	

irq.o: irq.c
	$(CC) $(CFLAGS) -o irq.o -c irq.c	
	
isr.o: isr.c
	$(CC) $(CFLAGS) -o isr.o -c isr.c	

idt.o: idt.c
	$(CC) $(CFLAGS) -o idt.o -c idt.c	
	
display.o: display.c 
	$(CC) $(CFLAGS) -o display.o -c display.c	

string.o: string.c 
	$(CC) $(CFLAGS) -o string.o -c string.c	

port.o: port.c 
	$(CC) $(CFLAGS) -o port.o -c port.c	
	
mem.o: mem.c
	$(CC) $(CFLAGS) -o mem.o -c mem.c
	
system.o: system.c
	$(CC) $(CFLAGS) -o system.o -c system.c
	
main.o: main.c
	$(CC) $(CFLAGS) -o main.o -c main.c

irq_asm.o: irq_asm.s
	$(AS) -o irq_asm.o irq_asm.s

idt_asm.o: idt_asm.s
	$(AS) -o idt_asm.o idt_asm.s
		
kernel.o: kernel.s
	$(AS) -o kernel.o kernel.s

clean:
	$(RM) -f *.o
	$(RM) -f *.bin
	$(RM) -f *.out
	