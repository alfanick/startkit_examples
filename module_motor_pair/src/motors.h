#ifndef ALJ_MOTORS_H
#define ALJ_MOTORS_H

#include <xs1.h>
#include <platform.h>

#define PWM_SCALE 10
#define PWM_RESOLUTION 50000
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
};
typedef struct motors_t motors_t;

interface motor_i {
  void set(unsigned speed);
};

interface motors_i {
  void left(signed speed);
  void right(signed speed);
};
typedef interface motors_i client motors_client;

[[combinable]]
void motor(interface motor_i server i, motor_t &pin);

void motors(interface motors_i server i, motors_t &pin);


#endif
