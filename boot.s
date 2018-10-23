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

LOAD_SEGMENT = 0x1000                     # carrega o carregador do segundo estágio para segmentar 1000h
FAT_SEGMENT  = 0x0ee0                     # carrega o FAT no segmento 0x0ee0 (9 * 512 bytes no segundo loader de estágio)

.global main

main:
    jmp short start                       # pula para o começo do código
    nop

.include "bootsector.s"
.include "macros.s"

start:
  mInitSegments  
  mResetDiskSystem
  mWriteString loadmsg
  mFindFile filename, LOAD_SEGMENT
  mReadFAT FAT_SEGMENT
  mReadFile LOAD_SEGMENT, FAT_SEGMENT
  mStartSecondStage

# 
# A inicialização falhou devido a um erro no disco.
# Informe o usuário e reinicie.
# 
bootFailure:
  mWriteString diskerror
  mReboot

.include "functions.s"
    
# PROGRAM DATA
filename:         .asciz "[Freud-OS] 2NDSTAGEBIN"
rebootmsg:        .asciz "Press any key to reboot.\r\n"
diskerror:        .asciz "Disk error. \r\n"
loadmsg:          .asciz "Loading [Freud-OS]...\r\n"

root_strt:   .byte 0,0      # hold offset do diretório raiz no disco
root_scts:   .byte 0,0      # mantém # setores no diretório raiz
file_strt:   .byte 0,0      # mantém o deslocamento do bootloader no disco

.fill (510-(.-main)), 1, 0  # Pad com nulos até 510 bytes (excl. Mágica de inicialização)
BootMagic:  .int 0xAA55     # palavra mágica para BIOS
