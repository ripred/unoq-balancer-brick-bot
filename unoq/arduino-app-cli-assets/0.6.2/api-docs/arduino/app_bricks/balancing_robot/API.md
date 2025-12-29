# balancing_robot API Reference

## Index

- Class `BalancingRobot`

---

## `BalancingRobot` class

```python
class BalancingRobot(imu_model: str = "mpu6050", simulated: bool = True, update_hz: int = 15)
```

Balancing robot controller with simulation support, telemetry streaming, and WebUI integration.

### Parameters

- **imu_model** (*str*): IMU model name (e.g., "mpu6050", "mpu9250").
- **simulated** (*bool*): Start in simulation mode if true.
- **update_hz** (*int*): Loop rate for simulation/telemetry updates.

### Methods

#### `attach_webui(ui)`

Attach a WebUI instance and register dashboard socket handlers.

#### `attach_bridge(bridge)`

Attach Arduino Router Bridge for MCU communication.

#### `start()`

Start the control/telemetry loop.

#### `stop()`

Stop the control/telemetry loop.

#### `get_state()`

Get current configuration and latest telemetry.

#### `http_set_pid(p=None, i=None, d=None)`

Set PID gains via HTTP-style parameters.

#### `http_set_setpoint(setpoint=None)`

Set the target angle in degrees.

#### `http_set_imu_model(imu_model=None)`

Change IMU model identifier.

#### `http_set_axis_mode(axis_mode=None)`

Select axis mode ("pitch" or "roll").

#### `http_set_axis_sign(axis_sign=None)`

Invert axis sign (+1 or -1).

#### `http_set_motor_invert(left=None, right=None)`

Invert motor direction for left/right.

#### `http_set_encoder_invert(left=None, right=None)`

Invert encoder direction for left/right.

#### `http_motor_test(left=None, right=None, duration_ms=None)`

Run a short motor test (simulation or real hardware).

#### `http_stop_motor_test()`

Stop an active motor test.

#### `http_set_mode(mode=None)`

Set mode to "sim" or "real".

#### `http_kick(angle=None)`

Apply a simulated kick (ignored in real mode).

EOF"
