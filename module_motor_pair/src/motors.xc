#include "motors.h"

[[combinable]]
void motor(interface motor_i server i, motor_t &pin) {
  timer t;
  unsigned duty = 0, state = 0, time;

  t :> time;

  while (1) {
    select {
      case i.set(unsigned speed):
        if (speed > 0) {
          duty = speed;
          pin.disable <: 0;
        } else {
          duty = 0;
          pin.disable <: 1;
        }
        break;

      case duty != 0 => t when timerafter(time) :> void:
        pin.disable <: !state;
        time += PWM_SCALE * (state ? duty : (PWM_RESOLUTION - duty));
        state = !state;

        break;
    }
  }
}

#define ABS(x) ((x) > 0 ? (x) : -(x))

void motors_logic(interface motors_i server i, interface motor_i client left, interface motor_i client right, out port directions) {
  directions <: 0b1001;

  while (1) {
    select {
      case i.left(signed speed):
        left.set(ABS(speed));
        break;

      case i.right(signed speed):
        right.set(ABS(speed));
        break;
    }
  }

}

void motors(interface motors_i server i, motors_t &pin) {
  interface motor_i left, right;

  par {
    motors_logic(i, left, right, pin.directions);

//    [[combine]]
 //   par {
      motor(left, pin.left);
      motor(right, pin.right);
  //  }
  }

}

