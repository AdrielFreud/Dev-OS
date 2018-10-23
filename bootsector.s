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

bootsector:
 iOEM:        .ascii "DevOS   "    # OEM String
 iSectSize:   .word  0x200         # Bytes por setor
 iClustSize:  .byte  1             # Setores por cluster
 iResSect:    .word  1             # #of setores reservados
 iFatCnt:     .byte  2             # #of FAT cópias
 iRootSize:   .word  224           # tamanho do diretório raiz
 iTotalSect:  .word  2880          # total # de setores abaixo de 32 MB
 iMedia:      .byte  0xF0          # Descritor de Mídia
 iFatSize:    .word  9             # Tamanho de cada FAT
 iTrackSect:  .word  9             # Setores por faixa
 iHeadCnt:    .word  2             # número de cabeças de leitura/gravação
 iHiddenSect: .int   0             # número de setores ocultos
 iSect32:     .int   0             # # setores com mais de 32 MB
 iBootDrive:  .byte  0             # detém unidade que o setor de inicialização veio
 iReserved:   .byte  0             # reservado, vazio
 iBootSign:   .byte  0x29          # assinatura do setor de inicialização estendida
 iVolID:      .ascii "seri"        # Serial de Disco
 acVolLabel:  .ascii "MYVOLUME   " # apenas espaço reservado. Ainda não usamos rótulos de volume.
 acFSType:    .ascii "FAT16   "    # Tipo de sistema de arquivos como (NTFS, FAT32).
/* end boot sector */
