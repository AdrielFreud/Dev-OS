# ***********************************************************
#
# DevOS 2018
#
# Implementado por Adriel Freud!
# Contato: businessc0rp2k17@gmail.com
# FB: http://www.facebook.com/xrn401
#   =>DebutySecTeamSecurity<=
# 
# ***********************************************************

.code16
.intel_syntax noprefix
.text
.org 0x0             

.include "macros.s"

.global main

main:
  xchg bx, bx
  mWriteString msg
hang:
  jmp hang

# 
# A inicialização falhou devido a um erro no disco.
# Informe o usuário e reinicie.
# 
bootFailure:
  mWriteString diskerror
  mReboot
  
.include "functions.s"

# PROGRAM DATA
msg:          .asciz "2nd stage bootloader...\r\n"
rebootmsg:    .asciz "Press any key to reboot.\r\n"
diskerror:    .asciz "Disk error. "

.include "bootsector.s"

.fill 1024, 1, 1              # Pad 1K com 1 bytes para testar arquivo maior que 1 setor.
