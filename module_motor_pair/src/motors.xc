#include "motors.h"

[[combinable]]
void motor(interface motor_i server i, motor_t &pin) {
  timer t;
  unsigned duty = 0, state = 0, time, status;
  const unsigned delay = XS1_TIMER_HZ / PWM_SCALE;

  t :> time;
  pin.status :> status;

  while (1) {
    select {
      case i.set(unsigned speed):
        duty = speed;
        break;

      case pin.status when pinsneq(status) :> status:
        i.status_changed();
        break;

      case i.status() -> int s:
        s = status;
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
#define SIGN(x) ((x) > 0 ? 1 : (x) < 0 ? -1 : 0)
#define UPDATE(where, shift, value) (where) = ((where) & (~(3 << (shift)))) | ((value) << (shift))
#define DIRECTION(previous, current, rpm) ( (previous == 0b00 && current == 0b10) || \
                                            (previous == 0b01 && current == 0b00) || \
                                            (previous == 0b11 && current == 0b01) || \
                                            (previous == 0b10 && current == 0b11) ? -1 : \
                                            (previous == 0b00 && current == 0b01) || \
                                            (previous == 0b01 && current == 0b11) || \
                                            (previous == 0b11 && current == 0b10) || \
                                            (previous == 0b10 && current == 0b00) ? 1 : \
                                            (SIGN(rpm) | 1) )

{ int, int } hall_update(unsigned hall, timer t) {
  unsigned current_state, current_time;
  static int rpm[2] = { 1, 1 };
  static unsigned time[2][2] = { {0, 0}, {0, 0} };
  static unsigned state[2];

  t :> current_time;

  current_state = (hall & 0b1100) >> 2;
  if (state[0] != current_state) {
    rpm[0] = DIRECTION(state[0], current_state, rpm[0]);
    state[0] = current_state;
    time[0][1] = time[0][0];
    time[0][0] = current_time;
  }

  current_state = (hall & 0b0011);
  if (state[1] != current_state) {
    rpm[1] = -DIRECTION(state[1], current_state, rpm[1]);
    state[1] = current_state;
    time[1][1] = time[1][0];
    time[1][0] = current_time;
  }

  if (time[0][1] != 0) {
    rpm[0] *= 60 * XS1_TIMER_HZ / (time[0][0] - time[0][1]) / 1216;
  }

  if (time[1][1] != 0) {
    rpm[1] *= 60 * XS1_TIMER_HZ / (time[1][0] - time[1][1]) / 1216;
  }

  return { rpm[1], rpm[0] };
}

[[combinable]]
void motors_logic(interface motors_i server i,
                  interface motors_status_i server status,
                  interface motor_i client left,
                  interface motor_i client right,
                  out port directions, in port sensors) {
  unsigned current_directions = 0b0000;
  unsigned hall;
  timer t;
  unsigned time;
  int left_rpm = 0, right_rpm = 0;

  t :> time;
  sensors :> hall;
  { left_rpm, right_rpm } = hall_update(hall, t);

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
        rpm = left_rpm;
        break;

      case i.right_rpm() -> int rpm:
        rpm = right_rpm;
        break;

      case left.status_changed():
        status.changed();
        break;

      case right.status_changed():
        status.changed();
        break;

      case status.get() -> { int l, int r }:
        l = left.status();
        r = right.status();
        break;

      case t when timerafter(time) :> void:
        left_rpm = 0;
        right_rpm = 0;
        time += 1000 * XS1_TIMER_KHZ;
        break;

      case sensors when pinsneq(hall) :> hall:
        { left_rpm, right_rpm } = hall_update(hall, t);
        break;
    }
  }

}

