#include "include/system.h"
#include "include/irq.h"
#include "include/pit.h"

void start_kernel()
{
	__asm__ __volatile__("xchg %bx, %bx");
	
	__asm__ __volatile__("cli");
	install_idt();
	install_isrs();
	install_irq();
	__asm__ __volatile__("sti");
	timer_install();
	
	init_video();
	
	__asm__ __volatile__("xchg %bx, %bx");
	
mylabel:
	goto mylabel;
}
