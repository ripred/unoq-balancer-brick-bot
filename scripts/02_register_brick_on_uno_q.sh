#!/usr/bin/env bash
set -euo pipefail

# Idempotent brick registration in UNO Q bricks-list.yaml
# Usage:
#   ./02_register_brick_on_uno_q.sh \
#     --brick-id "arduino:balancing_robot" \
#     --brick-name "Balancing Robot" \
#     --remote arduino@ada.local

BRICK_ID=""
BRICK_NAME=""
REMOTE_HOST="arduino@ada.local"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brick-id) BRICK_ID="$2"; shift 2;;
    --brick-name) BRICK_NAME="$2"; shift 2;;
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

if [[ -z "$BRICK_ID" || -z "$BRICK_NAME" ]]; then
  echo "Missing required args. Use --brick-id and --brick-name." >&2
  exit 1
fi

LIST_PATH="/home/arduino/.local/share/arduino-app-cli/assets/0.6.2/bricks-list.yaml"

# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "BRICK_ID=$(printf '%q' "$BRICK_ID") BRICK_NAME=$(printf '%q' "$BRICK_NAME") LIST_PATH=$(printf '%q' "$LIST_PATH") bash -s" <<'REMOTE'
set -euo pipefail

if ! grep -q "id: $BRICK_ID" "$LIST_PATH"; then
  cat >> "$LIST_PATH" <<'YAML'
- id: __BRICK_ID__
  name: __BRICK_NAME__
  description: Balancing robot brick (custom)
  require_container: false
  require_model: false
  mount_devices_into_container: false
  ports: []
  category: robotics
YAML
  sed -i "s|__BRICK_ID__|$BRICK_ID|" "$LIST_PATH"
  sed -i "s|__BRICK_NAME__|$BRICK_NAME|" "$LIST_PATH"
else
  echo "Brick already registered: $BRICK_ID"
fi
REMOTE
