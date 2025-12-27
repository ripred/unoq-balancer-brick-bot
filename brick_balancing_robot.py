"""Balancing robot brick API + simulation."""

import random
import threading
import time
from typing import Any, Dict, Optional, Callable


class BalancingRobot:
    def __init__(self, imu_model: str = "mpu6050", simulated: bool = True, update_hz: int = 15):
        self.imu_model = imu_model
        self.simulated = simulated
        self.update_hz = update_hz
        self.axis_mode = "pitch"
        self.axis_sign = 1
        self.motor_invert = {"left": 1, "right": 1}
        self.encoder_invert = {"left": 1, "right": 1}

        self.pid = {"p": 12.0, "i": 0.0, "d": 0.4}
        self.setpoint = 0.0
        self._integral = 0.0
        self._last_error = 0.0

        self._telemetry: Dict[str, Any] = {
            "ts": 0.0,
            "angle_deg": 0.0,
            "gyro_dps": 0.0,
            "accel_g": 0.0,
            "pid": self.pid.copy(),
            "setpoint": self.setpoint,
            "motor_pwm": {"left": 0, "right": 0},
            "encoders": {"left": 0, "right": 0},
            "mode": "sim" if self.simulated else "real",
            "imu_model": self.imu_model,
        }

        self._ui = None
        self._thread: Optional[threading.Thread] = None
        self._stop = threading.Event()

        # Optional hooks for real hardware integration.
        self._sensor_provider: Optional[Callable[[], Dict[str, Any]]] = None
        self._motor_sink: Optional[Callable[[int, int], None]] = None

        # Bridge integration
        self._bridge = None
        self._bridge_ready = False
        self._hw_lock = threading.Lock()
        self._latest_hw: Dict[str, Any] = {}

    def attach_webui(self, ui) -> None:
        self._ui = ui
        ui.on_connect(lambda sid: self._send_config(sid))
        ui.on_message("get_initial_state", self._on_get_initial_state)
        ui.on_message("set_pid", self._on_set_pid)
        ui.on_message("set_setpoint", self._on_set_setpoint)
        ui.on_message("set_imu_model", self._on_set_imu_model)
        ui.on_message("set_axis_mode", self._on_set_axis_mode)
        ui.on_message("set_axis_sign", self._on_set_axis_sign)
        ui.on_message("set_motor_invert", self._on_set_motor_invert)
        ui.on_message("set_encoder_invert", self._on_set_encoder_invert)
        ui.on_message("motor_test", self._on_motor_test)
        ui.on_message("stop_motor_test", self._on_stop_motor_test)
        ui.on_message("set_mode", self._on_set_mode)
        ui.on_message("kick", self._on_kick)

    def attach_bridge(self, bridge) -> None:
        self._bridge = bridge
        try:
            bridge.provide("record_telemetry", self.record_telemetry)
        except RuntimeError:
            pass
        self._ensure_bridge_ready()

    def set_sensor_provider(self, fn: Callable[[], Dict[str, Any]]) -> None:
        """Provide a callable that returns sensor telemetry for real mode."""
        self._sensor_provider = fn

    def set_motor_sink(self, fn: Callable[[int, int], None]) -> None:
        """Provide a callable that receives motor PWM outputs."""
        self._motor_sink = fn

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._stop.clear()
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=2.0)

    def get_state(self) -> Dict[str, Any]:
        return {
            "config": {
                "imu_model": self.imu_model,
                "pid": self.pid.copy(),
                "setpoint": self.setpoint,
                "mode": "real" if not self.simulated else "sim",
                "axis_mode": self.axis_mode,
                "axis_sign": self.axis_sign,
                "motor_invert": self.motor_invert.copy(),
                "encoder_invert": self.encoder_invert.copy(),
            },
            "telemetry": self._telemetry,
        }

    def record_telemetry(
        self,
        angle_deg: float,
        gyro_dps: float,
        accel_g: float,
        pwm: int,
        enc_left: int,
        enc_right: int,
        mode: str,
        imu_model: str,
    ) -> None:
        with self._hw_lock:
            self._latest_hw = {
                "angle_deg": float(angle_deg),
                "gyro_dps": float(gyro_dps),
                "accel_g": float(accel_g),
                "motor_pwm": {"left": int(pwm), "right": int(pwm)},
                "encoders": {"left": int(enc_left), "right": int(enc_right)},
                "mode": str(mode),
                "imu_model": str(imu_model),
            }
        self._bridge_ready = True

    # HTTP setters for polling mode
    def http_set_pid(self, p=None, i=None, d=None) -> Dict[str, Any]:
        data = {"p": p, "i": i, "d": d}
        self._on_set_pid(None, data)
        return self.get_state()["config"]

    def http_set_setpoint(self, setpoint=None) -> Dict[str, Any]:
        self._on_set_setpoint(None, {"setpoint": setpoint})
        return self.get_state()["config"]

    def http_set_imu_model(self, imu_model=None) -> Dict[str, Any]:
        self._on_set_imu_model(None, {"imu_model": imu_model})
        return self.get_state()["config"]

    def http_set_axis_mode(self, axis_mode=None) -> Dict[str, Any]:
        self._on_set_axis_mode(None, {"axis_mode": axis_mode})
        return self.get_state()["config"]

    def http_set_axis_sign(self, axis_sign=None) -> Dict[str, Any]:
        self._on_set_axis_sign(None, {"axis_sign": axis_sign})
        return self.get_state()["config"]

    def http_set_motor_invert(self, left=None, right=None) -> Dict[str, Any]:
        self._on_set_motor_invert(None, {"left": left, "right": right})
        return self.get_state()["config"]

    def http_set_encoder_invert(self, left=None, right=None) -> Dict[str, Any]:
        self._on_set_encoder_invert(None, {"left": left, "right": right})
        return self.get_state()["config"]

    def http_motor_test(self, left=None, right=None, duration_ms=None) -> Dict[str, Any]:
        self._on_motor_test(None, {"left": left, "right": right, "duration_ms": duration_ms})
        return self.get_state()["config"]

    def http_stop_motor_test(self) -> Dict[str, Any]:
        self._on_stop_motor_test(None, {})
        return self.get_state()["config"]

    def http_set_mode(self, mode=None) -> Dict[str, Any]:
        self._on_set_mode(None, {"mode": mode})
        return self.get_state()["config"]

    def http_kick(self, angle=None) -> Dict[str, Any]:
        self._on_kick(None, {"angle": angle})
        return self.get_state()["config"]

    def _ensure_bridge_ready(self) -> bool:
        if not self._bridge:
            return False
        if self._bridge_ready:
            return True
        try:
            self._bridge.call("get_status", timeout=2)
            self._bridge_ready = True
        except Exception:
            self._bridge_ready = False
        return self._bridge_ready

    def _bridge_notify(self, method: str, *params) -> None:
        if not self._bridge:
            return
        if not self._ensure_bridge_ready():
            return
        try:
            self._bridge.notify(method, *params)
        except Exception:
            pass

    def _send_config(self, client=None) -> None:
        if not self._ui:
            return
        self._ui.send_message("config", self.get_state()["config"], client)

    def _on_get_initial_state(self, client, _data) -> None:
        self._send_config(client)

    def _on_set_pid(self, _client, data) -> None:
        try:
            if data.get("p") is not None:
                self.pid["p"] = float(data.get("p"))
            if data.get("i") is not None:
                self.pid["i"] = float(data.get("i"))
            if data.get("d") is not None:
                self.pid["d"] = float(data.get("d"))
        except (ValueError, TypeError):
            return
        if not self.simulated:
            self._bridge_notify("set_pid", self.pid["p"], self.pid["i"], self.pid["d"])
        self._send_config()

    def _on_set_setpoint(self, _client, data) -> None:
        try:
            if data.get("setpoint") is not None:
                self.setpoint = float(data.get("setpoint"))
        except (ValueError, TypeError):
            return
        if not self.simulated:
            self._bridge_notify("set_setpoint", self.setpoint)
        self._send_config()

    def _on_set_imu_model(self, _client, data) -> None:
        model = data.get("imu_model")
        if model:
            self.imu_model = str(model)
            if not self.simulated:
                self._bridge_notify("set_imu_model", self.imu_model)
            self._send_config()

    def _on_set_axis_mode(self, _client, data) -> None:
        axis = data.get("axis_mode")
        if axis:
            self.axis_mode = str(axis)
            if not self.simulated:
                self._bridge_notify("set_axis_mode", self.axis_mode)
            self._bridge_notify("set_axis_sign", self.axis_sign)
            self._send_config()

    def _on_set_axis_sign(self, _client, data) -> None:
        sign = data.get("axis_sign")
        if sign is None:
            return
        try:
            self.axis_sign = -1 if int(sign) < 0 else 1
        except (ValueError, TypeError):
            self.axis_sign = 1
        if not self.simulated:
            self._bridge_notify("set_axis_sign", self.axis_sign)
        self._send_config()

    def _on_set_motor_invert(self, _client, data) -> None:
        left = data.get("left")
        right = data.get("right")
        if left is not None:
            try:
                self.motor_invert["left"] = -1 if int(left) < 0 else 1
            except (ValueError, TypeError):
                self.motor_invert["left"] = 1
        if right is not None:
            try:
                self.motor_invert["right"] = -1 if int(right) < 0 else 1
            except (ValueError, TypeError):
                self.motor_invert["right"] = 1
        if not self.simulated:
            self._bridge_notify("set_motor_invert", self.motor_invert["left"], self.motor_invert["right"])
        self._send_config()

    def _on_set_encoder_invert(self, _client, data) -> None:
        left = data.get("left")
        right = data.get("right")
        if left is not None:
            try:
                self.encoder_invert["left"] = -1 if int(left) < 0 else 1
            except (ValueError, TypeError):
                self.encoder_invert["left"] = 1
        if right is not None:
            try:
                self.encoder_invert["right"] = -1 if int(right) < 0 else 1
            except (ValueError, TypeError):
                self.encoder_invert["right"] = 1
        if not self.simulated:
            self._bridge_notify("set_encoder_invert", self.encoder_invert["left"], self.encoder_invert["right"])
        self._send_config()

    def _on_motor_test(self, _client, data) -> None:
        if self.simulated:
            return
        try:
            left = int(data.get("left", 0))
            right = int(data.get("right", 0))
            duration_ms = int(data.get("duration_ms", 1000))
        except (ValueError, TypeError):
            return
        left = max(-255, min(255, left))
        right = max(-255, min(255, right))
        duration_ms = max(100, min(5000, duration_ms))
        self._bridge_notify("motor_test", left, right, duration_ms)

    def _on_stop_motor_test(self, _client, _data) -> None:
        if self.simulated:
            return
        self._bridge_notify("stop_motor_test")

    def _on_set_mode(self, _client, data) -> None:
        mode = str(data.get("mode", "sim"))
        self.simulated = (mode != "real")
        self._bridge_notify("set_mode", "real" if not self.simulated else "sim")
        if not self.simulated:
            self._bridge_notify("set_pid", self.pid["p"], self.pid["i"], self.pid["d"])
            self._bridge_notify("set_setpoint", self.setpoint)
            self._bridge_notify("set_imu_model", self.imu_model)
            self._bridge_notify("set_axis_mode", self.axis_mode)
            self._bridge_notify("set_axis_sign", self.axis_sign)
            self._bridge_notify("set_motor_invert", self.motor_invert["left"], self.motor_invert["right"])
            self._bridge_notify("set_encoder_invert", self.encoder_invert["left"], self.encoder_invert["right"])
        self._send_config()

    def _on_kick(self, _client, data) -> None:
        try:
            angle = float(data.get("angle", 30))
        except (ValueError, TypeError):
            angle = 30.0
        if self.simulated:
            # Hard shove: set telemetry to a large angle with some rate
            self._telemetry["angle_deg"] = angle
            self._telemetry["gyro_dps"] = 5.0 if angle >= 0 else -5.0
        else:
            # Kick is simulation-only to avoid face-planting hardware.
            return

    def _run_loop(self) -> None:
        dt = 1.0 / max(1, int(self.update_hz))
        angle = 12.0
        rate = 0.0
        accel = 0.0
        enc_l = 0
        enc_r = 0
        pid_out = 0.0

        while not self._stop.is_set():
            if self.simulated:
                # Larger, slower oscillation with noise for visible UI motion.
                rate += (-0.25 * angle - 0.03 * rate + random.uniform(-0.5, 0.5))
                angle += rate * dt
                accel = max(-2.0, min(2.0, angle / 10.0))
            else:
                # Prefer bridge telemetry if available.
                with self._hw_lock:
                    data = dict(self._latest_hw)

                if data:
                    angle = float(data.get("angle_deg", angle))
                    rate = float(data.get("gyro_dps", rate))
                    accel = float(data.get("accel_g", accel))
                    enc = data.get("encoders", {})
                    if isinstance(enc, dict):
                        enc_l = int(enc.get("left", enc_l))
                        enc_r = int(enc.get("right", enc_r))
                    pid_out = float(data.get("motor_pwm", {}).get("left", pid_out))
                elif self._sensor_provider:
                    try:
                        data = self._sensor_provider() or {}
                    except Exception:
                        data = {}

                    try:
                        angle = float(data.get("angle_deg", angle))
                    except (ValueError, TypeError):
                        pass
                    try:
                        rate = float(data.get("gyro_dps", rate))
                    except (ValueError, TypeError):
                        pass
                    try:
                        accel = float(data.get("accel_g", accel))
                    except (ValueError, TypeError):
                        pass

                    enc = data.get("encoders", {})
                    if isinstance(enc, dict):
                        enc_l = int(enc.get("left", enc_l))
                        enc_r = int(enc.get("right", enc_r))
                    else:
                        try:
                            enc_l = int(data.get("enc_left", enc_l))
                            enc_r = int(data.get("enc_right", enc_r))
                        except (ValueError, TypeError, AttributeError):
                            pass
                else:
                    rate *= 0.95

            if self.simulated:
                error = self.setpoint - angle
                self._integral += error * dt
                deriv = (error - self._last_error) / dt
                self._last_error = error

                pid_out = (
                    self.pid["p"] * error
                    + self.pid["i"] * self._integral
                    + self.pid["d"] * deriv
                )
                pid_out = max(-255.0, min(255.0, pid_out))

                # Simulated encoders proportional to output.
                enc_l += int(pid_out * 0.12)
                enc_r += int(pid_out * 0.12)

            if self._motor_sink:
                try:
                    self._motor_sink(int(pid_out), int(pid_out))
                except Exception:
                    pass

            self._telemetry = {
                "ts": time.time(),
                "angle_deg": angle,
                "gyro_dps": rate,
                "accel_g": accel,
                "pid": self.pid.copy(),
                "setpoint": self.setpoint,
                "motor_pwm": {"left": int(pid_out), "right": int(pid_out)},
                "encoders": {"left": enc_l, "right": enc_r},
                "mode": "real" if not self.simulated else "sim",
                "imu_model": self.imu_model,
            }

            if self._ui:
                self._ui.send_message("telemetry", self._telemetry)

            time.sleep(dt)
