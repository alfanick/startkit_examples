#include "config.h"

#define DEBUG_PRINT_ENABLE 0
#include <debug_print.h>
#include <flashlib.h>

#define CONFIG_PAGE_SIZE 256

void config_save(config_flash_port &ports, int position, const int data[], const static int size, unsigned char page[]) {
  const fl_DeviceSpec flash_chip = FL_DEVICE_WINBOND_W25X20;

  if (0 != fl_connectToDevice(ports, &flash_chip, 1))
    debug_printf("cannot connect in read\n");
  position *= 4;

//  for (int i = 0; i < 256; i++)
//    page[i] = 0;

  if (0 != fl_readDataPage(0, page))
    debug_printf("cant read in save\n");

  fl_eraseDataSector(0);

  for (int i = 0; i < size; i++) {
    for (int j = 0; j < 4; j++) {
      page[position + i*4 + j] = data[i] >> (j*8);
      debug_printf("%d ", (unsigned char)(data[i] >> (j*8)));
    }
    debug_printf("\n");
  }
  if (0 != fl_writeDataPage(0, page))
    debug_printf("cant write\n");

  debug_printf("after write\n");
}

void config_read(config_flash_port &ports, int position, int data[], const static int size, unsigned char page[]) {
  const fl_DeviceSpec flash_chip = FL_DEVICE_WINBOND_W25X20;

  if (0 != fl_connectToDevice(ports, &flash_chip, 1))
    debug_printf("cannot connect in read\n");
  position *= 4;

  if (0 !=fl_readDataPage(0, page))
    debug_printf("cant read in read\n");

  for (int i = 0; i < size; i++) {
    data[i] = 0;
    for (int j = 0; j < 4; j++) {
      data[i] |= page[position + i*4 + j] << (j*8);
      debug_printf("%d ", page[position + i*4 + j]);
    }
    debug_printf("\n");
  }

  fl_disconnect();
}
