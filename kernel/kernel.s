.code32
.intel_syntax noprefix
.text

.global start
start:
  lea    esp, sys_stack    # Configure uma pilha.
  call   _start_kernel     # Salta para a função C.
  
# Aqui está a definição da nossa seção BSS. Agora vamos usar
# apenas para armazenar a pilha. Lembre-se que uma pilha realmente cresce
# para baixo, por isso, declaramos o tamanho dos dados antes de declarar
# o identificador '_sys_stack'
.section .bss
  .lcomm buff, 0x1000 # Reserve 4KB
    
sys_stack:

.section .data
  sec_id:      .ascii "DATA SECTION"
