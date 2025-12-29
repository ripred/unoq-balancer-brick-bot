# SPDX-FileCopyrightText: Copyright (C) ARDUINO SRL (http://www.arduino.cc)
#
# SPDX-License-Identifier: MPL-2.0
#
# This example runs the full dashboard in SIMULATION mode only.
# Use it first to explore PID tuning and telemetry safely without hardware.
#
# EXAMPLE_NAME = "Simulation dashboard (safe tuning)"
# EXAMPLE_REQUIRES = "No hardware required. Great for first-time PID tuning."
import time
from arduino.app_utils import App, Bridge
from arduino.app_bricks.web_ui import WebUI
from arduino.app_bricks.balancing_robot import BalancingRobot

# Web dashboard at http://<uno-q-ip>:7000
ui = WebUI(port=7000)

# Start in simulation mode
bot = BalancingRobot(imu_model="mpu6050", simulated=True, update_hz=15)
bot.attach_webui(ui)
bot.attach_bridge(Bridge)
bot.start()

ui.start()
App.run(user_loop=lambda: time.sleep(1))
