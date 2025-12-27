#!/usr/bin/env bash
set -euo pipefail

# Idempotent scaffolding for a custom App Lab app on the UNO Q.
# Usage:
#   ./01_scaffold_app.sh \
#     --app-name balancing_bot_app \
#     --brick-id "arduino:balancing_robot" \
#     --remote arduino@ada.local

APP_NAME=""
BRICK_ID=""
REMOTE_HOST="arduino@ada.local"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name) APP_NAME="$2"; shift 2;;
    --brick-id) BRICK_ID="$2"; shift 2;;
    --remote) REMOTE_HOST="$2"; shift 2;;
    -h|--help)
      sed -n '1,60p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
 done

if [[ -z "$APP_NAME" || -z "$BRICK_ID" ]]; then
  echo "Missing required args. Use --app-name and --brick-id." >&2
  exit 1
fi

# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "APP_NAME=$(printf '%q' "$APP_NAME") BRICK_ID=$(printf '%q' "$BRICK_ID") bash -s" <<'REMOTE'
set -euo pipefail
REMOTE_APP_DIR="/home/arduino/ArduinoApps/$APP_NAME"

if [[ ! -d "$REMOTE_APP_DIR" ]]; then
  arduino-app-cli app new "$APP_NAME" --description "Balancing robot app"
fi

# app.yaml
cat > "$REMOTE_APP_DIR/app.yaml" <<'YAML'
name: __APP_NAME__
icon: 
description: "Balancing robot app"
ports: [7000]

bricks:
  - arduino:web_ui
  - __BRICK_ID__
YAML
sed -i "s|__APP_NAME__|$APP_NAME|" "$REMOTE_APP_DIR/app.yaml"
sed -i "s|__BRICK_ID__|$BRICK_ID|" "$REMOTE_APP_DIR/app.yaml"

# python/main.py
if [[ ! -f "$REMOTE_APP_DIR/python/main.py" ]]; then
  mkdir -p "$REMOTE_APP_DIR/python"
fi
cat > "$REMOTE_APP_DIR/python/main.py" <<'PY'
import time
from arduino.app_utils import App
from arduino.app_bricks.balancing_robot import BalancingRobot

bot = BalancingRobot(imu_model="mpu6050")

bot.start()

# basic loop placeholder
App.run(user_loop=lambda: time.sleep(1))
PY

# sketch/sketch.ino
if [[ ! -f "$REMOTE_APP_DIR/sketch/sketch.ino" ]]; then
  mkdir -p "$REMOTE_APP_DIR/sketch"
  cat > "$REMOTE_APP_DIR/sketch/sketch.ino" <<'INO'
#include <Arduino.h>

void setup() {
  // TODO: initialize IMU, encoders, motor driver
}

void loop() {
  // TODO: PID control loop placeholder
}
INO
fi

echo "App scaffold complete: $REMOTE_APP_DIR"
REMOTE
