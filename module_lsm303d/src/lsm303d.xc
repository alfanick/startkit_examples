#include "lsm303d.h"

void lsm303d_init(lsm303d_t &pin) {
  unsigned char data[1];

  i2c_master_init(pin);

  // enable acc
  data[0] = 0b10100111;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x20, data, 1, pin);

  // acc = 8g
  data[0] = 0b00011000;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x21, data, 1, pin);

  // temp and high res
  data[0] = 0b11110100;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x24, data, 1, pin);

  // mag = 8g
  data[0] = 0b01000000;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x25, data, 1, pin);

  // enable mag
  data[0] = 0b00000000;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x26, data, 1, pin);

}

inline void lsm303d_read_vector(lsm303d_t &pin, unsigned char reg, vector3d &v) {
  unsigned char data[6];
  i2c_master_read_reg(LSM303D_ADDRESS, reg | (1 << 7), data, 6, pin);

  v.x = data[1] << 8 | data[0];
  v.y = data[3] << 8 | data[2];
  v.z = data[5] << 8 | data[4];
}

inline void lsm303d_read_accelerometer(lsm303d_t &pin, vector3d &v) {
  lsm303d_read_vector(pin, 0x28, v);
}

inline void lsm303d_read_magnetometer(lsm303d_t &pin, vector3d &v) {
  lsm303d_read_vector(pin, 0x08, v);
}

void lsm303d(interface lsm303d_i server i, lsm303d_t &pin) {
  unsigned time;
  timer t;
  vector3d acc, mag;

  lsm303d_init(pin);

  t :> time;

  while (1) {
    select {
      case i.accelerometer_raw() -> vector3d v:
        break;
      case i.accelerometer() -> vector3d v:
        v = acc;
        break;
      case i.magnetometer_raw() -> vector3d v:
        break;
      case i.magnetometer() -> vector3d v:
        v = mag;
        break;

      case t when timerafter(time) :> void:
        lsm303d_read_accelerometer(pin, acc);
        lsm303d_read_magnetometer(pin, mag);

        time += 10 * XS1_TIMER_KHZ;
        break;
    }
  }

}
