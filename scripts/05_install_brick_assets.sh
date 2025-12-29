#!/usr/bin/env bash
set -euo pipefail

# Install custom Brick assets (docs/API/examples) into the Uno Q App Lab assets tree.
# Usage:
#   ./05_install_brick_assets.sh \
#     --brick-name balancing_robot \
#     --local-assets ./unoq/arduino-app-cli-assets/0.6.2 \
#     --assets-version 0.6.2 \
#     --remote arduino@ada.local

BRICK_NAME=""
LOCAL_ASSETS=""
ASSETS_VERSION=""
REMOTE_HOST="${REMOTE_HOST:-${UNOQ_HOST:-arduino@ada.local}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brick-name) BRICK_NAME="$2"; shift 2;;
    --local-assets) LOCAL_ASSETS="$2"; shift 2;;
    --assets-version) ASSETS_VERSION="$2"; shift 2;;
    --remote) REMOTE_HOST="$2"; shift 2;;
    -h|--help)
      sed -n '1,80p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$BRICK_NAME" ]]; then
  echo "Missing required arg: --brick-name" >&2
  exit 1
fi

if [[ -z "$LOCAL_ASSETS" ]]; then
  LOCAL_ASSETS="./unoq/arduino-app-cli-assets"
fi

if [[ ! -d "$LOCAL_ASSETS" ]]; then
  echo "Local assets path not found: $LOCAL_ASSETS" >&2
  exit 1
fi

# If LOCAL_ASSETS points at the version directory, use it as-is.
if [[ -d "$LOCAL_ASSETS/docs" || -d "$LOCAL_ASSETS/api-docs" || -d "$LOCAL_ASSETS/examples" ]]; then
  ASSETS_DIR="$LOCAL_ASSETS"
else
  if [[ -z "$ASSETS_VERSION" ]]; then
    ASSETS_VERSION="$(find "$LOCAL_ASSETS" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V | tail -n 1)"
  fi
  ASSETS_DIR="$LOCAL_ASSETS/$ASSETS_VERSION"
fi

if [[ -z "$ASSETS_VERSION" ]]; then
  ASSETS_VERSION="$(basename "$ASSETS_DIR")"
fi

if [[ ! -d "$ASSETS_DIR" ]]; then
  echo "Assets directory not found: $ASSETS_DIR" >&2
  exit 1
fi

PATHS=()
if [[ -d "$ASSETS_DIR/docs/arduino/$BRICK_NAME" ]]; then
  PATHS+=("docs/arduino/$BRICK_NAME")
fi
if [[ -d "$ASSETS_DIR/api-docs/arduino/app_bricks/$BRICK_NAME" ]]; then
  PATHS+=("api-docs/arduino/app_bricks/$BRICK_NAME")
fi
if [[ -d "$ASSETS_DIR/examples/arduino/$BRICK_NAME" ]]; then
  PATHS+=("examples/arduino/$BRICK_NAME")
fi

if [[ ${#PATHS[@]} -eq 0 ]]; then
  echo "No assets found for brick '$BRICK_NAME' under: $ASSETS_DIR" >&2
  exit 1
fi

# shellcheck disable=SC2029
tar -C "$ASSETS_DIR" -czf - "${PATHS[@]}" | ssh "$REMOTE_HOST" "ASSETS_VERSION=$(printf '%q' "$ASSETS_VERSION") bash -s" <<'REMOTE'
set -euo pipefail
ASSETS_ROOT="/home/arduino/.local/share/arduino-app-cli/assets"
REMOTE_DIR="$ASSETS_ROOT/$ASSETS_VERSION"
mkdir -p "$REMOTE_DIR"
tar -xzf - -C "$REMOTE_DIR"
echo "Installed assets into $REMOTE_DIR"
REMOTE
