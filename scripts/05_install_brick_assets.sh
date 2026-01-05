#!/usr/bin/env bash
set -euo pipefail

# Install custom Brick assets (docs/API/examples) into the Uno Q App Lab assets tree.
# Usage:
#   ./05_install_brick_assets.sh \
#     --repo https://github.com/ripred/unoq-balancer-brick-bot.git \
#     --brick-name balancing_robot \
#     --remote arduino@ada.local

REPO_URL=""
REMOTE_REPO_DIR="/home/arduino/unoq-balancer-brick-bot"
ASSETS_SRC="unoq/arduino-app-cli-assets/0.6.2"
BRICK_NAME="balancing_robot"
REMOTE_HOST="${REMOTE_HOST:-${UNOQ_HOST:-arduino@ada.local}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_URL="$2"; shift 2;;
    --repo-dir) REMOTE_REPO_DIR="$2"; shift 2;;
    --assets-src) ASSETS_SRC="$2"; shift 2;;
    --brick-name) BRICK_NAME="$2"; shift 2;;
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

if [[ -z "$REPO_URL" ]]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    REPO_URL="$(git config --get remote.origin.url || true)"
  fi
fi

if [[ -z "$REPO_URL" ]]; then
  echo "Missing required arg: --repo (or set a git origin in this repo)" >&2
  exit 1
fi

ASSETS_VERSION="$(basename "$ASSETS_SRC")"
REMOTE_ASSETS_DIR="/home/arduino/.local/share/arduino-app-cli/assets/$ASSETS_VERSION"

# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "REPO_URL=$(printf '%q' "$REPO_URL") REPO_DIR=$(printf '%q' "$REMOTE_REPO_DIR") ASSETS_SRC=$(printf '%q' "$ASSETS_SRC") BRICK_NAME=$(printf '%q' "$BRICK_NAME") REMOTE_ASSETS_DIR=$(printf '%q' "$REMOTE_ASSETS_DIR") bash -s" <<'REMOTE'
set -euo pipefail

if [[ -d "$REPO_DIR/.git" ]]; then
  git -C "$REPO_DIR" fetch --all --prune
  git -C "$REPO_DIR" reset --hard origin/main
else
  rm -rf "$REPO_DIR"
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
fi

for path in \
  "docs/arduino/$BRICK_NAME" \
  "api-docs/arduino/app_bricks/$BRICK_NAME" \
  "examples/arduino/$BRICK_NAME"; do
  if [[ ! -d "$REPO_DIR/$ASSETS_SRC/$path" ]]; then
    echo "Missing required path: $REPO_DIR/$ASSETS_SRC/$path" >&2
    exit 1
  fi
done

mkdir -p "$REMOTE_ASSETS_DIR/docs/arduino" \
  "$REMOTE_ASSETS_DIR/api-docs/arduino/app_bricks" \
  "$REMOTE_ASSETS_DIR/examples/arduino"

rm -rf "$REMOTE_ASSETS_DIR/docs/arduino/$BRICK_NAME"
rm -rf "$REMOTE_ASSETS_DIR/api-docs/arduino/app_bricks/$BRICK_NAME"
rm -rf "$REMOTE_ASSETS_DIR/examples/arduino/$BRICK_NAME"

cp -R "$REPO_DIR/$ASSETS_SRC/docs/arduino/$BRICK_NAME" \
  "$REMOTE_ASSETS_DIR/docs/arduino/"
cp -R "$REPO_DIR/$ASSETS_SRC/api-docs/arduino/app_bricks/$BRICK_NAME" \
  "$REMOTE_ASSETS_DIR/api-docs/arduino/app_bricks/"
cp -R "$REPO_DIR/$ASSETS_SRC/examples/arduino/$BRICK_NAME" \
  "$REMOTE_ASSETS_DIR/examples/arduino/"
REMOTE

echo "Installed brick assets from $REPO_URL -> $REMOTE_HOST:$REMOTE_ASSETS_DIR"
