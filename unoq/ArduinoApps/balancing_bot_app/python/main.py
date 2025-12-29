import time
from pathlib import Path

from arduino.app_utils import App, Bridge
from arduino.app_bricks.web_ui import WebUI
import arduino.app_bricks as app_bricks

# Extend the system app_bricks package with our local brick path.
LOCAL_BRICKS = Path(__file__).parent / "arduino" / "app_bricks"
app_bricks.__path__.append(str(LOCAL_BRICKS))

from arduino.app_bricks.balancing_robot import BalancingRobot  # noqa: E402

ui = WebUI()

bot = BalancingRobot(imu_model="mpu6050", simulated=True, update_hz=50)
bot.attach_webui(ui)
bot.attach_bridge(Bridge)
bot.start()

# HTTP endpoints for polling mode (no socket.io)
ui.expose_api("GET", "/status", lambda: bot.get_state())
ui.expose_api("GET", "/set_pid", lambda p=None, i=None, d=None: bot.http_set_pid(p, i, d))
ui.expose_api("GET", "/set_pid_hz", lambda pid_hz=None: bot.http_set_pid_hz(pid_hz))
ui.expose_api("GET", "/set_setpoint", lambda setpoint=None: bot.http_set_setpoint(setpoint))
ui.expose_api("GET", "/set_imu_model", lambda imu_model=None: bot.http_set_imu_model(imu_model))
ui.expose_api("GET", "/set_axis_mode", lambda axis_mode=None: bot.http_set_axis_mode(axis_mode))
ui.expose_api("GET", "/set_axis_sign", lambda axis_sign=None: bot.http_set_axis_sign(axis_sign))
ui.expose_api("GET", "/set_motor_invert", lambda left=None, right=None: bot.http_set_motor_invert(left, right))
ui.expose_api("GET", "/set_encoder_invert", lambda left=None, right=None: bot.http_set_encoder_invert(left, right))
ui.expose_api("GET", "/motor_test", lambda left=None, right=None, duration_ms=None: bot.http_motor_test(left, right, duration_ms))
ui.expose_api("GET", "/stop_motor_test", lambda: bot.http_stop_motor_test())
ui.expose_api("GET", "/set_mode", lambda mode=None: bot.http_set_mode(mode))
ui.expose_api("GET", "/kick", lambda angle=None: bot.http_kick(angle))

App.run(user_loop=lambda: time.sleep(1))
