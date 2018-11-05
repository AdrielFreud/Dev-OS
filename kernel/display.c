#include "include/system.h"

#define VIDEO_SEGMENT 0xB8000

uint16 *textmemptr;
uint8 attrib = 0x07;
uint8 csr_x = 0;
uint8 csr_y = 0;

/* Rola a tela */
void scroll(void)
{
  uint16 blank;
  uint16 temp;

  /* Um espaço em branco é definido como um espaço ... precisamos dar backcolor também */
  blank = 0x20 | (attrib << 8);

  /* A linha 25 é o fim, isso significa que precisamos rolar para cima */
  if(csr_y >= 25)
  {
    /* Mova o trecho de texto atual que compõe a tela de volta no buffer por uma linha */
    temp = csr_y - 25 + 1;
    memcpyw (textmemptr, textmemptr + temp * 80, (25 - temp) * 80 * 2);

    /* Finalmente, definimos o pedaço de memória que ocupa a última linha do texto para o caractere 'em branco' */
    memsetw (textmemptr + (25 - temp) * 80, blank, 80);
    csr_y = 25 - 1;
  }
}

/* Atualiza o cursor do hardware: a pequena linha piscando na tela sob o último caractere pressionado! */
void move_csr(void)
{
  uint16 offset;

  /* A equação para encontrar o índice em um pedaço linear de memória pode ser representada por:
  * Índice = [(y * largura) + x] */
  offset = csr_y * 80 + csr_x;

  /* Isso envia um comando para os índices 14 e 15 no
   * CRT Control Register do controlador VGA. Estes
   * são os bytes altos e baixos do índice que mostram
   * onde o cursor do hardware deve estar 'piscando'. Para
   * aprenda mais, você deve procurar algum tipo específico de VGA
   * documentos de programação. Um ótimo começo para gráficos:
   * http://www.brackeen.com/home/vga */

  outportb(0x3D4, 14);
  outportb(0x3D5, offset >> 8);
  outportb(0x3D4, 15);
  outportb(0x3D5, offset);
}

void cls()
{
  /* Preencha a tela com espaços em branco (com o atributo atual) */  
  uint16 blank = 0x20 | (attrib << 8);
  memsetw ((uint16*) textmemptr, blank, 80 * 25);

  /* Mover o cursor do hardware para 0,0. */
  csr_x = 0;
  csr_y = 0;
  move_csr();
}


/* Coloca um único caractere na tela */
void putch(char c)
{
  uint16 *where;
  uint16 att = attrib << 8;

  /* Lidar com um backspace, movendo o cursor de volta um espaço */
  if(c == 0x08)
  {
      if(csr_x != 0) csr_x--;
  }
  /* Lida com uma guia incrementando o x do cursor, mas somente
  * até um ponto que o tornará divisível por 8 */
  else if(c == 0x09)
  {
      csr_x = (csr_x + 8) & ~(8 - 1);
  }
  /* Lida com um 'retorno de carro', que simplesmente traz o
  * cursor de volta para a margem */
  else if(c == '\r')
  {
      csr_x = 0;
  }
  /* Nós lidamos com nossas novas linhas como o DOS e o BIOS fazem: nós
  * Trate como se um 'CR' também estivesse lá, então nós trazemos o
  * cursor para a margem e incrementamos o valor 'y' */
  else if(c == '\n')
  {
      csr_x = 0;
      csr_y++;
  }
  /* Qualquer caractere maior que e incluindo um espaço, é um
   * personagem imprimível. A equação para encontrar o índice
   * em um pedaço linear de memória pode ser representado por:
   * Índice = [(y * largura) + x] */
  else if(c >= ' ')
  {
      where = textmemptr + (csr_y * 80 + csr_x);
      *where = c | att; /*Caractere e atributos: cor */
      csr_x++;
  }

  /* Se o cursor atingiu a borda da largura da tela,
  * insira uma nova linha lá */
  if(csr_x >= 80)
  {
      csr_x = 0;
      csr_y++;
  }

  /* Role a tela, se necessário, e finalmente mova o cursor */
  scroll();
  move_csr();
}

/* Usa a rotina acima para gerar uma string ...*/
void puts(char *text)
{
  uint32 len = strlen(text);
  uint32 i;

  for (i = 0; i < len; i++)
  {
    putch(text[i]);
  }
}

/* Define o forecolor e o backcolor que usaremos */
void settextcolor(uint8 forecolor, uint8 backcolor)
{
  /* Os 4 primeiros bytes são o fundo, 4 bytes inferiores
    * são a cor do primeiro plano */
  attrib = (backcolor << 4) | (forecolor & 0x0F);
}

void init_video()
{
  settextcolor(124, 218);
  char* str = "Copyright by Adriel Freud. Dev-OS";
  textmemptr = (uint16*) 0xb8000;
  
  cls();
  mylabel:
    settextcolor(12, 21);
    puts(str);
    goto mylabel;
}
