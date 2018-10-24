#include "include/system.h"

/*
  * Força a CPU a aguardar a conclusão de uma operação de E/S.
  * Use somente quando não houver nada como um registro de status
  * ou um IRQ para informar que a informação foi recebida.
  */

inline void io_wait()
{
    // porta 0x80 é usada para 'checkpoints' durante o POST.
    // O kernel do Linux parece achar que está livre para uso: - /
    asm volatile( "outb %%al, $0x80"
                  : : "a"(0) );
}