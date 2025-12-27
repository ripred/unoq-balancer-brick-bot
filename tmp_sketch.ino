#include <Arduino.h>
#include <Arduino_RouterBridge.h>
#include "PID_v1.h"
#include <Wire.h>
#include <math.h>

// --- Arduino Motor Shield Rev3 (L298P) pin map ---
// Channel A (left): DIR D12, PWM D3, BRAKE D9, CS A0
// Channel B (right): DIR D13, PWM D11, BRAKE D8, CS A1
const uint8_t PIN_MOTOR_L_PWM = 3;
const uint8_t PIN_MOTOR_L_DIR = 12;
const uint8_t PIN_MOTOR_L_BRAKE = 9;
const uint8_t PIN_MOTOR_R_PWM = 11;
const uint8_t PIN_MOTOR_R_DIR = 13;
const uint8_t PIN_MOTOR_R_BRAKE = 8;

// --- Encoder pins (quadrature A/B) ---
const uint8_t PIN_ENC_L_A = 2;
const uint8_t PIN_ENC_L_B = 4;
const uint8_t PIN_ENC_R_A = 5;
const uint8_t PIN_ENC_R_B = 6;

// --- IMU I2C setup ---
const uint8_t IMU_ADDR = 0x68;
const uint8_t REG_PWR_MGMT_1 = 0x6B;
const uint8_t REG_WHO_AM_I = 0x75;
const uint8_t REG_ACCEL_XOUT_H = 0x3B;
const float RAD_TO_DEG_F = 57.2957795f;

// --- Axis mapping ---
enum AxisMode {
  AXIS_PITCH = 0, // rotate about X, use accel Y/Z and gyro X
  AXIS_ROLL  = 1  // rotate about Y, use accel X/Z and gyro Y
};
static AxisMode axisMode = AXIS_PITCH;
static int axisSign = 1;
static int motorInvertL = 1;
static int motorInvertR = 1;
static int encoderInvertL = 1;
static int encoderInvertR = 1;
static unsigned long motorTestUntilMs = 0;
static int motorTestLeft = 0;
static int motorTestRight = 0;

// --- PID state ---
static double inputAngle = 0.0;
static double outputPwm = 0.0;
static double setpointAngle = 0.0;

static double Kp = 12.0;
static double Ki = 0.0;
static double Kd = 0.4;

PID pid(&inputAngle, &outputPwm, &setpointAngle, Kp, Ki, Kd, DIRECT);

// --- Runtime state ---
static volatile long encLeft = 0;
static volatile long encRight = 0;
static bool simulatedImu = true;
static bool imuReady = false;
static char imuModel[8] = "mpu6050";

static unsigned long lastTelemetryMs = 0;
static const unsigned long telemetryIntervalMs = 66; // ~15 Hz

static float angleEstimate = 0.0f;
static unsigned long lastImuMs = 0;

void onEncLeft() {
  int b = digitalRead(PIN_ENC_L_B);
  encLeft += (b == HIGH) ? 1 : -1;
}

void onEncRight() {
  int b = digitalRead(PIN_ENC_R_B);
  encRight += (b == HIGH) ? 1 : -1;
}

void setMotor(int pwm, uint8_t dirPin, uint8_t brakePin, uint8_t pwmPin) {
  int magnitude = abs(pwm);
  if (magnitude > 255) magnitude = 255;

  if (pwm >= 0) {
    digitalWrite(dirPin, HIGH);
  } else {
    digitalWrite(dirPin, LOW);
  }
  digitalWrite(brakePin, LOW);
  analogWrite(pwmPin, magnitude);
}

void applyMotors(int pwmLeft, int pwmRight) {
  setMotor(pwmLeft * motorInvertL, PIN_MOTOR_L_DIR, PIN_MOTOR_L_BRAKE, PIN_MOTOR_L_PWM);
  setMotor(pwmRight * motorInvertR, PIN_MOTOR_R_DIR, PIN_MOTOR_R_BRAKE, PIN_MOTOR_R_PWM);
}

uint8_t imuExpectedWho() {
  if (strcmp(imuModel, "mpu9250") == 0) {
    return 0x71;
  }
  return 0x68; // mpu6050
}

