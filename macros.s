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

# Inicialize vários segmentos:
# - O setor de inicialização é carregado pelo BIOS em 0: 7C00 (CS = 0)
# - CS, DS e ES estão definidos como zero.
# - O ponto de empilhamento está definido para 0x7C00 e aumentará a partir daí.
# - Interrupções podem não agir agora, então elas estão desativadas.
.macro mInitSegments
  cli                        
  mov  iBootDrive, dl    # salvar em qual unidade nós inicializamos (deve ser 0x0)
  mov  ax, cs            # CS é definido como 0x0, porque é onde o setor de inicialização é carregado (0:07c00)
  mov  ds, ax            # DS = CS = 0x0 
  mov  es, ax            # ES = CS = 0x0
  mov  ss, ax            # SS = CS = 0x0
  mov  sp, 0x7C00        # Pilha cresce do deslocamento 0x7C00 para 0x0000.
  sti
.endm
 
# Reinicie o sistema de disco.
# Isso é feito através da interrupção 0x13, subfunção 0.
# Se a reinicialização falhar, o carry está definido e saltamos para a reinicialização.
.macro mResetDiskSystem
  mov  dl, iBootDrive    # drive para redefinir
  xor  ax, ax            # subfuncao 0
  int  0x13              # chama interrupt 13h
  jc   bootFailure       # exibir mensagem de erro se transportar set (erro)  
.endm

# Escreva uma string para stdout.
# str = string para escrever
.macro mWriteString str
  lea    si,    \str
  call   WriteString
.endm

# Mostrar uma mensagem de erro no disco, aguarde a tecla,
# então reinicie.
.macro mReboot
  call   Reboot
.endm

# coloca o primeiro setor do bootloader em file_strt
# coloca # setores no bootloader em file_scts
# salta para bootFailure se o bootloader não for encontrado no diretório raiz
.macro mFindFile filename, loadsegment

  # O diretório raiz será carregado em um segmento superior.
  # Defina ES para este segmento.
  mov     ax, \loadsegment
  mov     es, ax
  
  # O número de setores que o diretório raiz ocupa
  # é igual ao seu número máximo de entradas, vezes 32 bytes por
  # entry, dividido pelo tamanho do setor.
  # Por exemplo. (32 * raízes) / 512
  # Isso normalmente produz 14 setores em um disco FAT12.
  # Nós calculamos este total, então o armazenamos em cx para uso posterior em um loop.
  mov     ax, 32
  xor     dx, dx
  mul     word ptr iRootSize
  div     word ptr iSectSize          # Divide (dx:ax,sectsize) -> (ax,dx)
  mov     cx, ax                      
  mov     root_scts, cx
  # root_scts é agora o número de setores no diretório raiz.
  
  # Calcular o diretório raiz do setor de inicialização:
  # root_strt = número de tabelas FAT * setores por FAT
  # + número de setores ocultos
  # + número de setores reservados
  xor   ax, ax                      # encontre o diretório raiz
  mov   al, byte ptr iFatCnt        # ax = número de tabelas FAT
  mov   bx, word ptr iFatSize       # bx = ssetor por FAT
  mul   bx                          # ax = #FATS * setor por FAT
  add   ax, word ptr iHiddenSect    # Adicionar setores ocultos ao AX
  adc   ax, word ptr iHiddenSect+2
  add   ax, word ptr iResSect       # Add reserved sectors to ax
  mov   root_strt, ax
  # root_strt é agora o número do primeiro setor raiz
  
  # Carrega um setor do diretório raiz.
  # Se a leitura do setor falhar, uma reinicialização ocorrerá.
  read_next_sector:
    push   cx
    push   ax
    xor    bx, bx
    call   ReadSector
    
  check_entry:
    mov    cx, 11                      # Nomes de arquivos de entradas de diretório são 11 bytes.
    mov    di, bx                      # es:di = Endereço de entrada de diretório
    lea    si, \filename               # ds:si = Endereço do nome do arquivo que estamos procurando.
    repz   cmpsb                       # Compare o nome do arquivo à memória.
    je     found_file                  # Se encontrado, pule fora.
    add    bx, word ptr 32             # Mover para a próxima entrada. Entradas completas são 32 bytes.
    cmp    bx, word ptr iSectSize      # Já saímos do setor?
    jne    check_entry                 # Se não, tente a próxima entrada de diretório.
    
    pop    ax
    inc    ax                          # verifique o próximo setor quando voltarmos
    pop    cx
    loopnz read_next_sector            # loop até encontrado ou não
    jmp    bootFailure                 # não foi possível encontrar o arquivo: abort
    
  found_file:
    # A entrada de diretório armazena o primeiro número de cluster do arquivo
    # no byte 26 (0x1a). BX ainda está apontando para o endereço do começo
    # da entrada do diretório, então vamos de lá.
    # Leia o número do cluster da memória:
    mov    ax, es:[bx+0x1a]
    mov    file_strt, ax
