#ifndef ALJ_IMU10_H
#define ALJ_IMU10_H

#include <i2c.h>

#ifndef LSM303D_ADDRESS
#define LSM303D_ADDRESS 0b0011101
#endif

#ifndef L3GD20H_ADDRESS
#define L3GD20H_ADDRESS 0b1101011
#endif

typedef r_i2c imu10_t;

typedef struct vector3d {
  short x;
  short y;
  short z;
} vector3d;

interface imu10_i {
  void accelerometer_raw(vector3d &v);
  void accelerometer(vector3d &v);
  float accelerometer_pitch();

  void magnetometer_raw(vector3d &v);
  void magnetometer(vector3d &v);

  void gyroscope_raw(vector3d &v);
  void gyroscope(vector3d &v);
  float gyroscope_pitch();

  float get_pitch();

  int get_lowpass();
  void set_lowpass(int i);
};

typedef interface imu10_i client imu10_client;

float kalman_filter(float, float, float, float, float, float);

void imu10_init(imu10_t &pin);

inline void read_vector(unsigned char address, imu10_t &pin, unsigned char reg, vector3d &v);

inline void lsm303d_read_accelerometer(imu10_t &pin, vector3d &v);
inline void lsm303d_read_magnetometer(imu10_t &pin, vector3d &v);
inline void l3gd20h_read_gyroscope(imu10_t &pin, vector3d &v);

[[combinable]]
void imu10(interface imu10_i server i, imu10_t &pin);

#endif
/* vim: set ft=xc: */
