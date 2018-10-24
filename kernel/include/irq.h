#ifndef __IRQ_H
#define __IRQ_H

#include "idt.h"

extern void install_irq();
extern void irq_install_handler(int irq, void (*handler)(INT_REGS *r));
extern void irq_uninstall_handler(int irq);

#endif