.endm

.macro mReadFAT fatsegment
    # O FAT será carregado em um segmento especial.
    # Defina ES para este segmento.
    mov   ax, \fatsegment
    mov   es, ax
  
    # Calcular o deslocamento do FAT:
    mov   ax, word ptr iResSect       # Adicionar setores reservados ao machado 
    add   ax, word ptr iHiddenSect    # Adicione setores ocultos ao machado
    adc   ax, word ptr iHiddenSect+2
  
    # Leia todos os setores FAT na memória:
    mov   cx, word ptr iFatSize       # Número de setores no FAT
    xor   bx, bx                      # Deslocamento de memória para ler (es:bx)
  read_next_fat_sector:
    push  cx
    push  ax
    call  ReadSector
    pop   ax
    pop   cx
    inc   ax
    add   bx, word ptr iSectSize
    loopnz read_next_fat_sector       # continua para o proximo setor
.endm

# Carrega um arquivo na memória no segmento especificado.
# - O número do setor lógico do file_start deve estar em file_strt
# - O tamanho do arquivo em setores deve estar em file_scts
.macro mReadFile loadsegment, fatsegment
    # Configure o segmento de memória que receberá o arquivo:
    mov     ax, \loadsegment
    mov     es, ax
    # Definir deslocamento de memória para carregamento em 0.
    xor     bx, bx
        
    # Definir o segmento de memória para FAT:
    mov     cx, file_strt             # CX agora aponta para a primeira entrada FAT do arquivo
    
  read_file_next_sector:
    # Localize setor:
    mov     ax, cx                    # O setor a ser lido é igual à entrada atual do FAT
    add     ax, root_strt             # Além do início do diretório raiz
    add     ax, root_scts             # Além disso, o tamanho do diretório raiz
    sub     ax, 2                     # ... mais o menos 2
    
    # Leia setor:
    push    cx                        # Leia um setor do disco, mas salve CX
    call    ReadSector                # como contém nossa entrada FAT
    pop     cx
    add     bx, iSectSize             # Mover o ponteiro da memória para a próxima seção
    
    # Obtenha o próximo setor do FAT:
    push    ds                        # Faça o DS:SI aponte para a tabela FAT
    mov     dx, \fatsegment           # Em Memoria.
    mov     ds, dx
    
    mov     si, cx                    # Faça o SI apontar para a entrada atual do FAT
    mov     dx, cx                    # (offset é o valor de entrada * 1.5 bytes)
    shr     dx
    add     si, dx
    
    mov     dx, ds:[si]               # Leia a entrada FAT da memória
    test    dx, 1                     # Veja qual caminho mudar
    jz      read_next_file_even
    and     dx, 0x0fff
    jmp     read_next_file_cluster_done
read_next_file_even:    
    shr     dx, 4
read_next_file_cluster_done:    
    pop     ds                        # Restaurar o DS para o segmento de dados normal
    mov     cx, dx                    # Armazene a nova entrada FAT no CX
    cmp     cx, 0xff8                 # Se a entrada FAT for maior ou igual
    jl      read_file_next_sector     # para 0xff8, então chegamos ao fim do arquivo
.endm

.macro mStartSecondStage
    # Faça es e ds apontarem para o segmento em que o segundo estágio foi carregado.
    mov     ax, word ptr LOAD_SEGMENT
    mov     es, ax
    mov     ds, ax
    # Saltar para o início do segundo estágio:  
    jmp     LOAD_SEGMENT:0
.endm