bool imuWriteReg(uint8_t reg, uint8_t value) {
  Wire.beginTransmission(IMU_ADDR);
  Wire.write(reg);
  Wire.write(value);
  return Wire.endTransmission() == 0;
}

bool imuReadBytes(uint8_t reg, uint8_t *buf, size_t len) {
  Wire.beginTransmission(IMU_ADDR);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) {
    return false;
  }
  size_t readCount = Wire.requestFrom(IMU_ADDR, static_cast<uint8_t>(len));
  if (readCount != len) {
    return false;
  }
  for (size_t i = 0; i < len; i++) {
    buf[i] = Wire.read();
  }
  return true;
}

bool imuInit() {
  uint8_t who = 0;
  if (!imuReadBytes(REG_WHO_AM_I, &who, 1)) {
    return false;
  }
  uint8_t expected = imuExpectedWho();
  if (who != expected) {
    return false;
  }
  if (!imuWriteReg(REG_PWR_MGMT_1, 0x00)) {
    return false;
  }
  delay(50);
  imuReady = true;
  return true;
}

// Placeholder IMU read. Replace with MPU-6050/9250 integration.
double readImuAngleSim() {
  static double phase = 0.0;
  phase += 0.03;
  return 10.0 * sin(phase);
}

bool readImuFiltered(float &angleDeg, float &gyroDps, float &accelG) {
  uint8_t raw[14];
  if (!imuReadBytes(REG_ACCEL_XOUT_H, raw, sizeof(raw))) {
    return false;
  }

  int16_t ax = (static_cast<int16_t>(raw[0]) << 8) | raw[1];
  int16_t ay = (static_cast<int16_t>(raw[2]) << 8) | raw[3];
  int16_t az = (static_cast<int16_t>(raw[4]) << 8) | raw[5];
  int16_t gx = (static_cast<int16_t>(raw[8]) << 8) | raw[9];
  int16_t gy = (static_cast<int16_t>(raw[10]) << 8) | raw[11];
  int16_t gz = (static_cast<int16_t>(raw[12]) << 8) | raw[13];

  float ax_g = ax / 16384.0f;
  float ay_g = ay / 16384.0f;
  float az_g = az / 16384.0f;
  float gx_dps = gx / 131.0f;
  float gy_dps = gy / 131.0f;
  float gz_dps = gz / 131.0f;

  float accelAngle = 0.0f;
  float gyroRate = 0.0f;

  if (axisMode == AXIS_PITCH) {
    accelAngle = atan2(ay_g, az_g) * RAD_TO_DEG_F;
    gyroRate = gx_dps;
  } else {
    accelAngle = atan2(ax_g, az_g) * RAD_TO_DEG_F;
    gyroRate = gy_dps;
  }

  unsigned long now = millis();
  float dt = (now - lastImuMs) / 1000.0f;
  if (lastImuMs == 0) {
    dt = 0.0f;
  }
  lastImuMs = now;

  angleEstimate = 0.98f * (angleEstimate + gyroRate * dt) + 0.02f * accelAngle;

  angleDeg = angleEstimate * axisSign;
  gyroDps = gyroRate * axisSign;
  accelG = sqrtf(ax_g * ax_g + ay_g * ay_g + az_g * az_g);
  (void)gz_dps;
  return true;
}

void set_pid(double p, double i, double d) {
  Kp = p;
  Ki = i;
  Kd = d;
  pid.SetTunings(Kp, Ki, Kd);
}

void set_setpoint(double sp) {
  setpointAngle = sp;
}

void set_mode(String mode) {
  if (mode == "real") {
    simulatedImu = false;
    imuReady = imuInit();
    if (!imuReady) {
      simulatedImu = true;
    }
  } else {
    simulatedImu = true;
  }
}

void set_imu_model(String model) {
  model.toCharArray(imuModel, sizeof(imuModel));
  if (!simulatedImu) {
    imuReady = imuInit();
    if (!imuReady) {
      simulatedImu = true;
    }
  }
}

void set_axis_mode(String mode) {
  if (mode == "roll") {
    axisMode = AXIS_ROLL;
  } else {
    axisMode = AXIS_PITCH;
  }
}

void set_axis_sign(int sign) {
  axisSign = (sign < 0) ? -1 : 1;
}

