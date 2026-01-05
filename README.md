# Uno Q Balancing Bot (Custom Brick + App)

This repo contains the raw source files needed to recreate the working Uno Q setup:
- custom `balancing_robot` brick (Python + docs/examples/API)
- `balancing_bot_app` App Lab application (Python + web UI + sketch)

No archives or scp are used by the scripts; they pull raw files via `git` on the board.

## Requirements
- Arduino Uno Q with App Lab runtime
- SSH access to the board (default `arduino@ada.local`)
- `git` installed on the board
- Host machine with `git` + `ssh`

## Recreate the running environment

Clone the repo:
```bash
git clone https://github.com/ripred/unoq-balancer-brick-bot.git
cd unoq-balancer-brick-bot
```

Set your board host (optional):
```bash
export UNOQ_HOST="arduino@ada.local"
```

Verify SSH works:
```bash
ssh "${UNOQ_HOST:-arduino@ada.local}" "uname -a"
```

1) Install the brick docs/examples/API into the App Lab assets cache:
```bash
./scripts/05_install_brick_assets.sh \
  --repo "$(git config --get remote.origin.url)" \
  --remote "${UNOQ_HOST:-arduino@ada.local}"
```

2) Register the brick in `bricks-list.yaml`:
```bash
./scripts/02_register_brick_on_uno_q.sh \
  --brick-id "arduino:balancing_robot" \
  --brick-name "Balancing Robot" \
  --remote "${UNOQ_HOST:-arduino@ada.local}"
```

3) Deploy the app to the Uno Q:
```bash
./scripts/03_deploy_app_to_uno_q.sh \
  --repo "$(git config --get remote.origin.url)" \
  --remote "${UNOQ_HOST:-arduino@ada.local}"
```

4) Start (or restart) the app:
```bash
ssh "${UNOQ_HOST:-arduino@ada.local}" "arduino-app-cli app start user:balancing_bot_app"
```

Open the dashboard:
```
http://ada.local:7000
```

## Verify
On the board:
```bash
arduino-app-cli app list
arduino-app-cli app logs user:balancing_bot_app
```

## Notes
- The scripts use `git` on the board to pull raw source files from this repo (no scp/archives).
- The board will build its own `.cache/` and venv under the app directory at runtime. Those are intentionally excluded from this repo.
- If your board uses a different assets version, pass `--assets-src` to `scripts/05_install_brick_assets.sh`.
- App + brick details are documented in `unoq/ArduinoApps/balancing_bot_app/README.md`.
