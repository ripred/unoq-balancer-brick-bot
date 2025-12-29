# Balancing Robot Brick

This Brick provides a complete balancing robot stack: IMU fusion, PID control, motor drive, and a live tuning dashboard. It supports simulation-first onboarding and a smooth switch to real hardware.

## Overview

The Balancing Robot Brick allows you to:

- Run a full balancing loop in simulation or with real hardware
- Tune PID gains and setpoint live from a web dashboard
- Stream telemetry (angle, gyro, accel, motors, encoders)
- Use Arduino_RouterBridge to connect the MCU to the App
- Gradually enable IMU, motors, and encoders

If you are new to balancing robots, start in **Simulation**. You can progressively enable each subsystem (IMU → motors → encoders) and switch to **Real** only when each step is stable.

## Features

- Simulation mode for safe testing
- Real-time dashboard (WebUI) with PID controls
- IMU support for MPU6050 / MPU9250
- Motor test and safety stop
- Axis selection and inversion for quick alignment
- Encoder direction control
- Bridge-based telemetry from MCU

## Hardware notes (recommended defaults)

- **Motor shield**: Arduino Motor Shield Rev3 (L298P)
- **IMU**: MPU6050 / MPU9250 on Wire (I2C)
- **Encoders**: Quadrature A/B on free digital pins

## Progressive setup (recommended)

1. **Simulation only**: verify the dashboard and PID sliders.
2. **IMU only**: wire the IMU and confirm angles update.
3. **Motors only**: run motor tests with wheels off the ground.
4. **Encoders**: verify direction and counts.
5. **Real mode**: enable full balancing.

## Safety notes

- Motor tests are time-limited and can be stopped from the dashboard.
- “Kick” is simulation-only and ignored in real mode.

## Code example and usage

### 1) Minimal app + dashboard (simulation)

```python
import time
from arduino.app_utils import App, Bridge
from arduino.app_bricks.web_ui import WebUI
from arduino.app_bricks.balancing_robot import BalancingRobot

ui = WebUI(port=7000)

bot = BalancingRobot(imu_model="mpu6050", simulated=True, update_hz=15)
bot.attach_webui(ui)
bot.attach_bridge(Bridge)
bot.start()

ui.start()
App.run(user_loop=lambda: time.sleep(1))
```

Open the dashboard at `http://<uno-q-ip>:7000`.

### 2) HTTP polling mode (no socket.io)

```python
import time
from arduino.app_utils import App, Bridge
from arduino.app_bricks.web_ui import WebUI
from arduino.app_bricks.balancing_robot import BalancingRobot

ui = WebUI(port=7000)

bot = BalancingRobot(imu_model="mpu6050", simulated=True, update_hz=15)
bot.attach_webui(ui)
bot.attach_bridge(Bridge)
bot.start()

# Expose polling endpoints (useful if socket.io is not available)
ui.expose_api("GET", "/status", lambda: bot.get_state())
ui.expose_api("GET", "/set_pid", lambda p=None, i=None, d=None: bot.http_set_pid(p, i, d))
ui.expose_api("GET", "/set_setpoint", lambda setpoint=None: bot.http_set_setpoint(setpoint))

ui.start()
App.run(user_loop=lambda: time.sleep(1))
```

### 3) Switch to real mode (after wiring)

```python
# Switch from sim to real once IMU + motors are verified
bot.http_set_mode("real")
```

### 4) MCU sketch (Bridge telemetry)

Minimal loop showing how telemetry is sent to the App:

```cpp
#include <Arduino_RouterBridge.h>

void setup() {
  Bridge.begin();
  // init IMU, motors, encoders here
}

void loop() {
  float angle_deg = 0.0;
  float gyro_dps = 0.0;
  float accel_g = 0.0;
  int pwm = 0;
  long enc_left = 0;
  long enc_right = 0;

  Bridge.notify("record_telemetry", angle_deg, gyro_dps, accel_g, pwm, enc_left, enc_right, "real", "mpu6050");
}
```

### 5) Dashboard tips (tuning flow)

- Start with **P only**, increase until the robot oscillates.
- Add **D** to dampen oscillation.
- Add **I** only if you need to correct steady-state drift.
- Use **Motor Test** to confirm wiring and direction.
- Flip **Axis** and **Axis Sign** if tilt goes the wrong way.

