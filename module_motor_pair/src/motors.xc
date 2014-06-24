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

[[combinable]]
void motors_logic(interface motors_i server i, interface motor_i client left, interface motor_i client right, out port directions) {
  unsigned current_directions = 0b0000;

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
    }
  }

}

