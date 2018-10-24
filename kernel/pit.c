#include "include/system.h"
#include "include/idt.h"
#include "include/irq.h"

/* Isto irá acompanhar quantos ticks o sistema foi executado por */

int timer_ticks = 0;

void timer_phase(int hz)
{
  int divisor = 1193180 / hz;       /* Calcular nosso divisor */
  outportb(0x43, 0x36);             /* Defina nosso byte de comando 0x36 */
  outportb(0x40, divisor & 0xFF);   /* Definir byte baixo do divisor */
  outportb(0x40, divisor >> 8);     /* Definir byte alto do divisor */
}

/* Lida com o temporizador. Neste caso, é muito simples: nós
* incrementar a variável 'timer_ticks' toda vez que o
* Timer dispara. Por padrão, o timer é acionado 18,222 vezes
* por segundo. Por que 18,222Hz? Algum engenheiro da IBM deve ter
* Fumar algo funky */
void timer_handler(INT_REGS *r)
{
  /* Incrementar o nosso 'tick count' */
  timer_ticks++;

  /* A cada 18 relógios (aproximadamente 1 segundo), vamos exibir uma mensagem na tela */
  if (timer_ticks % (3*18) == 0)
  {
    puts("One second has passed\n");
  }
}

/* Configura o relógio do sistema instalando o manipulador de cronômetro em IRQ0 */
void timer_install()
{
  /* Instala 'timer_handler' para IRQ0 */
  irq_install_handler(0, timer_handler);
}
