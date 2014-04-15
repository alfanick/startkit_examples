#ifndef ALJ_MOTOR_H
#define ALJ_MOTOR_H

#include <xs1.h>
#include <platform.h>

#define PWM_SCALE 2
#define PWM_RESOLUTION 10000
#define PWM_PERCENT(x) ( (x) * PWM_RESOLUTION / 100 )

#define MOTOR_PULSES 64

struct motor_t {
  out port enable;
  out port a;
  out port b;

  in port ?hall[2];
};

interface motor_i {
  void set(signed speed);

  { unsigned, signed char } rpm();
};

typedef interface motor_i client motor_client;

[[combinable]]
void motor(interface motor_i server i, struct motor_t &pin);


#endif
