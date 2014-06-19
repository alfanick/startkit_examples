#include <xs1.h>
#include <platform.h>
#include <print.h>

#include <double_distance_sensor.h>

struct double_distance_sensor_t distance_sensors = {
  XS1_PORT_1M, XS1_PORT_1L
};

void logic(interface double_distance_sensor_i client distance);

int main() {
  interface double_distance_sensor_i distance;

  par {
    logic(distance);

    double_distance_sensor(distance, distance_sensors);
  }

  return 0;
}

void logic(interface double_distance_sensor_i client distance) {
  distance.frequency(17);

  unsigned front, back;
  timer t; unsigned time;
  t :> time;

  while (1) {
    t when timerafter(time) :> void;
    time += 1000 * XS1_TIMER_KHZ;
    { front, back } = distance.read();
    printuintln(front);
    printuintln(back);
    printstrln("");
  }
}
