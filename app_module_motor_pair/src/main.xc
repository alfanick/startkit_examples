#include <xs1.h>
#include <platform.h>
#include <print.h>

#include <motors.h>


motors_t motors_pin = {
  { XS1_PORT_1E, XS1_PORT_1M },
  { XS1_PORT_1F, XS1_PORT_1N },
  XS1_PORT_4D
};

void logic(motors_client motors);

int main() {
  interface motors_i motors_interface;

  par {
    logic(motors_interface);
    motors(motors_interface, motors_pin);
  }

  return 0;
}

void logic(motors_client motors) {
  motors.left(PWM_PERCENT(80));
  motors.right(PWM_PERCENT(40));

}

