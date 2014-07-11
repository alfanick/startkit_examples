#include "config.h"

#include <flashlib.h>

#define CONFIG_PAGE_SIZE 256

void config_open(config_flash_port &ports) {
  const fl_DeviceSpec flash_chip = FL_DEVICE_WINBOND_W25X20;

  fl_connectToDevice(ports, &flash_chip, 1);
}

void config_close() {
  fl_disconnect();
}


void config_save(int position, const int data[], const static int size) {
  unsigned char page[256];

  position *= 4;

  fl_readDataPage(0, page);
  for (int i = 0; i < size; i++)
    for (int j = 0; j < 4; j++)
      page[position + i*4 + j] = data[i] >> (j*8);
  fl_writeDataPage(0, page);
}

void config_read(int position, int data[], const static int size) {
  unsigned char page[256];

  position *= 4;

  fl_readDataPage(0, page);

  for (int i = 0; i < size; i++) {
    data[i] = 0;
    for (int j = 0; j < 4; j++)
      data[i] |= page[position + i*4 + j] << (j*8);
  }
}
