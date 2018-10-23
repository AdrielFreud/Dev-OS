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

#
# Grava string no DS: SI para a tela.
# String deve ser terminada com NULL.
#
# Esta função usa em 10h / ah = 0xe (saída de vídeo - teletipo).
#
.func WriteString
 WriteString:
  lodsb                   # load byte at ds:si em al (avançando si)
  or     al, al           # teste se o caractere é 0 (end)
  jz     WriteString_done # Pula para o final se for 0.
  
  mov    ah, 0xe          # Subfunção 0xe de int 10h (video teletype output).
  mov    bx, 9            # Seta bh (page number) para 0, e bl (attribute) para branco (9).
  int    0x10             # Chama interreupção de BIOS.
  
  jmp    WriteString      # Repita para o próximo caractere.
 
 WriteString_done:
  retw
.endfunc

#
# Exibe 'pressione qualquer tecla', aguarda a chave e faz com que o BIOS seja reinicializado
# Esta função usa a interrupção da BIOS 16h, subfunção 0 para ler um
# pressione o botão.
#
.func Reboot
 Reboot:
  lea    si, rebootmsg    # Carregar endereço da mensagem de reinicialização em si
  call   WriteString      # printa a string
  xor    ax, ax           # subfuction 0
  int    0x16             # ligue para o bios para esperar pela chave

  .byte  0xEA             # linguagem de máquina para pular para FFFF:0000 (reboot)
  .word  0x0000
  .word  0xFFFF
.endfunc

# Leia setor com endereço lógico (LBA) AX em dados
# buffer no ES: BX.
# Esta função usa a interrupção 13h, subfunção ah = 2.
.func ReadSector
ReadSector:
  xor     cx, cx                      # Set try count = 0

 readsect:
  push    ax                          # Armazena o bloco lógico
  push    cx                          # Tenta Armazenar o Numero
  push    bx                          # Armazena o deslocamento do buffer de dados
   
  # Calculate cylinder, head and sector:
  # Cylinder = (LBA / SectorsPerTrack) / NumHeads
  # Sector   = (LBA mod SectorsPerTrack) + 1
  # Head     = (LBA / SectorsPerTrack) mod NumHeads
    
  mov     bx, iTrackSect              # Pega setores por faixa
  xor     dx, dx
  div     bx                          # Divide (dx:ax/bx to ax,dx)
                                      # Quotient (ax) =  LBA / SectorsPerTrack
                                      # Remainder (dx) = LBA mod SectorsPerTrack
  inc     dx                          # Adicionar 1 ao restante, desde setor
  mov     cl, dl                      # Armazena o resultado no cl para a chamada int 13h.
  
  mov     bx, iHeadCnt                # Obter número de cabeças
  xor     dx, dx
  div     bx                          # Divide (dx:ax/bx to ax,dx)
                                      # Quotient (ax) = Cylinder
                                      # Remainder (dx) = head
  mov     ch, al                      # ch = cylinder                      
  xchg    dl, dh                      # dh = head number
  
  # Chame a interrupção int 0x13, subfunção 2 para
  # leia o setor.
  # al = número de setores
  # ah = SubFunçoes 2
  # cx = número do setor
  # dh = numbero de cabeçalho
  # dl = numero de driver
  # es:bx = buffer de dados
  # Se falhar, o flag de transporte será definido.
  mov     ax, 0x0201                  # Subfunção 2, leia 1 setor
  mov     dl, iBootDrive              # desta unidade
  pop     bx                          # Restaurar o deslocamento do buffer de dados.
  int     0x13
  jc      readfail
  
  # No sucesso, retorne ao chamador.
  pop     cx                          # Descartar o número da tentativa
  pop     ax                          # Obter bloco lógico da pilha
  ret

  # A leitura falhou.
  # Repetiremos quatro vezes o total e, em seguida, passaremos para a falha de inicialização.
 readfail:   
  pop     cx                          # Obter o número da tentativa            
  inc     cx                          # Próxima tentativa
  cmp     cx, word ptr 4              # Pare em 4 tentativas
  je      bootFailure

  # Redefinir o sistema de disco:
  xor     ax, ax
  int     0x13
  
  # Obtenha o bloco lógico da pilha e tente novamente.
  pop     ax
  jmp     readsect
.endfunc
