#include "include/system.h"

/* Defines an IDT table entry */
typedef struct 
{
  uint16  base_lo;         /* Bits 0-15 of offset address. */
  uint16  sel;             /* GDT code segment selector. */
  uint8   always0;         
  uint8   flags;           
  uint16  base_hi;         /* Bits 16-31 of offset address. */
} __attribute__((packed)) IDT_DESCRIPTOR;

/*
 * Type flags for an IDT descriptor for an interrupt gate:
 * - Present is 1
 * - Privilege level is 0
 * - Gate type is 0xe (386 interrupt gate)
 */
#define IDT_DESCRIPTOR_INTERRUPT_GATE 0x8e

/*
 * Type flags for an IDT descriptor for an interrupt gate:
 * - Present is 1
 * - Privilege level is 0
 * - Gate type is 0xf (386 trap gate)
 */
#define IDT_DESCRIPTOR_TRAP_GATE 0x8f


/* Pointer to IDT table */
typedef struct
{
  uint16  limit;           /* IDT table length in bytes. */
  uint32  base;            /* Physical address of first inerrupt entry. */
} __attribute__((packed)) IDT_PTR;

/* 
 * Declare an IDT of 256 entries. Although we will only use the
 * first 32 entries, the rest exists as a bit
 * of a trap. If any undefined IDT entry is hit, it normally
 * will cause an "Unhandled Interrupt" exception. Any descriptor
 * for which the 'presence' bit is cleared (0) will generate an
 * "Unhandled Interrupt" exception.
 */
IDT_DESCRIPTOR idt[256];

/* 
 * The actual interrupt point is in idt_asm.s, as it is
 * used there by the LIDT instruction. 
 */
extern IDT_PTR idtp;

extern void load_idt();

/* 
 * Set an entry in the IDT.
 * num   - interrupt number, 0-255
 * base  - base address
 * sel   - segment selector
 * flags - interrupt descriptor access flags
 */
void set_idt_gate(uint8 num, uint32 base, uint16 sel, uint8 flags)
{
  /* The interrupt routine's base address */
  idt[num].base_lo = (base & 0xFFFF);
  idt[num].base_hi = (base >> 16) & 0xFFFF;

  /* The segment or 'selector' that this IDT entry will use
  *  is set here, along with any access flags */
  idt[num].sel = sel;
  idt[num].always0 = 0;
  idt[num].flags = flags; 
}

/* 
 * Sets an IDT interrupt gate. This is a convenience function.
 */
void set_idt_interrupt_gate(uint8 num, uint32 base)
{
  set_idt_gate(num, base, 0x08, IDT_DESCRIPTOR_INTERRUPT_GATE);
}

/* 
 * Sets an IDT trap gate. This is a convenience function.
 */
void set_idt_trap_gate(uint8 num, uint32 base)
{
  set_idt_gate(num, base, 0x08, IDT_DESCRIPTOR_TRAP_GATE);
}

/* 
 * Installs the IDT 
 */
void install_idt()
{
  /* Setup IDT pointer: */
  idtp.limit = (sizeof (IDT_DESCRIPTOR) * 256) - 1;
  idtp.base = (uint32) &idt;

  /* Clear IDT to zeroes: */
  memset((uint8*) &idt, 0, sizeof(IDT_DESCRIPTOR) * 256);

  /* Add any new ISRs to the IDT here using idt_set_gate */

  /* Points the processor's internal register to the new IDT */
  load_idt();
}