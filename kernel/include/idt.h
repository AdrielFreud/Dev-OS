#ifndef __IDT_H
#define __IDT_H

/* This defines what the stack looks like after an ISR was running */
typedef struct
{
  unsigned int gs, fs, es, ds;      /* pushed the segs last */
  unsigned int edi, esi, ebp, esp, ebx, edx, ecx, eax;  /* pushed by 'pusha' */
  unsigned int int_no, err_code;    /* our 'push byte #' and ecodes do this */
  unsigned int eip, cs, eflags, useresp, ss;   /* pushed by the processor automatically */ 
} INT_REGS;

extern void set_idt_interrupt_gate(uint8 num, uint32 base);
extern void set_idt_trap_gate(uint8 num, uint32 base);
extern void load_idt();
extern void install_idt();

#endif