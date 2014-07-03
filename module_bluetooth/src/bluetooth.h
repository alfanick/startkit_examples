#ifndef ALJ_MODULE_BLUETOOTH_H
#define ALJ_MODULE_BLUETOOTH_H

interface bluetooth_i {
  void send(const char* data, int length);

  void send_number(int i);
  void send_numbers(int a[], int n);

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
