#include "imu10.h"

#include <math.h>

#define MIN(a,b) ((b) ^ (((a) ^ (b)) & -((a) < (b))))
#define MAX(a,b) ((a) ^ (((a) ^ (b)) & -((a) < (b))))

void imu10_init(imu10_t &pin) {
  unsigned char data[1];
  i2c_master_init(pin);

  // LSM303D Config

  //    Enable XYZ
  //    1600Hz Acc
  data[0] = 0b10100111;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x20, data, 1, pin);

  //     773Hz AA
  data[0] = 0b00000000;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x21, data, 1, pin);

  //     Compass High Resolution
  //     50Hz Compass
  data[0] = 0b01110000;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x24, data, 1, pin);

  //     2 Gauss Compass
  data[0] = 0b00000000;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x25, data, 1, pin);

  //     Normal Mode
  //     Enable Compass
  data[0] = 0b00000000;
  i2c_master_write_reg(LSM303D_ADDRESS, 0x26, data, 1, pin);


  // L3GD20H Config

  //    Enable XYZ
  //    100Hz
  data[0] = 0b00111111;
  i2c_master_write_reg(L3GD20H_ADDRESS, 0x20, data, 1, pin);
}

inline void read_vector(unsigned char address, imu10_t &pin, unsigned char reg, vector3d &v) {
  unsigned char data[6];
  i2c_master_read_reg(address, reg | (1 << 7), data, 6, pin);

  v.x = data[1] << 8 | data[0];
  v.y = data[3] << 8 | data[2];
  v.z = data[5] << 8 | data[4];
}

inline void lsm303d_read_accelerometer(imu10_t &pin, vector3d &v) {
  read_vector(LSM303D_ADDRESS, pin, 0x28, v);
}

inline void lsm303d_read_magnetometer(imu10_t &pin, vector3d &v) {
  read_vector(LSM303D_ADDRESS, pin, 0x08, v);
}

inline void l3gd20h_read_gyroscope(imu10_t &pin, vector3d &v) {
  read_vector(L3GD20H_ADDRESS, pin, 0x28, v);
}

inline int median(int a, int b, int c) {
  return a ^ b ^ c ^ MAX(MAX(a, b), c) ^ MIN(MIN(a, b), c);
}

inline vector3d median_vector3d(vector3d a, vector3d b, vector3d c) {
  vector3d v;

  v.x = median(a.x, b.x, c.x);
  v.y = median(a.y, b.y, c.y);
  v.z = median(a.z, b.z, c.z);

  return v;
}

[[combinable]]
void imu10(interface imu10_i server i, imu10_t &pin) {
  unsigned time;
  timer t;

  vector3d acc_buffer[3],
           mag_buffer[3],
           gyro_buffer[3];
  vector3d acc_median;
  unsigned acc_position = 0,
           mag_position = 0,
           gyro_position = 0;
  int reliable = 0;
  float lowpass = 0.02f;
  float pitch = 0.0;
  float accelerometer_pitch = 0.0;
  float gyroscope_pitch = 0.0;

  imu10_init(pin);
  t :> time;

  while (1) {
    select {
      case i.accelerometer_raw(vector3d &v):
        v = acc_buffer[acc_position];
        break;
      case i.accelerometer(vector3d &v):
        v = median_vector3d(acc_buffer[0], acc_buffer[1], acc_buffer[2]);
        break;
      case i.magnetometer_raw(vector3d &v):
        v = mag_buffer[mag_position];
        break;
      case i.magnetometer(vector3d &v):
        v = median_vector3d(mag_buffer[0], mag_buffer[1], mag_buffer[2]);
        break;
      case i.gyroscope_raw(vector3d &v):
        v = gyro_buffer[gyro_position];
        break;
      case i.gyroscope(vector3d &v):
        v = median_vector3d(gyro_buffer[0], gyro_buffer[1], gyro_buffer[2]);
        break;

      case i.set_lowpass(int l):
        lowpass = ((float)l)/1000.0f;
        reliable = 0;
        break;

      case i.get_lowpass() -> int l:
        l = (int)(lowpass * 1000.0f);
        break;

      case i.get_pitch() -> float p:
        p = pitch;
        break;

      case i.accelerometer_pitch() -> float p:
        p = accelerometer_pitch;
        break;

      case i.gyroscope_pitch() -> float p:
        p = gyroscope_pitch;
        break;

      case t when timerafter(time) :> void:
        time += 1 * XS1_TIMER_KHZ;

        lsm303d_read_accelerometer(pin, acc_buffer[acc_position]);
        /* lsm303d_read_magnetometer(pin, mag_buffer[mag_position]); */
        l3gd20h_read_gyroscope(pin, gyro_buffer[gyro_position]);


        accelerometer_pitch = atan2(acc_buffer[acc_position].z, sqrt(acc_buffer[acc_position].x * acc_buffer[acc_position].x +
                                                       acc_buffer[acc_position].y * acc_buffer[acc_position].y));

        gyroscope_pitch = atan2(gyro_buffer[gyro_position].z, sqrt(gyro_buffer[gyro_position].x * gyro_buffer[gyro_position].x +
                                                       gyro_buffer[gyro_position].y * gyro_buffer[gyro_position].y));

        pitch = reliable ? (1.0f-lowpass)*pitch + lowpass*accelerometer_pitch : pitch;

        if (!reliable)
          reliable = 1;

        acc_position++;
        acc_position %= 3;
        mag_position++;
        mag_position %= 3;
        gyro_position++;
        gyro_position %= 3;

        break;
    }
  }

}
