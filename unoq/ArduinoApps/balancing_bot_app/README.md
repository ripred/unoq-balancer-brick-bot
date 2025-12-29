# Balancing Bot App

A full self-balancing robot application for Arduino Uno Q. Includes a live web dashboard for PID tuning, IMU alignment, motor tests, and simulation mode so you can iterate safely before connecting hardware.

## What this app does

- Runs a balancing control loop in **simulation** or **real** mode
- Streams telemetry (angle, gyro, accel, motors, encoders)
- Hosts a live dashboard for PID + setpoint tuning
- Uses the Arduino Router Bridge to communicate with the MCU sketch

## System overview

The app is split into a web dashboard, a Python control layer, and an MCU sketch bridged by the Router Bridge.

![System architecture](http://ada.local:7000/diagrams/system_arch.svg)

Direct link: http://ada.local:7000/diagrams/system_arch.svg

## Data flow (commands + telemetry)

Commands (PID, mode, motor tests) flow down to the MCU. Telemetry flows back up for rendering.

![Data flow](http://ada.local:7000/diagrams/data_flow.svg)

Direct link: http://ada.local:7000/diagrams/data_flow.svg

## Quick start

```bash
# On the Uno Q
cd /home/arduino/ArduinoApps/balancing_bot_app
arduino-app-cli app start user:balancing_bot_app
```

Open the dashboard:
```
http://ada.local:7000
```

Stop the app:
```bash
arduino-app-cli app stop user:balancing_bot_app
```

## Modes

- **Simulation (default):** safe for testing PID and UI
- **Real:** requires IMU + motors + encoders wired and validated

Switch modes from the dashboard or via HTTP:
```
http://ada.local:7000/set_mode?mode=real
```

## Hardware (recommended defaults)

- Motor shield: Arduino Motor Shield Rev3 (L298P)
- IMU: MPU6050 / MPU9250 on Wire (I2C)
- Encoders: Quadrature A/B on free digital pins

### Pin map (Rev3 shield + encoders + IMU)

This matches the current `sketch/sketch.ino` defaults.

![Pin map](http://ada.local:7000/diagrams/pin_map.svg)

Direct link: http://ada.local:7000/diagrams/pin_map.svg

## Dashboard guide

The dashboard is designed for safe iteration before wiring hardware:

- **PID / Setpoint:** tune live while watching the waveform and wireframe
- **PID Rate:** change control loop speed (default 50 Hz)
- **IMU / Axis:** select IMU model and axis mapping
- **Motor / Encoder invert:** quick polarity fixes without reflashing
- **Mode:** switch between simulation and real sensor data
- **Kick:** simulation-only disturbance for tuning stability

## Safety

- Motor test is time-limited and has a Stop button
- "Kick" is simulation-only and ignored in real mode

## Files

- `python/main.py` - app entrypoint
- `python/arduino/app_bricks/balancing_robot/__init__.py` - brick logic
- `assets/` - dashboard UI
- `sketch/sketch.ino` - MCU firmware
