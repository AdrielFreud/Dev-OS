#ifndef __SYSTEM_H
#define __SYSTEM_H

/*
 * Define types.
 */
typedef signed char          int8;
typedef unsigned char        uint8;
typedef short                int16;
typedef unsigned short       uint16;
typedef int                  int32;
typedef unsigned             uint32;

/* Memory */
extern uint8 *memcpy(uint8 *dest, const uint8 *src, uint32 count);
extern uint16 *memcpyw(uint16 *dest, const uint16 *src, uint32 count);
extern uint8 *memset(uint8 *dest, uint8 val, uint32 count);
extern uint16 *memsetw(uint16 *dest, uint16 val, uint32 count);

/* String */
extern uint32 strlen(char *str);

/* Ports */
extern uint8 inportb (uint16 _port);
extern void outportb (uint16 _port, uint8 _data);

/* Display */
extern void settextcolor(uint8 forecolor, uint8 backcolor);
extern void cls();
extern void puts(char *text);
extern void init_video();

/* ISR */
extern void install_idt();
extern void install_isrs();

/* System */
extern void io_wait();

#endif