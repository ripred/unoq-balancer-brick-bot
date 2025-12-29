#!/usr/bin/env bash
set -euo pipefail

# Idempotent scaffolding for a custom App Lab app on the UNO Q.
# Usage:
#   ./01_scaffold_app.sh \
#     --app-name balancing_bot_app \
#     --brick-id "arduino:balancing_robot" \
#     --brick-python-name balancing_robot \
#     --brick-class BalancingRobot \
#     --app-description "My custom app" \
#     --app-icon "🤖" \
#     --port 7000 \
#     --remote arduino@ada.local

APP_NAME=""
BRICK_ID=""
BRICK_PY_NAME=""
BRICK_CLASS=""
APP_DESC=""
APP_ICON=""
APP_PORT="7000"
REMOTE_HOST="${REMOTE_HOST:-${UNOQ_HOST:-arduino@ada.local}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name) APP_NAME="$2"; shift 2;;
    --brick-id) BRICK_ID="$2"; shift 2;;
    --brick-python-name) BRICK_PY_NAME="$2"; shift 2;;
    --brick-class) BRICK_CLASS="$2"; shift 2;;
    --app-description) APP_DESC="$2"; shift 2;;
    --app-icon) APP_ICON="$2"; shift 2;;
    --port) APP_PORT="$2"; shift 2;;
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

if [[ -z "$BRICK_PY_NAME" ]]; then
  if [[ "$BRICK_ID" == *:* ]]; then
    BRICK_PY_NAME="${BRICK_ID##*:}"
  else
    BRICK_PY_NAME="$BRICK_ID"
  fi
fi
if [[ -z "$BRICK_CLASS" ]]; then
  BRICK_CLASS="CustomBrick"
fi
if [[ -z "$APP_DESC" ]]; then
  APP_DESC="Custom App Lab app"
fi

# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "APP_NAME=$(printf '%q' "$APP_NAME") BRICK_ID=$(printf '%q' "$BRICK_ID") BRICK_PY_NAME=$(printf '%q' "$BRICK_PY_NAME") BRICK_CLASS=$(printf '%q' "$BRICK_CLASS") APP_DESC=$(printf '%q' "$APP_DESC") APP_ICON=$(printf '%q' "$APP_ICON") APP_PORT=$(printf '%q' "$APP_PORT") bash -s" <<'REMOTE'
set -euo pipefail
REMOTE_APP_DIR="/home/arduino/ArduinoApps/$APP_NAME"

if [[ ! -d "$REMOTE_APP_DIR" ]]; then
  arduino-app-cli app new "$APP_NAME" --description "$APP_DESC"
fi

# Escape quotes for YAML string.
APP_DESC_ESC=${APP_DESC//\"/\\\"}

# app.yaml
cat > "$REMOTE_APP_DIR/app.yaml" <<YAML
name: $APP_NAME
icon: $APP_ICON
description: "$APP_DESC_ESC"
ports: [$APP_PORT]

bricks:
  - arduino:web_ui
  - $BRICK_ID
YAML
if [[ -z "$APP_ICON" ]]; then
  sed -i '/^icon: *$/d' "$REMOTE_APP_DIR/app.yaml"
fi

# python/main.py
if [[ ! -f "$REMOTE_APP_DIR/python/main.py" ]]; then
  mkdir -p "$REMOTE_APP_DIR/python"
fi
cat > "$REMOTE_APP_DIR/python/main.py" <<PY
import time
from arduino.app_utils import App
from arduino.app_bricks.$BRICK_PY_NAME import $BRICK_CLASS

bot = $BRICK_CLASS()

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
