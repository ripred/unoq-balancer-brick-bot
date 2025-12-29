#!/usr/bin/env bash
set -euo pipefail

# Idempotent scaffolding for a custom App Lab brick on the UNO Q.
# Usage:
#   ./00_scaffold_brick.sh \
#     --brick-name balancing_robot \
#     --brick-id "arduino:balancing_robot" \
#     --brick-title "Balancing Robot" \
#     --brick-class BalancingRobot \
#     --app-name balancing_robot \
#     --remote arduino@ada.local

BRICK_NAME=""
BRICK_ID=""
BRICK_TITLE=""
BRICK_CLASS=""
APP_NAME=""
REMOTE_HOST="${REMOTE_HOST:-${UNOQ_HOST:-arduino@ada.local}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brick-name) BRICK_NAME="$2"; shift 2;;
    --brick-id) BRICK_ID="$2"; shift 2;;
    --brick-title) BRICK_TITLE="$2"; shift 2;;
    --brick-class) BRICK_CLASS="$2"; shift 2;;
    --app-name) APP_NAME="$2"; shift 2;;
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

if [[ -z "$BRICK_NAME" || -z "$BRICK_ID" ]]; then
  echo "Missing required args. Use --brick-name and --brick-id." >&2
  exit 1
fi

if [[ -z "$BRICK_TITLE" ]]; then
  BRICK_TITLE="${BRICK_NAME//_/ }"
  BRICK_TITLE="$(printf '%s' "$BRICK_TITLE" | tr '-' ' ')"
fi
if [[ -z "$BRICK_CLASS" ]]; then
  BRICK_CLASS="CustomBrick"
fi
if [[ -z "$APP_NAME" ]]; then
  APP_NAME="$BRICK_NAME"
fi

REMOTE_APP_DIR="/home/arduino/ArduinoApps"
BRICK_DIR="$REMOTE_APP_DIR/$APP_NAME/python/arduino/app_bricks/$BRICK_NAME"

# Create an app container for brick dev if it doesn't exist yet.
# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "BRICK_NAME=$(printf '%q' "$BRICK_NAME") BRICK_ID=$(printf '%q' "$BRICK_ID") BRICK_TITLE=$(printf '%q' "$BRICK_TITLE") BRICK_CLASS=$(printf '%q' "$BRICK_CLASS") APP_NAME=$(printf '%q' "$APP_NAME") REMOTE_APP_DIR=$(printf '%q' "$REMOTE_APP_DIR") BRICK_DIR=$(printf '%q' "$BRICK_DIR") bash -s" <<'REMOTE'
set -euo pipefail

if [[ ! -d "$REMOTE_APP_DIR/$APP_NAME" ]]; then
  arduino-app-cli app new "$APP_NAME" --description "Custom brick: $BRICK_NAME"
fi

mkdir -p "$BRICK_DIR"
mkdir -p "$BRICK_DIR/examples"
mkdir -p "$BRICK_DIR/assets"

# __init__.py
if [[ ! -f "$BRICK_DIR/__init__.py" ]]; then
  cat > "$BRICK_DIR/__init__.py" <<PY
"""$BRICK_TITLE brick API (placeholder)."""

class $BRICK_CLASS:
    def __init__(self):
        pass

    def start(self):
        pass

    def stop(self):
        pass
PY
fi

# brick_config.yaml
if [[ ! -f "$BRICK_DIR/brick_config.yaml" ]]; then
  cat > "$BRICK_DIR/brick_config.yaml" <<YAML
id: __BRICK_ID__
name: __BRICK_TITLE__
category: custom
description: >
  Custom brick placeholder. Replace with your own description.
YAML
  sed -i "s|__BRICK_ID__|$BRICK_ID|" "$BRICK_DIR/brick_config.yaml"
  sed -i "s|__BRICK_TITLE__|$BRICK_TITLE|" "$BRICK_DIR/brick_config.yaml"
fi

# README.md
if [[ ! -f "$BRICK_DIR/README.md" ]]; then
  cat > "$BRICK_DIR/README.md" <<MD
# $BRICK_TITLE Brick

This brick provides a Python API and a simple placeholder implementation.

## Quick start
- Import `$BRICK_CLASS` from `arduino.app_bricks.$BRICK_NAME`
- Call `start()` to begin telemetry + control

MD
fi

# Example
if [[ ! -f "$BRICK_DIR/examples/1_basic_usage.py" ]]; then
  cat > "$BRICK_DIR/examples/1_basic_usage.py" <<PY
from arduino.app_utils import App
from arduino.app_bricks.$BRICK_NAME import $BRICK_CLASS

bot = $BRICK_CLASS()

bot.start()
App.run()
PY
fi

# Do not create arduino/__init__.py here to avoid shadowing the system package.

echo "Brick scaffold complete: $BRICK_DIR"
REMOTE