void set_motor_invert(int left, int right) {
  motorInvertL = (left < 0) ? -1 : 1;
  motorInvertR = (right < 0) ? -1 : 1;
}

void set_encoder_invert(int left, int right) {
  encoderInvertL = (left < 0) ? -1 : 1;
  encoderInvertR = (right < 0) ? -1 : 1;
}

void motor_test(int left_pwm, int right_pwm, int duration_ms) {
  motorTestLeft = left_pwm;
  motorTestRight = right_pwm;
  motorTestUntilMs = millis() + static_cast<unsigned long>(duration_ms);
}

void stop_motor_test() {
  motorTestLeft = 0;
  motorTestRight = 0;
  motorTestUntilMs = 0;
}

void kick(double angle) {
  if (simulatedImu) {
    inputAngle = angle;
  }
}

String axisName() {
  return axisMode == AXIS_ROLL ? String("roll") : String("pitch");
}

String get_status() {
  String mode = simulatedImu ? "sim" : "real";
  String ready = imuReady ? "ready" : "noimu";
  return String("ok:") + mode + ":" + ready + ":" + String(imuModel) + ":" + axisName() + ":" + String(axisSign);
}

void emitTelemetry(double angle, double gyro, double accel) {
  Bridge.notify("record_telemetry",
                angle,
                gyro,
                accel,
                static_cast<int>(outputPwm),
                static_cast<long>(encLeft) * encoderInvertL,
                static_cast<long>(encRight) * encoderInvertR,
                simulatedImu ? "sim" : "real",
                String(imuModel));
}

void setup() {
  Wire.begin();
  Bridge.begin();

  Bridge.provide("set_pid", set_pid);
  Bridge.provide("set_setpoint", set_setpoint);
  Bridge.provide("set_mode", set_mode);
  Bridge.provide("set_imu_model", set_imu_model);
  Bridge.provide("set_axis_mode", set_axis_mode);
  Bridge.provide("set_axis_sign", set_axis_sign);
  Bridge.provide("set_motor_invert", set_motor_invert);
  Bridge.provide("set_encoder_invert", set_encoder_invert);
  Bridge.provide("motor_test", motor_test);
  Bridge.provide("stop_motor_test", stop_motor_test);
  Bridge.provide("kick", kick);
  Bridge.provide("get_status", get_status);

  pinMode(PIN_MOTOR_L_PWM, OUTPUT);
  pinMode(PIN_MOTOR_L_DIR, OUTPUT);
  pinMode(PIN_MOTOR_L_BRAKE, OUTPUT);
  pinMode(PIN_MOTOR_R_PWM, OUTPUT);
  pinMode(PIN_MOTOR_R_DIR, OUTPUT);
  pinMode(PIN_MOTOR_R_BRAKE, OUTPUT);

  pinMode(PIN_ENC_L_A, INPUT_PULLUP);
  pinMode(PIN_ENC_L_B, INPUT_PULLUP);
  pinMode(PIN_ENC_R_A, INPUT_PULLUP);
  pinMode(PIN_ENC_R_B, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_L_A), onEncLeft, RISING);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_R_A), onEncRight, RISING);

  pid.SetMode(AUTOMATIC);
  pid.SetOutputLimits(-255, 255);
  pid.SetSampleTime(telemetryIntervalMs);
}

void loop() {
  float gyro = 0.0f;
  float accel = 0.0f;

  if (simulatedImu) {
    inputAngle = readImuAngleSim();
  } else if (imuReady) {
    float angleDeg = 0.0f;
    if (readImuFiltered(angleDeg, gyro, accel)) {
      inputAngle = angleDeg;
    } else {
      simulatedImu = true;
    }
  }

  pid.Compute();
  if (motorTestUntilMs > 0) {
    if (millis() > motorTestUntilMs) {
      stop_motor_test();
    } else {
      applyMotors(motorTestLeft, motorTestRight);
    }
  } else {
    applyMotors(static_cast<int>(outputPwm), static_cast<int>(outputPwm));
  }

  if (millis() - lastTelemetryMs >= telemetryIntervalMs) {
    lastTelemetryMs = millis();
    emitTelemetry(inputAngle, gyro, accel);
  }
}
