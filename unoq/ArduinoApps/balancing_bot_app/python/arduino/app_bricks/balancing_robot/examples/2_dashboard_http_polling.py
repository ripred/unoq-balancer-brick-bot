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
