#include "bluetooth.h"

[[combinable]]
void bluetooth_uart(interface bluetooth_i server i, streaming chanend bin, streaming chanend bout) {
  unsigned char buffer[128];
  int position = 0;

  while (1) {
    select {
      case i.send(const unsigned char* data, int length):
        for (int i = 0; i < length; i++)
          bout <: data[i];
        break;

      case i.read(unsigned char data[], int &length):
        length = position;
        for (int i = 0; i < length; i++)
          data[i] = buffer[i];
        data[length] = '\0';
        position = 0;
        break;

      case bin :> unsigned char symbol:
        if (symbol == '\r') {
          i.incoming();
          break;
        }

        buffer[position++] = symbol;
        break;
    }
  }
}

