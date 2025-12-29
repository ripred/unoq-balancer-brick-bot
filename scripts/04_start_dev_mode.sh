#!/usr/bin/env bash
set -euo pipefail

# Start an App Lab app in dev mode (no-hardware / simulated).
# Usage:
#   ./04_start_dev_mode.sh --app-id user:balancing_bot_app --remote arduino@ada.local

APP_ID=""
REMOTE_HOST="${REMOTE_HOST:-${UNOQ_HOST:-arduino@ada.local}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-id) APP_ID="$2"; shift 2;;
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

if [[ -z "$APP_ID" ]]; then
  echo "Missing required arg: --app-id" >&2
  exit 1
fi

# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "APP_ID=$(printf '%q' "$APP_ID") bash -s" <<'REMOTE'
set -euo pipefail
ARDUINO_APP_DEV_MODE=1 arduino-app-cli app start "$APP_ID"
REMOTE
