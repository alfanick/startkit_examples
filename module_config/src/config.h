#ifndef MODULE_CONFIG_H_
#define MODULE_CONFIG_H_

#include <flashlib.h>

typedef fl_SPIPorts config_flash_port;

void config_open(config_flash_port&);
void config_save(int position, const int data[], const static int size);
void config_read(int position, int data[], const static int size);
void config_close();

#endif
