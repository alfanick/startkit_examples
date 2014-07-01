#include "motors.h"

[[combinable]]
void motor(interface motor_i server i, motor_t &pin) {
  timer t;
  unsigned duty = 0, state = 0, time;
  const unsigned delay = XS1_TIMER_HZ / PWM_SCALE;

  t :> time;

  while (1) {
    select {
      case i.set(unsigned speed):
        duty = speed;
        break;

      case t when timerafter(time) :> void:
        if (duty == 0)
          pin.disable <: 0;
        else
          pin.disable <: (state++ >= duty);

        time += delay;

        if (state == PWM_RESOLUTION)
          state = 0;

        break;
    }
  }
}

#define ABS(x) ((x) > 0 ? (x) : -(x))
#define UPDATE(where, shift, value) (where) = ((where) & (~(3 << (shift)))) | ((value) << (shift))

void hall_update(unsigned hall, unsigned state[2], unsigned time[2][2], timer t) {
  unsigned current_state, current_time;

  t :> current_time;

  current_state = (hall & 0b1100) >> 2;
  if (state[0] != current_state) {
    state[0] = current_state;
    time[0][1] = time[0][0];
    time[0][0] = current_time;
  }

  current_state = (hall & 0b0011);
  if (state[1] != current_state) {
    state[1] = current_state;
    time[1][1] = time[1][0];
    time[1][0] = current_time;
  }
}

[[combinable]]
void motors_logic(interface motors_i server i,
                  interface motor_i client left,
                  interface motor_i client right,
                  out port directions, in port sensors) {
  unsigned current_directions = 0b0000;
  unsigned hall;
  unsigned hall_state[2];
  unsigned hall_time[2][2] = { {0, 0}, {0, 0} };
  timer t;
  unsigned time;

  t :> time;
  sensors :> hall;
  hall_update(hall, hall_state, hall_time, t);

  while (1) {
    select {
      case i.left(signed speed):
        if (speed > 0) {
          UPDATE(current_directions, 0, 0b10);
        } else
        if (speed < 0) {
          UPDATE(current_directions, 0, 0b01);
        } else {
          UPDATE(current_directions, 0, 0b00);
        }

        directions <: current_directions;
        left.set(ABS(speed));
        break;

      case i.right(signed speed):
        if (speed > 0) {
          UPDATE(current_directions, 2, 0b01);
        } else
        if (speed < 0) {
          UPDATE(current_directions, 2, 0b10);
        } else {
          UPDATE(current_directions, 2, 0b00);
        }

        directions <: current_directions;
        right.set(ABS(speed));
        break;

      case i.left_rpm() -> int rpm:
        if (hall_time[1][0] == 0)
          rpm = 0;
        else
          rpm = 64 * 60 * 1000 / (hall_time[1][0] - hall_time[1][1]);
        break;

      case i.right_rpm() -> int rpm:
        if (hall_time[0][0] == 0)
          rpm = 0;
        else
          rpm = 64 * 60 * 1000 / (hall_time[0][0] - hall_time[0][1]);
        break;

      case t when timerafter(time) :> void:
        hall_time[0][0] = 0;
        hall_time[1][0] = 0;
        hall_time[0][1] = 0;
        hall_time[1][1] = 0;
        time += 1000 * XS1_TIMER_KHZ;
        break;

      case sensors when pinsneq(hall) :> hall:
        hall_update(hall, hall_state, hall_time, t);
        break;
    }
  }

}

