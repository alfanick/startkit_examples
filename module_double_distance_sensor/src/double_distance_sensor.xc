#include "double_distance_sensor.h"

#include <print.h>

[[combinable]]
void double_distance_sensor(interface double_distance_sensor_i server i, double_distance_sensor_t &pin) {
  timer t;
  unsigned time;
  unsigned delta = -1;
  unsigned last_raw = -1;
  unsigned current_time;
  unsigned state = 0;
  unsigned measure = 0;

  set_port_pull_down(pin.echo);

  t :> time;
  while (1) {
    select {
      case i.frequency(unsigned freq):
        delta = freq == 0 ? -1 : (XS1_TIMER_HZ / freq);
        break;

      case i.read() -> {unsigned distance_a, unsigned distance_b}:
        distance_a = distance_b = last_raw / 2 * 340 / XS1_TIMER_KHZ;
        break;

      case i.read_raw() -> {unsigned time_a, unsigned time_b}:
        time_a = time_b = last_raw;
        break;

      case (delta != -1) => t when timerafter(time) :> void:
        // send trigger pulse
        measure = 0;
        pin.trigger <: 1;
        time += 100 * XS1_TIMER_MHZ;
        t when timerafter(time) :> void;
        pin.trigger <: 0;

        // wait for response
        state = 0;
        measure = 1;

        // next measurement
        time += delta;
        break;

      case measure => pin.echo when pinsneq(state) :> state:
        // end of wave
        if (!state) {
          t :> current_time;
          last_raw = current_time - measure;
          measure = 0;
        } else {
          t :> measure;
        }
        break;
    }
  }
}
