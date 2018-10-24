#include "include/system.h"

uint32 strlen(char *str)
{
  uint32 retval;
  for(retval = 0; *str != '\0'; str++) retval++;
  return retval;
}

