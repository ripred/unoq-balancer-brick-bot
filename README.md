# Arduino Uno Q Custom Brick + App (End-to-End Instructions)

These instructions are written for macOS, Windows, and Linux hosts.

IMPORTANT NAME NOTES (read first):
- In the examples below, the Uno Q board name is `ada`.
- The default Uno Q user is `arduino`.
- If your board name or username is different, replace `ada` and `arduino` in every command.

Example: if your board is named `myboard` and your user is `trent`, then:
  arduino@ada.local  -->  trent@myboard.local

Everything below assumes you are running commands from the repo root.

---

1) Prerequisites (host machine)

- Git installed
- SSH client available
- Bash shell (macOS/Linux terminals, or Git Bash / WSL on Windows)
- Arduino App Lab installed (recommended for UI + Brick gallery)
- Uno Q updated and reachable on your network

On Windows:
- Recommended: use WSL2 (Ubuntu) and run commands from WSL.
- Alternative: use Git Bash for SSH + git.

---

2) Clone the repo

  git clone https://github.com/ripred/unoq-balancer-brick-bot.git
  cd unoq-balancer-brick-bot

---

3) Set your board target (host machine)

Set UNOQ_HOST to match your board name and user:

  export UNOQ_HOST="arduino@ada.local"

You can also pass --remote in any script instead of setting UNOQ_HOST.

---

4) Confirm SSH works

  ssh "$UNOQ_HOST" "uname -a"

If this fails, fix networking or the board name first.

---

5) Install the Brick metadata (docs/API/examples) on the Uno Q

This makes your custom Brick show up in the App Lab Brick gallery.

  ./scripts/05_install_brick_assets.sh \
    --brick-name balancing_robot \
    --local-assets ./unoq/arduino-app-cli-assets/0.6.2

If your Uno Q uses a different App Lab assets version, add:
  --assets-version 0.6.2

---

6) Register the Brick in bricks-list.yaml

  ./scripts/02_register_brick_on_uno_q.sh \
    --brick-id "arduino:balancing_robot" \
    --brick-name "Balancing Robot" \
    --description "Balancing robot brick (custom)" \
    --category robotics

---

7) Deploy the app to the Uno Q

  ./scripts/03_deploy_app_to_uno_q.sh \
    --local-app ./unoq/ArduinoApps/balancing_bot_app

---

8) Start the app (dev mode)

  ./scripts/04_start_dev_mode.sh \
    --app-id "user:balancing_bot_app"

Open the dashboard:
  http://ada.local:7000

---

9) Create your own Brick + App (reusable workflow)

These scripts are project-agnostic. Use them for any future custom Brick/app.

Brick scaffold:
  ./scripts/00_scaffold_brick.sh \
    --brick-name my_brick \
    --brick-id "arduino:my_brick" \
    --brick-title "My Brick" \
    --brick-class MyBrick \
    --app-name my_brick_app

App scaffold:
  ./scripts/01_scaffold_app.sh \
    --app-name my_brick_app \
    --brick-id "arduino:my_brick" \
    --brick-python-name my_brick \
    --brick-class MyBrick \
    --app-description "My custom Uno Q app" \
    --app-icon "🧱" \
    --port 7000

Register your Brick:
  ./scripts/02_register_brick_on_uno_q.sh \
    --brick-id "arduino:my_brick" \
    --brick-name "My Brick" \
    --description "Custom brick (local)" \
    --category custom

Deploy your app:
  ./scripts/03_deploy_app_to_uno_q.sh \
    --local-app ./path/to/my_brick_app

Install your Brick docs/examples:
  ./scripts/05_install_brick_assets.sh \
    --brick-name my_brick \
    --local-assets ./path/to/assets/version

---

10) Notes

- These scripts are idempotent and safe to re-run.
- If rsync is not installed on your host, the deploy script falls back to tar over SSH.
- Shellcheck is required for script changes; run it on scripts before committing:
    shellcheck ./scripts/*.sh

---

11) Images (for the article series)

Planned screenshots to include in posts:
- Brick gallery README tab
- Brick gallery Example Usage tab
- Brick gallery API Documentation tab
- App README page (as rendered in App Lab)
- Live HTML dashboard running
