AS  := as
LD	:= ld
RM  := rm

all:	boot.bin 2ndstage.bin

boot.bin: boot.out
	objcopy -O binary -j .text boot.out boot.bin

boot.out: boot.o
	$(LD) -o boot.out boot.o -Ttext 0x7c00
  
boot.o: boot.s bootsector.s functions.s macros.s 
	$(AS) -o boot.o boot.s

2ndstage.bin: 2ndstage.out
	objcopy -O binary -j .text 2ndstage.out 2ndstage.bin
  
2ndstage.out: 2ndstage.o
	$(LD) -o 2ndstage.out 2ndstage.o -Ttext 0x0
  
2ndstage.o: 2ndstage.s bootsector.s functions.s macros.s descriptors.s a20.s
	$(AS) -o 2ndstage.o 2ndstage.s

clean:
	$(RM) -f *.o
	$(RM) -f *.out
	$(RM) -f *.bin
