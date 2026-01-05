#!/usr/bin/env bash
set -euo pipefail

# Idempotent deploy of the app from this repo to UNO Q over SSH.
# Usage:
#   ./03_deploy_app_to_uno_q.sh --repo https://github.com/ripred/unoq-balancer-brick-bot.git --remote arduino@ada.local

REPO_URL=""
REMOTE_REPO_DIR="/home/arduino/unoq-balancer-brick-bot"
APP_SRC="unoq/ArduinoApps/balancing_bot_app"
REMOTE_HOST="${REMOTE_HOST:-${UNOQ_HOST:-arduino@ada.local}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_URL="$2"; shift 2;;
    --repo-dir) REMOTE_REPO_DIR="$2"; shift 2;;
    --app-src) APP_SRC="$2"; shift 2;;
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

APP_NAME="$(basename "$APP_SRC")"
REMOTE_APP_DIR="/home/arduino/ArduinoApps/$APP_NAME"

# shellcheck disable=SC2029
ssh "$REMOTE_HOST" "REPO_URL=$(printf '%q' "$REPO_URL") REPO_DIR=$(printf '%q' "$REMOTE_REPO_DIR") APP_SRC=$(printf '%q' "$APP_SRC") REMOTE_APP_DIR=$(printf '%q' "$REMOTE_APP_DIR") bash -s" <<'REMOTE'
set -euo pipefail

if [[ -d "$REPO_DIR/.git" ]]; then
  git -C "$REPO_DIR" fetch --all --prune
  git -C "$REPO_DIR" reset --hard origin/main
else
  rm -rf "$REPO_DIR"
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
fi

if [[ ! -d "$REPO_DIR/$APP_SRC" ]]; then
  echo "App source not found in repo: $REPO_DIR/$APP_SRC" >&2
  exit 1
fi

rm -rf "$REMOTE_APP_DIR"
mkdir -p "$REMOTE_APP_DIR"
cp -R "$REPO_DIR/$APP_SRC"/. "$REMOTE_APP_DIR"/
REMOTE

echo "Deployed $APP_SRC from $REPO_URL -> $REMOTE_HOST:$REMOTE_APP_DIR"
