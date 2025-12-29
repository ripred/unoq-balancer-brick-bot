#!/usr/bin/env bash
set -euo pipefail

# Idempotent brick registration in UNO Q bricks-list.yaml
# Usage:
#   ./02_register_brick_on_uno_q.sh \
#     --brick-id "arduino:balancing_robot" \
#     --brick-name "Balancing Robot" \
#     --description "Custom brick (local)" \
#     --category robotics \
#     --ports "" \
#     --assets-version 0.6.2 \
#     --remote arduino@ada.local

BRICK_ID=""
BRICK_NAME=""
BRICK_DESC=""
BRICK_CATEGORY="custom"
BRICK_PORTS=""
ASSETS_VERSION=""
REMOTE_HOST="${REMOTE_HOST:-${UNOQ_HOST:-arduino@ada.local}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brick-id) BRICK_ID="$2"; shift 2;;
    --brick-name) BRICK_NAME="$2"; shift 2;;
    --description) BRICK_DESC="$2"; shift 2;;
    --category) BRICK_CATEGORY="$2"; shift 2;;
    --ports) BRICK_PORTS="$2"; shift 2;;
    --assets-version) ASSETS_VERSION="$2"; shift 2;;
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

if [[ -z "$BRICK_DESC" ]]; then
  BRICK_DESC="Custom brick (local)"
fi

# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "BRICK_ID=$(printf '%q' "$BRICK_ID") BRICK_NAME=$(printf '%q' "$BRICK_NAME") BRICK_DESC=$(printf '%q' "$BRICK_DESC") BRICK_CATEGORY=$(printf '%q' "$BRICK_CATEGORY") BRICK_PORTS=$(printf '%q' "$BRICK_PORTS") ASSETS_VERSION=$(printf '%q' "$ASSETS_VERSION") bash -s" <<'REMOTE'
set -euo pipefail

ASSETS_ROOT="/home/arduino/.local/share/arduino-app-cli/assets"
if [[ -z "$ASSETS_VERSION" ]]; then
  ASSETS_VERSION="$(ls -1 "$ASSETS_ROOT" | sort -V | tail -n 1)"
fi
LIST_PATH="$ASSETS_ROOT/$ASSETS_VERSION/bricks-list.yaml"

if [[ ! -f "$LIST_PATH" ]]; then
  echo "bricks-list.yaml not found: $LIST_PATH" >&2
  exit 1
fi

if [[ -n "$BRICK_PORTS" ]]; then
  PORTS_YAML="[${BRICK_PORTS// /}]"
else
  PORTS_YAML="[]"
fi

if ! grep -q "id: $BRICK_ID" "$LIST_PATH"; then
  cat >> "$LIST_PATH" <<YAML
- id: __BRICK_ID__
  name: __BRICK_NAME__
  description: __BRICK_DESC__
  require_container: false
  require_model: false
  mount_devices_into_container: false
  ports: __BRICK_PORTS__
  category: __BRICK_CATEGORY__
YAML
  sed -i "s|__BRICK_ID__|$BRICK_ID|" "$LIST_PATH"
  sed -i "s|__BRICK_NAME__|$BRICK_NAME|" "$LIST_PATH"
  sed -i "s|__BRICK_DESC__|$BRICK_DESC|" "$LIST_PATH"
  sed -i "s|__BRICK_PORTS__|$PORTS_YAML|" "$LIST_PATH"
  sed -i "s|__BRICK_CATEGORY__|$BRICK_CATEGORY|" "$LIST_PATH"
else
  echo "Brick already registered: $BRICK_ID"
fi
REMOTE
