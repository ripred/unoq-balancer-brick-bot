# SPDX-FileCopyrightText: Copyright (C) ARDUINO SRL (http://www.arduino.cc)
#
# SPDX-License-Identifier: MPL-2.0
#
# This example starts in simulation, then switches to REAL mode for hardware.
# Use it only after IMU + motors + encoders are wired and validated.
#
# EXAMPLE_NAME = "Switch to real mode"
# EXAMPLE_REQUIRES = "IMU + motors + encoders wired and validated."
import time
from arduino.app_utils import App, Bridge
from arduino.app_bricks.web_ui import WebUI
from arduino.app_bricks.balancing_robot import BalancingRobot

ui = WebUI(port=7000)

bot = BalancingRobot(imu_model="mpu6050", simulated=True, update_hz=15)
bot.attach_webui(ui)
bot.attach_bridge(Bridge)
bot.start()

# After wiring IMU + motors + encoders, switch to real mode
bot.http_set_mode("real")

ui.start()
App.run(user_loop=lambda: time.sleep(1))
