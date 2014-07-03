#include "bluetooth.h"
#include <platform.h>

void send(streaming chanend bout, const unsigned char* data, int length) {
  for (int i = 0; i < length; i++) {
    bout <: data[i];
  }
}

void reverse(unsigned char* a, int l) {
  unsigned char t;
  for (int i = 0; i <= l/2; i++) {
    t = a[i];
    a[i] = a[l-i];
    a[l-i] = t;
  }
}

void send_number(streaming chanend bout, int number) {
  unsigned char representation[32] = "";
  int length = 0;
  int original = number;

  if (number < 0)
    number = -number;
  else if (number == 0)
    representation[length++] = '0';

  while (number != 0) {
    int digit = number % 10;
    representation[length++] = (digit > 9)? (digit - 10) + 'a' : digit + '0';
    number /= 10;
  }

  if (original < 0)
    representation[length++] = '-';

  reverse(representation, length-1);

  send(bout, representation, length);
}


[[combinable]]
void bluetooth_uart(interface bluetooth_i server i, streaming chanend bin, streaming chanend bout) {
  unsigned char buffer[128];
  int position = 0;

  while (1) {
    select {
      case i.send(const unsigned char* data, int length):
        send(bout, data, length);
        break;

      case i.send_number(int number):
        send_number(bout, number);
        bout <: '\r';
        break;

      case i.send_numbers(int a[], int n):
        for (int i = 0; i < n; i++) {
          send_number(bout, a[i]);

          bout <: i != n-1 ? ',' : '\r';
        }
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

