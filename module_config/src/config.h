#ifndef MODULE_CONFIG_H_
#define MODULE_CONFIG_H_

#include <flashlib.h>

typedef fl_SPIPorts config_flash_port;

void config_save(config_flash_port& p, int position, const int data[], const static int size, unsigned char page[]);
void config_read(config_flash_port& p, int position, int data[], const static int size, unsigned char page[]);

#endif
