.code32
.intel_syntax noprefix
.text

.global _irq0
.global _irq1
.global _irq2
.global _irq3
.global _irq4
.global _irq5
.global _irq6
.global _irq7
.global _irq8
.global _irq9
.global _irq10
.global _irq11
.global _irq12
.global _irq13
.global _irq14
.global _irq15

.macro mIRQ num
  push 0
  push \num
  jmp irq_common_stub
.endm

_irq0:  mIRQ 32
_irq1:  mIRQ 33
_irq2:  mIRQ 34
_irq3:  mIRQ 35
_irq4:  mIRQ 36
_irq5:  mIRQ 37
_irq6:  mIRQ 38
_irq7:  mIRQ 39
_irq8:  mIRQ 40
_irq9:  mIRQ 41
_irq10: mIRQ 42
_irq11: mIRQ 43
_irq12: mIRQ 44
_irq13: mIRQ 45
_irq14: mIRQ 46
_irq15: mIRQ 47

irq_common_stub:
  pusha
  push  ds
  push  es
  push  fs
  push  gs
  mov   ax, 0x10
  mov   ds, ax
  mov   es, ax
  mov   fs, ax
  mov   gs, ax
  mov   eax, esp
  push  eax
  lea   eax, _irq_handler
  call  eax
  pop   eax
  pop   gs
  pop   fs
  pop   es
  pop   ds
  popa
  add   esp, 8
  iret  
