#ifndef ALJ_DISTANCE_SENSOR_H
#define ALJ_DISTANCE_SENSOR_H

#include <xs1.h>
#include <platform.h>

struct double_distance_sensor_t {
  out port trigger;
  in port echo;
};
typedef struct double_distance_sensor_t double_distance_sensor_t;

interface double_distance_sensor_i {
  {unsigned, unsigned} read();
  {unsigned, unsigned} read_raw();
  void frequency(unsigned freq);
};
typedef interface distance_sensor_i client distance_sensor_client;

[[combinable]]
void double_distance_sensor(interface double_distance_sensor_i server i, double_distance_sensor_t &pin);


#endif
