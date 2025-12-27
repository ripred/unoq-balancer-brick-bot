#!/usr/bin/env bash
set -euo pipefail

# Idempotent deploy of a local app folder to UNO Q over SSH.
# Usage:
#   ./03_deploy_app_to_uno_q.sh --local-app ./balancing_bot_app --remote arduino@ada.local

LOCAL_APP=""
REMOTE_HOST="arduino@ada.local"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local-app) LOCAL_APP="$2"; shift 2;;
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

if [[ -z "$LOCAL_APP" ]]; then
  echo "Missing required arg: --local-app" >&2
  exit 1
fi

if [[ ! -d "$LOCAL_APP" ]]; then
  echo "Local app not found: $LOCAL_APP" >&2
  exit 1
fi

APP_NAME="$(basename "$LOCAL_APP")"
REMOTE_APP_DIR="/home/arduino/ArduinoApps/$APP_NAME"

# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "REMOTE_APP_DIR=$(printf '%q' "$REMOTE_APP_DIR") bash -s" <<'REMOTE'
set -euo pipefail
mkdir -p "$REMOTE_APP_DIR"
REMOTE
rsync -az --delete "$LOCAL_APP/" "$REMOTE_HOST:$REMOTE_APP_DIR/"

echo "Deployed $LOCAL_APP -> $REMOTE_HOST:$REMOTE_APP_DIR"
