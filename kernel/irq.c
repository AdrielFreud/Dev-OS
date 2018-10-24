#include "include/system.h"
#include "include/idt.h"

/*
  * O byte EOI de interrupção deve ser enviado para o PIC após o tratamento de um IRQ.
  * O PIC não enviará mais IRQs até receber o EOI.
  *
  * São dois controladores PIC: mestre e escravo. Quando um IRQ enviado pelo
  * escravo é reconhecido, então um EOI deve ser enviado para ambos os controladores.
*/

#define PIC_EOI              0x20

/*
  * Porta na qual o chip PIC principal escuta:
*/
#define PIC_MASTER_CMD_PORT  0x20
#define PIC_MASTER_DATA_PORT 0x21

/*
 * Porta na qual o chip PIC escravo escuta:
*/
#define PIC_SLAVE_CMD_PORT   0xA0
#define PIC_SLAVE_DATA_PORT  0xA1


extern void irq0();
extern void irq1();
extern void irq2();
extern void irq3();
extern void irq4();
extern void irq5();
extern void irq6();
extern void irq7();
extern void irq8();
extern void irq9();
extern void irq10();
extern void irq11();
extern void irq12();
extern void irq13();
extern void irq14();
extern void irq15();

/* Essa matriz é, na verdade, uma matriz de ponteiros de função. Nós usamos
* isto para lidar com manipuladores de IRQ personalizados para um determinado IRQ */

void *irq_routines[16] =
{
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0
};

/* Isso instala um manipulador de IRQ personalizado para o IRQ */
void irq_install_handler(int irq, void (*handler)(INT_REGS *r))
{
  irq_routines[irq] = handler;
}

/* Isso limpa o manipulador para um determinado IRQ */
void irq_uninstall_handler(int irq)
{
  irq_routines[irq] = 0;
}

/* Normalmente, os IRQs 0 a 7 são mapeados para as entradas 8 a 15. Este
  * é um problema no modo protegido, porque a entrada 8 do IDT é um
  * Dupla Falha! Sem remapeamento, toda vez que o IRQ0 dispara,
  * você recebe uma exceção de falha dupla, que na verdade não é
  * o que está acontecendo. Nós enviamos comandos para o programável
  * Controlador de interrupção (PICs - também chamado de 8259) em
  * ordem para remapear IRQ0 até 15 para entradas IDT 32 a 47.
*/

void remap_PIC()
{
  outportb(PIC_MASTER_CMD_PORT,  0x11);  /* Diga ao PIC mestre para aguardar 3 bytes de inicialização. */
  io_wait();
  outportb(PIC_SLAVE_CMD_PORT,   0x11);  /* Diga ao escravo PIC para esperar 3 bytes de inicialização. */
  io_wait();
  outportb(PIC_MASTER_DATA_PORT, 0x20);  /* Remapear: defina o deslocamento PIC mestre para 0x20 (32). */
  io_wait();
  outportb(PIC_SLAVE_DATA_PORT,  0x28);  /* Remapear: defina o deslocamento PIC escravo para 0x28 (40).  */
  io_wait();
  outportb(PIC_MASTER_DATA_PORT, 0x04);  /* Diga ao PIC mestre que existe um PIC escravo no IRQ2 (máscara de bits 0000 0100) */
  io_wait();
  outportb(PIC_SLAVE_DATA_PORT,  0x02);  /* Diga ao slave PIC que sua identidade em cascata é 2 (0000 0010) */
  io_wait();
  outportb(PIC_MASTER_DATA_PORT, 0x01);  /* Defina o modo de operação PIC mestre para o modo 8086/8088 (MCS-80/85). */
  io_wait();
  outportb(PIC_SLAVE_DATA_PORT,  0x01);  /* Defina o modo de operação PIC escravo para o modo 8086/8088 (MCS-80/85). */
  io_wait();
  outportb(PIC_MASTER_DATA_PORT, 0x00);  /* Limpar a máscara PIC principal. */
  outportb(PIC_SLAVE_DATA_PORT,  0x00);  /* Limpar máscara PIC escrava. */
}

/* Remapear os controladores de interrupção e, em seguida, instalamos
* os ISRs apropriados para as entradas corretas no IDT. este
* é como instalar os manipuladores de exceção 
*/
void install_irq()
{
  remap_PIC();

	set_idt_interrupt_gate(32, (unsigned)irq0);
	set_idt_interrupt_gate(33, (unsigned)irq1);
	set_idt_interrupt_gate(34, (unsigned)irq2);
	set_idt_interrupt_gate(35, (unsigned)irq3);
	set_idt_interrupt_gate(36, (unsigned)irq4);
	set_idt_interrupt_gate(37, (unsigned)irq5);
	set_idt_interrupt_gate(38, (unsigned)irq6);
	set_idt_interrupt_gate(39, (unsigned)irq7);
	set_idt_interrupt_gate(40, (unsigned)irq8);
	set_idt_interrupt_gate(41, (unsigned)irq9);
	set_idt_interrupt_gate(42, (unsigned)irq10);
	set_idt_interrupt_gate(43, (unsigned)irq11);
	set_idt_interrupt_gate(44, (unsigned)irq12);
	set_idt_interrupt_gate(45, (unsigned)irq13);
	set_idt_interrupt_gate(46, (unsigned)irq14);
	set_idt_interrupt_gate(47, (unsigned)irq15);
}

/*
 * Esta função é chamada quando um IRQ entra.
 */
void irq_handler(INT_REGS *r)
{
  /* This is a blank function pointer */
  void (*handler)(INT_REGS *r);

  /* 
   * Descubra se temos um manipulador personalizado para executar
   * IRQ e, finalmente, executá-lo. Se não houver manipulador,
   * fazer nada.
   */
  handler = irq_routines[r->int_no - 32];
  if (handler)
  {
    handler(r);
  }

  /* Se a entrada IDT que foi invocada for maior que 40
   * (significando IRQ8 - 15), então precisamos enviar um EOI para
   * o controlador escravo */
  if (r->int_no >= 40)
  {
    outportb(PIC_SLAVE_CMD_PORT, PIC_EOI);
  }

  /* Em ambos os casos, precisamos enviar um EOI para o mestre
   * controlador de interrupção também: */
  outportb(PIC_MASTER_CMD_PORT, PIC_EOI);
}


