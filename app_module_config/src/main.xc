#include <xs1.h>
#include <platform.h>
#define DEBUG_PRINT_ENABLE 1
#include <debug_print.h>

#include "config.h"
enum config_properties {
  BALANCER_SPEED_BOOST = 0,
  BALANCER_SPEED_THRESHOLD = 1,
  BALANCER_TARGET = 2,
  BALANCER_PID = 3,
  BALANCER_PID_LOWPASS = 6,
  BALANCER_ANGLE_LOWPASS = 7,
  BALANCER_LOOPDELAY = 8,
  EOF = 9
};
config_flash_port flash_memory = {
  PORT_SPI_MISO,
  PORT_SPI_SS,
  PORT_SPI_CLK,
  PORT_SPI_MOSI,
  XS1_CLKBLK_1
};


void logic();

int main() {

  par {
    logic();
  }

  return 0;
}

void logic() {
  int a[9] = {3, 3, 3, 123,-1563,3, 3, 3, 3};
  int r[3];

  config_open(flash_memory);

  config_save(0, a, 9);

  config_read(BALANCER_PID, r, 3);

  config_close();

  debug_printf("%d %d %d\n", r[0], r[1], r[2]);
}

