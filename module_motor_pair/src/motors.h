#ifndef ALJ_MOTORS_H
#define ALJ_MOTORS_H

#include <xs1.h>
#include <platform.h>

#define PWM_SCALE 200000
#define PWM_RESOLUTION 2000
#define PWM_PERCENT(x) ( (x) * PWM_RESOLUTION / 100 )

#define MOTOR_PULSES 64

struct motor_t {
  out port disable;
  in port status;
};
typedef struct motor_t motor_t;

struct motors_t {
  motor_t left;
  motor_t right;

  out port directions;
  in port sensors;
};
typedef struct motors_t motors_t;

interface motor_i {
  void set(unsigned speed);

  [[notification]]
  slave void status_changed(void);

  [[clears_notification]]
  int status();
};

interface motors_status_i {
  [[notification]]
  slave void changed(void);

  [[clears_notification]]
  { int, int } get();
};
typedef interface motors_status_i client motors_status_client;

interface motors_i {
  void left(signed speed);
  void right(signed speed);

  int left_rpm();
  int right_rpm();
};
typedef interface motors_i client motors_client;

[[combinable]]
void motor(interface motor_i server i, motor_t &pin);

[[combinable]]
void motors_logic(interface motors_i server i, interface motors_status_i server status,
    interface motor_i client left,
    interface motor_i client right,
    out port directions,
    in port sensors);


#endif

/* vim: set ft=xc: */
