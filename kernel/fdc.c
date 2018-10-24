#include "include/system.h"

#define FLOPPY_PARAMS_ADDRESS = 0x000fefc7  /* Parâmetros de disquete residem nesse endereço físico. */
#define FLOPPY_PRIMARY_BASE   = 0x03f0      /* Endereço base para o FDC primário */
#define FLOPPY_SECONDARY_BASE = 0x0370      /* Endereço base para o secundário FDC */

/*
 * Deslocamentos para adicionar ao endereço base do FDC para obter registro:
 */
#define STATUS_REG_A             0x0000 /* PS2 SYSTEMS */
#define STATUS_REG_B             0x0001 /* PS2 SYSTEMS */
#define DIGITAL_OUTPUT_REG       0x0002
#define MAIN_STATUS_REG          0x0004
#define DATA_RATE_SELECT_REG     0x0004 /* PS2 SYSTEMS */
#define DATA_REGISTER            0x0005
#define DIGITAL_INPUT_REG        0x0007 /* AT SYSTEMS */
#define CONFIG_CONTROL_REG       0x0007 /* AT SYSTEMS */
#define PRIMARY_RESULT_STATUS    0x0000
#define SECONDARY_RESULT_STATUS  0x0000

/* 
 * Controller commands:
 */
#define FIX_DRIVE_DATA           0x03
#define CHECK_DRIVE_STATUS       0x04
#define CALIBRATE_DRIVE          0x07
#define CHECK_INTERRUPT_STATUS   0x08
#define FORMAT_TRACK             0x4D
#define READ_SECTOR              0x66
#define READ_DELETE_SECTOR       0xCC
#define READ_SECTOR_ID           0x4A
#define READ_TRACK               0x42
#define SEEK_TRACK               0x0F
#define WRITE_SECTOR             0xC5
#define WRITE_DELETE_SECTOR      0xC9
 
/*
 * Estrutura de parâmetros do disquete (encontrada em FLOPPY_PARAMS_ADDRESS
  * na memória física):
 */
typedef struct
{
  unsigned char steprate_headunload;
  unsigned char headload_ndma;
  unsigned char motor_delay_off;   /* especificado em pulsos de clock */
  unsigned char bytes_per_sector;
  unsigned char sectors_per_track;
  unsigned char gap_length;
  unsigned char data_length;        /* usado somente quando bytes por setor == 0 */
  unsigned char format_gap_length;
  unsigned char filler;
  unsigned char head_settle_time;   /* especificado em milissegundos */
  unsigned char motor_start_time;   /* especificado em 1/8 segundos */
} __attribute__ ((packed)) FLOPPY_PARAMS;

FLOPPY_PARAMS floppy_params;

/*
  * Leia os parâmetros do disquete da memória
  * estrutura:
  */
void read_floppy_params()
{
	memcpy((uint8*) &floppy_params, (uint8*) FLOPPY_PARAMS_ADDRESS, sizeof(FLOPPY_PARAMS));
}

void reset_fdc(uint8 base, char drive)
{
	outportb((base + DIGITAL_OUTPUT_REG), 0x00); /* Desativar controller */
	outportb((base + DIGITAL_OUTPUT_REG), 0x0c); /* Ativar controller */
}


