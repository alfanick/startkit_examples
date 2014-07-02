#ifndef ALJ_MODULE_BLUETOOTH_H
#define ALJ_MODULE_BLUETOOTH_H

interface bluetooth_i {
  void send(const char* data, int length);

  [[notification]]
  slave void incoming();

  [[clears_notification]]
  void read(char data[], int &length);
};
typedef interface bluetooth_i client bluetooth_client;

[[combinable]]
void bluetooth_uart(interface bluetooth_i server i, streaming chanend bin, streaming chanend bout);

#endif

/* vim: set ft=xc: */
