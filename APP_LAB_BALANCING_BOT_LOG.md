# Balancing Robot Brick + App Lab Project Log

## ELI5 intro
We're going to build a new Lego-like software block (a **Brick**) that makes a balancing robot easy to use in Arduino App Lab. The Arduino Uno Q has two "brains":
- The **MCU** (microcontroller) is fast and handles real-time motor control and sensors.
- The **MPU** (Linux computer) is great at networking, web pages, and dashboards.

So we split the work: the MCU keeps the robot balanced every millisecond, and the MPU shows a live dashboard you can open in a browser to tune the robot without touching the hardware.

What we'll build:
- A **custom Brick** called `balancing_robot` that provides a clean Python API for the App Lab.
- A **custom App Lab app** that uses that Brick and ships with:
  - a custom Arduino sketch (`.ino`) for the MCU
  - a Python app for the MPU
  - a web dashboard for tuning and live visualization

We'll do it step-by-step, starting with mapping where App Lab stores bricks and apps, then scaffolding the Brick, then building the app and dashboard, and finally testing on hardware.

---

## Milestone summaries

### Milestone 1: Environment discovery + initial documentation sources
- Verified the host has Arduino App Lab installed and located the app bundle.
- Confirmed the UNO Q is reachable and inspected its app/brick-related directories.
- Found the UNO Q's App CLI asset cache containing a brick registry and examples.
- Pulled the official Brick development guide for the app-bricks-py structure and workflow.
- Collected a representative sample of moderator posts/comments to align tone for the eventual subreddit writeup.

Next up:
- Create a minimal App Lab app and deploy it so we can confirm the exact on-device app layout.
- Locate the runtime Python environment that loads `arduino.app_bricks` on the UNO Q.
- Draft the `balancing_robot` Brick skeleton and the app scaffold (MCU sketch + MPU python + assets).

---

## Command log (chronological)

### Terminal commands
1. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'uname -a'`
2. `ls /Applications | rg -i 'app lab'`
3. `mdfind "kMDItemFSName == 'App Lab.app'"`
4. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'ls -la / && ls -la /home/arduino'`
5. `mdfind "kMDItemFSName == 'Arduino App Lab.app'"`
6. `ls -la "/Applications/Arduino App Lab.app/Contents"`
7. `ls -la "/Applications/Arduino App Lab.app/Contents/Resources"`
8. `find ~/Library -maxdepth 6 -type d -iname '*brick*'`
9. `ls -la ~/Library/Application\ Support | rg -i 'arduino|app lab|bricks'`
10. `ls -la ~/Library/Application\ Support/arduino-electron`
11. `ls -la "/Applications/Arduino App Lab.app/Contents/MacOS"`
12. `find ~ -maxdepth 6 -type d -iname '*app*lab*'`
13. `ls -la ~/Library/Containers | rg -i 'applab|arduino'`
14. `rg --files -g '*applab*' ~/Library`
15. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'ls -la /home/arduino/.arduino-bricks && find /home/arduino/.arduino-bricks -maxdepth 3 -type d'`
16. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'ls -la /home/arduino/ArduinoApps && find /home/arduino/ArduinoApps -maxdepth 2 -type d'`
17. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /opt /usr /home/arduino -maxdepth 6 -type d -iname "*brick*" 2>/dev/null'`
18. `find /Applications -maxdepth 6 -type d -iname '*brick*' 2>/dev/null`
19. `find /Library -maxdepth 6 -type d -iname '*brick*' 2>/dev/null`
20. `rg -a -m 40 -n "brick" "/Applications/Arduino App Lab.app/Contents/MacOS/Arduino App Lab"`
21. `ls -la ~/Library/Caches/cc.arduino.applab`
22. `find ~/Library/Caches/cc.arduino.applab -maxdepth 4 -type d`
23. `rg --files -g '*brick*' ~/Library/Caches/cc.arduino.applab`
24. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'python3 - <<"PY"\nimport arduino, arduino.app_bricks, sys, pkgutil\nprint("arduino:", arduino.__file__)\nprint("app_bricks:", arduino.app_bricks.__file__)\nprint("site-packages:", [p for p in sys.path if "site-packages" in p][:2])\nprint("bricks:", [m.name for m in pkgutil.iter_modules(arduino.app_bricks.__path__)][:20])\nPY'`
25. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /opt /usr -maxdepth 6 -type d -name "app_bricks" 2>/dev/null'`
26. `plutil -p ~/Library/Preferences/cc.arduino.applab.plist`
27. `find ~/Library -maxdepth 5 -type d -name 'cc.arduino.applab*'`
28. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'docker ps -a'`
29. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /home/arduino -maxdepth 6 -type f -iname "*brick*" 2>/dev/null'`
30. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/bricks-list.yaml'`
31. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'ls -la /home/arduino/.local/share/arduino-app-cli/assets/0.6.2'`
32. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/compose -maxdepth 3 -type f -print'`
33. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'which arduino-app-cli && arduino-app-cli version'`
34. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/docs -maxdepth 2 -type f -print'`
35. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/examples -maxdepth 3 -type f -print'`
36. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/examples/arduino/web_ui/1_serve_webapp.py'`
37. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/examples/arduino/web_ui/2_serve_webapp_and_api.py'`
38. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /home/arduino -maxdepth 6 -type d -name "app_bricks" 2>/dev/null'`
39. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /home/arduino /usr /opt -maxdepth 6 -type f -iname "*app_bricks*" 2>/dev/null'`
40. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/examples -maxdepth 5 -type f -iname "*app*" -o -iname "*manifest*"'`
41. `cat <<'EOF' > /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`
42. `sed -n '60,140p' /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`
43. `apply_patch: update /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md (failed match)`
44. `apply_patch: update /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md (add command 41)`
45. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`
46. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`

### Web lookups (no passwords involved)
1. `web.run search_query: u/ripred3 Reddit Arduino posts comments`
2. `web.run search_query: site:reddit.com "ripred3" Arduino`
3. `web.run search_query: "ripred3" "arduino" Reddit comment`
4. `web.run open: https://deepwiki.com/arduino/app-bricks-py/3-brick-development-guide`

---

## Notes / requirements
- Produce shell scripts to automate boilerplate scaffolding steps so readers can reproduce easily.
- Markdown rule: when adding source code blocks, use 4-space indentation (no triple backticks) to avoid breaking outer fenced blocks.

### Terminal commands (continued)
47. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli --help'`
48. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli app --help'`
49. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli app new --help'`
56. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'echo "## app_utils.py (local/usr)"; find /home/arduino/.local /usr/lib /usr/local -type f -name "app_utils.py" 2>/dev/null; echo "## arduino python packages"; find /home/arduino/.local /usr/lib /usr/local -type d -path "*site-packages/arduino*" 2>/dev/null; echo "## arduino app cli assets"; ls -la /home/arduino/.local/share/arduino-app-cli || true'`
57. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'command -v rg >/dev/null && rg -n "app_utils" /home/arduino /usr/lib /usr/local 2>/dev/null | head -n 50'`
58. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'which rg || true'`
59. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'grep -R "app_utils" -n /home/arduino/.local /home/arduino/ArduinoApps --include "*.py" 2>/dev/null | head -n 50'`
60. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'echo "## app_utils dirs"; find /home/arduino /usr /opt -type d -name "app_utils" 2>/dev/null; echo "## arduino/app_utils dirs"; find /home/arduino /usr /opt -type d -path "*/arduino/app_utils" 2>/dev/null'`
61. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'ls -la /usr/lib | grep -i arduino || true'`
62. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'ls -la /opt'`
64. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli app list'`
66. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'docker ps -a | head -n 20'`
67. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/compose/arduino/audio_classification/brick_compose.yaml'`
69. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /home/arduino/.local/share/arduino-app-cli/examples -maxdepth 3 -name app.yaml -print | head -n 5'`
70. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/examples/blink-with-ui/app.yaml'`
76. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'docker run --rm --entrypoint cat ghcr.io/arduino/app-bricks/python-apps-base:0.6.2 /run.sh'`
77. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'grep -R "app_utils" -n /home/arduino/.local /home/arduino/ArduinoApps --include "*.py" 2>/dev/null | head -n 50'`
78. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`

### Milestone 2: App layout + runtime container model
- Created a probe app via arduino-app-cli and mapped its on-device structure: app.yaml, python/main.py, sketch/sketch.ino, sketch/sketch.yaml.
- Confirmed apps run inside a Docker container (python-apps-base:0.6.2) with /app bind-mounted to the app folder.
- Extracted /run.sh from the container image to understand the runtime: it creates a venv under /app/.cache/.venv, installs wheels from /app/python-libraries and requirements.txt, then runs /app/python/main.py.
- Learned that custom Python code can be added under /app/python (script directory is on sys.path), and extra libraries can be provided as wheels via /app/python-libraries.

Next up:
- Draft idempotent SSH-run scripts to scaffold the custom Brick and App structure.
- Add a bricks-list.yaml entry on the UNO Q so the Brick appears in App Lab.
- Implement the first draft of the balancing_robot Brick API + app skeleton.

79. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`
- Article note: explain the container model early (apps run in python-apps-base container with /app bind-mount and venv under /app/.cache/.venv).

### Milestone 3: SSH-based idempotent scaffolding scripts
- Added SSH-run, idempotent scripts to scaffold the Brick, the App, register the Brick, deploy an app folder, and start dev mode.
- Scripts are stored under ./scripts and are designed for copy/paste use in the article.

Next up:
- Run the scripts against the UNO Q to confirm they work end-to-end.
- Fill in the balancing_robot Brick API, add telemetry protocol, and wire the Web UI.

80. `mkdir -p /Users/trent/dev/codex-agents/scripts`
81. `cat <<'EOF' > /Users/trent/dev/codex-agents/scripts/00_scaffold_brick.sh`
82. `cat <<'EOF' > /Users/trent/dev/codex-agents/scripts/01_scaffold_app.sh`
83. `cat <<'EOF' > /Users/trent/dev/codex-agents/scripts/02_register_brick_on_uno_q.sh`
84. `cat <<'EOF' > /Users/trent/dev/codex-agents/scripts/03_deploy_app_to_uno_q.sh`
85. `cat <<'EOF' > /Users/trent/dev/codex-agents/scripts/04_start_dev_mode.sh`
86. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`
87. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`
- Requirement: run shellcheck on all scripts and fix all issues/warnings until clean.
88. `chmod +x /Users/trent/dev/codex-agents/scripts/00_scaffold_brick.sh /Users/trent/dev/codex-agents/scripts/01_scaffold_app.sh /Users/trent/dev/codex-agents/scripts/02_register_brick_on_uno_q.sh /Users/trent/dev/codex-agents/scripts/03_deploy_app_to_uno_q.sh /Users/trent/dev/codex-agents/scripts/04_start_dev_mode.sh`
89. `/Users/trent/dev/codex-agents/scripts/00_scaffold_brick.sh --brick-name balancing_robot --brick-id "arduino:balancing_robot" --remote arduino@ada.local`
90. `nl -ba /Users/trent/dev/codex-agents/scripts/00_scaffold_brick.sh | sed -n '35,80p'`
91. `nl -ba /Users/trent/dev/codex-agents/scripts/00_scaffold_brick.sh | tail -n 20`
92. `apply_patch: update /Users/trent/dev/codex-agents/scripts/00_scaffold_brick.sh (fix heredoc/ssh)`
93. `/Users/trent/dev/codex-agents/scripts/00_scaffold_brick.sh --brick-name balancing_robot --brick-id "arduino:balancing_robot" --remote arduino@ada.local`
94. `/Users/trent/dev/codex-agents/scripts/02_register_brick_on_uno_q.sh --brick-id "arduino:balancing_robot" --brick-name "Balancing Robot" --remote arduino@ada.local`
95. `apply_patch: update /Users/trent/dev/codex-agents/scripts/00_scaffold_brick.sh (arg passing refactor)`
96. `apply_patch: update /Users/trent/dev/codex-agents/scripts/01_scaffold_app.sh (arg passing refactor)`
97. `apply_patch: update /Users/trent/dev/codex-agents/scripts/02_register_brick_on_uno_q.sh (arg passing refactor)`
98. `apply_patch: update /Users/trent/dev/codex-agents/scripts/03_deploy_app_to_uno_q.sh (arg passing refactor)`
99. `apply_patch: update /Users/trent/dev/codex-agents/scripts/04_start_dev_mode.sh (arg passing refactor)`
100. `shellcheck -x /Users/trent/dev/codex-agents/scripts/*.sh`
101. `apply_patch: update /Users/trent/dev/codex-agents/scripts/01_scaffold_app.sh (remove unused var)`
102. `shellcheck -x /Users/trent/dev/codex-agents/scripts/*.sh`
103. `apply_patch: update /Users/trent/dev/codex-agents/scripts/00_scaffold_brick.sh (SC2259 fix)`
104. `apply_patch: update /Users/trent/dev/codex-agents/scripts/01_scaffold_app.sh (SC2259 fix)`
105. `apply_patch: update /Users/trent/dev/codex-agents/scripts/02_register_brick_on_uno_q.sh (SC2259 fix)`
106. `apply_patch: update /Users/trent/dev/codex-agents/scripts/03_deploy_app_to_uno_q.sh (SC2259 fix)`
107. `apply_patch: update /Users/trent/dev/codex-agents/scripts/04_start_dev_mode.sh (SC2259 fix)`
108. `shellcheck -x /Users/trent/dev/codex-agents/scripts/*.sh`
109. `/Users/trent/dev/codex-agents/scripts/02_register_brick_on_uno_q.sh --brick-id "arduino:balancing_robot" --brick-name "Balancing Robot" --remote arduino@ada.local`
110. `/Users/trent/dev/codex-agents/scripts/01_scaffold_app.sh --app-name balancing_bot_app --brick-id "arduino:balancing_robot" --remote arduino@ada.local`
111. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`

### Milestone 4: Scripts validated + scaffolds applied on UNO Q
- All scaffolding scripts pass shellcheck with no warnings.
- balancing_robot brick scaffold created on UNO Q.
- balancing_bot_app scaffold created on UNO Q and linked to the balancing_robot brick in app.yaml.
- Brick registered in the UNO Q bricks list.

Next up:
- Flesh out the brick API and telemetry protocol.
- Add dashboard assets and a simple WebUI server stub.

112. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/examples/arduino/web_ui/5_send_message.py; echo "---"; sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/assets/0.6.2/examples/arduino/web_ui/4_on_message.py; echo "---"; sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/examples/blink-with-ui/python/main.py'`
113. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'find /home/arduino/.local/share/arduino-app-cli/examples/blink-with-ui -maxdepth 2 -type f -print'`
114. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/examples/blink-with-ui/assets/app.js'`
115. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,120p" /home/arduino/.local/share/arduino-app-cli/examples/blink-with-ui/app.yaml'`
116. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,200p" /home/arduino/.local/share/arduino-app-cli/examples/blink-with-ui/assets/index.html'`
117. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'ls -la /home/arduino/.local/share/arduino-app-cli/examples/blink-with-ui/assets/libs'`
118. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'APP_DIR=/home/arduino/ArduinoApps/balancing_bot_app; BRICK_DIR=$APP_DIR/python/arduino/app_bricks/balancing_robot; mkdir -p $BRICK_DIR; mkdir -p $APP_DIR/python/arduino/app_bricks; mkdir -p $APP_DIR/python/arduino; if [ ! -f $APP_DIR/python/arduino/__init__.py ]; then echo "" > $APP_DIR/python/arduino/__init__.py; fi; if [ ! -f $APP_DIR/python/arduino/app_bricks/__init__.py ]; then echo "" > $APP_DIR/python/arduino/app_bricks/__init__.py; fi; cat > $BRICK_DIR/__init__.py <<"PY" ... PY; cat > $APP_DIR/python/main.py <<"PY" ... PY; mkdir -p $APP_DIR/assets/libs; cp ...; cat > $APP_DIR/assets/index.html <<"HTML" ... HTML; cat > $APP_DIR/assets/style.css <<"CSS" ... CSS; cat > $APP_DIR/assets/app.js <<"JS" ... JS'`
119. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`

### Milestone 5: Brick API + WebUI stub (simulation)
- Implemented balancing_robot brick class with simulated telemetry, PID control logic, and WebUI message handlers.
- Wired main.py to WebUI + BalancingRobot in simulation mode.
- Added dashboard assets (HTML/CSS/JS) with live telemetry, basic chart, and wireframe view.
- Copied socket.io client bundle into assets for WebUI connectivity.

Next up:
- Run the app to verify the dashboard loads and streams simulated telemetry.
- Refine telemetry schema and start mapping real IMU/encoder integration points for the MCU sketch.

120. `shellcheck -x /Users/trent/dev/codex-agents/scripts/*.sh`
121. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'APP_DIR=/home/arduino/ArduinoApps/balancing_bot_app; rm -f $APP_DIR/python/arduino/__init__.py $APP_DIR/python/arduino/app_bricks/__init__.py; cat > $APP_DIR/python/main.py <<"PY" ... PY'`
122. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli app start user:balancing_bot_app'`
123. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli app logs user:balancing_bot_app | tail -n 30'`
124. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'docker exec balancing_bot_app-main-1 python -c "import arduino.app_utils; print(\"ok\")"'`
125. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`

### Milestone 6: App running + module shadowing fix
- Resolved module shadowing by removing local arduino/__init__.py and extending arduino.app_bricks.__path__ in main.py.
- App now starts successfully and WebUI reports the dashboard URL.
- Verified arduino.app_utils import inside the running container.

Next up:
- Confirm dashboard loads and streams telemetry from a browser.
- Add a small readme snippet for how to open the WebUI and tune PID.

- Article note: explain the tools used (arduino-app-cli, Docker container, WebUI brick, socket.io, rsync/ssh scripts) early in the writeup.
126. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'sed -n "1,120p" /home/arduino/ArduinoApps/balancing_bot_app/app.yaml'`
127. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/app.yaml <<"YAML" ... YAML'`
128. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli app restart user:balancing_bot_app'`
129. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli app logs user:balancing_bot_app | tail -n 30'`
130. `apply_patch: update /Users/trent/dev/codex-agents/scripts/01_scaffold_app.sh (include web_ui + ports)`
131. `shellcheck -x /Users/trent/dev/codex-agents/scripts/*.sh`
132. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`
- Requirement: maintain simulation/mock mode alongside real IMU/motor support until hardware is attached.
133. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'APP_DIR=/home/arduino/ArduinoApps/balancing_bot_app; cat > $APP_DIR/assets/index.html <<"HTML" ... HTML; cat > $APP_DIR/assets/app.js <<"JS" ... JS'`
134. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'APP_DIR=/home/arduino/ArduinoApps/balancing_bot_app; cat > $APP_DIR/python/arduino/app_bricks/balancing_robot/__init__.py <<"PY" ... PY'`
135. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli app restart user:balancing_bot_app'`
136. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`
137. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'APP_DIR=/home/arduino/ArduinoApps/balancing_bot_app; cat > $APP_DIR/python/main.py <<"PY" ... PY'`
138. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'APP_DIR=/home/arduino/ArduinoApps/balancing_bot_app; cat > $APP_DIR/python/arduino/app_bricks/balancing_robot/__init__.py <<"PY" ... PY'`
139. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'APP_DIR=/home/arduino/ArduinoApps/balancing_bot_app; cat > $APP_DIR/assets/app.js <<"JS" ... JS'`
140. `ssh -o BatchMode=yes -o ConnectTimeout=10 arduino@ada.local 'arduino-app-cli app restart user:balancing_bot_app'`
141. `cat <<'EOF' >> /Users/trent/dev/codex-agents/APP_LAB_BALANCING_BOT_LOG.md`
- Requirement: dashboard is responsive (mobile/portrait vs desktop/landscape), supports light/dark themes, and later adds tasteful visual polish.

### Terminal commands (continued)
114. `ssh arduino@10.102.67.134 'sed -n "1,240p" /home/arduino/ArduinoApps/balancing_bot_app/assets/style.css'`
115. `ssh arduino@10.102.67.134 'sed -n "1,200p" /home/arduino/ArduinoApps/balancing_bot_app/assets/index.html'`
116. `ssh arduino@10.102.67.134 'cat > /home/arduino/ArduinoApps/balancing_bot_app/assets/index.html <<"EOF" ... EOF'`
117. `ssh arduino@10.102.67.134 'cat > /home/arduino/ArduinoApps/balancing_bot_app/assets/style.css <<"EOF" ... EOF'`

Notes:
- Adjusted PID control layout to a flex-based layout to prevent overlap on small widths.

### Terminal commands (continued)
142. `ssh arduino@ada.local`
143. `ls -la /home/arduino/ArduinoApps`
144. `arduino-app-cli app list`
145. `sed -n "1,160p" /home/arduino/ArduinoApps/balancing_bot_app/app.yaml`
146. `sed -n "1,200p" /home/arduino/ArduinoApps/balancing_bot_app/python/main.py`
147. `sed -n "1,260p" /home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py`
148. `curl -s http://ada.local:7000/status | head -c 500`
149. `ssh arduino@ada.local 'sed -n "1,220p" /home/arduino/ArduinoApps/balancing_bot_app/assets/style.css'`
150. `curl -s http://ada.local:7000/ | head -n 20`
151. `curl -I http://ada.local:7000/libs/socket.io.min.js | head -n 10`
152. `ssh arduino@ada.local 'sed -n "1,200p" /home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino'`
153. `ssh arduino@ada.local 'sed -n "1,200p" /home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.yaml'`
155. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py <<\"PY\" ... PY'`
157. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino <<\"CPP\" ... CPP'`
159. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.yaml <<\"YAML\" ... YAML'`
161. `ssh arduino@ada.local 'curl -fsSL -o /home/arduino/ArduinoApps/balancing_bot_app/sketch/libraries/PID/PID_v1.h https://raw.githubusercontent.com/br3ttb/Arduino-PID-Library/master/PID_v1.h'`
162. `ssh arduino@ada.local 'curl -fsSL -o /home/arduino/ArduinoApps/balancing_bot_app/sketch/libraries/PID/PID_v1.cpp https://raw.githubusercontent.com/br3ttb/Arduino-PID-Library/master/PID_v1.cpp'`
165. `ssh arduino@ada.local 'cp /home/arduino/ArduinoApps/balancing_bot_app/sketch/libraries/PID/PID_v1.h /home/arduino/ArduinoApps/balancing_bot_app/sketch/PID_v1.h'`
166. `ssh arduino@ada.local 'cp /home/arduino/ArduinoApps/balancing_bot_app/sketch/libraries/PID/PID_v1.cpp /home/arduino/ArduinoApps/balancing_bot_app/sketch/PID_v1.cpp'`
169. `cat > /Users/trent/dev/codex-agents/tmp_sketch.ino`
170. `scp /Users/trent/dev/codex-agents/tmp_sketch.ino arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino`
172. `ssh arduino@ada.local 'arduino-app-cli app stop user:balancing_bot_app; sleep 2; arduino-app-cli app start user:balancing_bot_app'`
173. `curl -s http://ada.local:7000/status | head -c 300`

### Milestone 8: First-pass hardware scaffolding + PID_v1
- Added real-mode hooks to the balancing_robot brick (sensor provider + motor sink) while keeping simulation intact.
- Replaced placeholder MCU sketches with a PID_v1-based control loop, motor/encoder stubs, and a simple serial command protocol.
- Vendored Brett Beauregard's PID_v1 sources into each sketch folder to satisfy the PID_v1 requirement.
- Restarted the app and verified /status still returns live telemetry.

Next up:
- Wire the Python brick to the MCU serial link (parse `T,...` lines + send PID/SET/MODE commands).
- Decide pin mappings for the actual motor driver + encoder wiring and update constants.

### Milestone 7: Live app verification on board
- Confirmed `balancing_bot_app` is running on the UNO Q and serving the WebUI port (7000).
- Verified `/status` returns live simulated telemetry + config from the brick.
- Reconfirmed the local brick wiring in `python/main.py` and the simulation loop in the brick.

Next up:
- Open the dashboard in a browser and confirm socket.io telemetry streaming (not just polling).
- Inspect/adjust the WebUI assets for any remaining layout or theme issues.
- Start mapping real IMU + motor integration points in the MCU sketch and Python brick while keeping simulation mode intact.

### Terminal commands (continued)
174. `ssh arduino@ada.local 'grep -R "Bridge" -n /home/arduino/.local/share/arduino-app-cli/examples --include "*.py" | head -n 40'`
175. `ssh arduino@ada.local 'sed -n "70,170p" /home/arduino/.local/share/arduino-app-cli/examples/real-time-accelerometer/python/main.py'`
176. `ssh arduino@ada.local 'grep -R "Bridge\\." -n /home/arduino/.local/share/arduino-app-cli/examples/*/sketch/sketch.ino | head -n 80'`
177. `ssh arduino@ada.local 'sed -n "1,120p" /home/arduino/.local/share/arduino-app-cli/examples/real-time-accelerometer/sketch/sketch.ino'`
178. `ssh arduino@ada.local 'sed -n "1,120p" /home/arduino/.local/share/arduino-app-cli/examples/blink-with-ui/sketch/sketch.ino'`
179. `ssh arduino@ada.local 'sed -n "1,120p" /home/arduino/.local/share/arduino-app-cli/examples/weather-forecast/sketch/sketch.ino'`
180. `cat > /Users/trent/dev/codex-agents/tmp_sketch.ino`
181. `scp /Users/trent/dev/codex-agents/tmp_sketch.ino arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino`
183. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py <<\"PY\" ... PY'`
185. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/python/main.py <<\"PY\" ... PY'`
186. `ssh arduino@ada.local 'arduino-app-cli app stop user:balancing_bot_app; sleep 2; arduino-app-cli app start user:balancing_bot_app'`
187. `curl -s http://ada.local:7000/status | head -c 300`
188. `curl -s 'http://ada.local:7000/set_mode?mode=real' | head -c 200`
189. `sleep 1; curl -s http://ada.local:7000/status | head -c 300`
190. `curl -s 'http://ada.local:7000/set_mode?mode=sim' | head -c 200`
191. `cat > /Users/trent/dev/codex-agents/tmp_sketch.ino`
192. `scp /Users/trent/dev/codex-agents/tmp_sketch.ino arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino`
194. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py <<\"PY\" ... PY'`
196. `ssh arduino@ada.local 'arduino-app-cli app stop user:balancing_bot_app; sleep 2; arduino-app-cli app start user:balancing_bot_app'`
197. `curl -s 'http://ada.local:7000/set_mode?mode=real' | head -c 200`
198. `sleep 1; curl -s http://ada.local:7000/status | head -c 300`
199. `ssh arduino@ada.local 'arduino-app-cli app logs user:balancing_bot_app | tail -n 40'`
200. `cat > /Users/trent/dev/codex-agents/tmp_sketch.ino`
201. `scp /Users/trent/dev/codex-agents/tmp_sketch.ino arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino`
203. `ssh arduino@ada.local 'python3 - <<\"PY\" ... PY'`
204. `ssh arduino@ada.local 'arduino-app-cli app stop user:balancing_bot_app; sleep 2; arduino-app-cli app start user:balancing_bot_app'`
205. `curl -s 'http://ada.local:7000/set_mode?mode=real' | head -c 200`
206. `curl -s 'http://ada.local:7000/set_pid?p=20&i=0.2&d=0.6' | head -c 200`
207. `sleep 1; curl -s http://ada.local:7000/status | head -c 260`
208. `curl -s 'http://ada.local:7000/kick?angle=45' | head -c 200`
209. `sleep 1; curl -s http://ada.local:7000/status | head -c 260`
210. `curl -s 'http://ada.local:7000/set_mode?mode=sim' | head -c 200`
211. `curl -s 'http://ada.local:7000/kick?angle=45' | head -c 200`
212. `sleep 1; curl -s http://ada.local:7000/status | head -c 260`
213. `cat > /Users/trent/dev/codex-agents/tmp_sketch.ino`
214. `scp /Users/trent/dev/codex-agents/tmp_sketch.ino arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino`
216. `ssh arduino@ada.local 'arduino-app-cli app stop user:balancing_bot_app; sleep 2; arduino-app-cli app start user:balancing_bot_app'`
217. `curl -s 'http://ada.local:7000/set_mode?mode=real' | head -c 200`
218. `sleep 1; curl -s http://ada.local:7000/status | head -c 260`
219. `cat > /Users/trent/dev/codex-agents/tmp_sketch.ino`
220. `scp /Users/trent/dev/codex-agents/tmp_sketch.ino arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino`
222. `cat > /Users/trent/dev/codex-agents/tmp_app.js`
223. `scp /Users/trent/dev/codex-agents/tmp_app.js arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/assets/app.js`
224. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/assets/index.html <<\"HTML\" ... HTML'`
225. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py <<\"PY\" ... PY'`
227. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/python/main.py <<\"PY\" ... PY'`
228. `ssh arduino@ada.local 'arduino-app-cli app restart user:balancing_bot_app'`
229. `curl -s http://ada.local:7000/status | head -c 200`
230. `curl -s 'http://ada.local:7000/set_axis_mode?axis_mode=roll' | head -c 200`
231. `curl -s http://ada.local:7000/status | head -c 200`
232. `cat > /Users/trent/dev/codex-agents/tmp_sketch.ino`
233. `scp /Users/trent/dev/codex-agents/tmp_sketch.ino arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino`
235. `scp arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py /Users/trent/dev/codex-agents/brick_balancing_robot.py`
236. `scp arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/assets/index.html /Users/trent/dev/codex-agents/brick_index.html`
237. `scp arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/assets/app.js /Users/trent/dev/codex-agents/brick_app.js`
238. `scp /Users/trent/dev/codex-agents/brick_index.html arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/assets/index.html`
239. `scp /Users/trent/dev/codex-agents/brick_app.js arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/assets/app.js`
240. `scp /Users/trent/dev/codex-agents/brick_balancing_robot.py arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py`
242. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/python/main.py <<\"PY\" ... PY'`
243. `ssh arduino@ada.local 'arduino-app-cli app stop user:balancing_bot_app; sleep 2; arduino-app-cli app start user:balancing_bot_app'`
244. `curl -s http://ada.local:7000/status | head -c 220`
245. `curl -s 'http://ada.local:7000/set_motor_invert?left=-1&right=1' | head -c 200`
246. `curl -s 'http://ada.local:7000/set_encoder_invert?left=-1&right=-1' | head -c 200`
247. `cat > /Users/trent/dev/codex-agents/tmp_sketch.ino`
248. `scp /Users/trent/dev/codex-agents/tmp_sketch.ino arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino`
250. `scp /Users/trent/dev/codex-agents/brick_balancing_robot.py arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py`
252. `scp /Users/trent/dev/codex-agents/brick_index.html arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/assets/index.html`
253. `scp /Users/trent/dev/codex-agents/brick_app.js arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/assets/app.js`
254. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/python/main.py <<\"PY\" ... PY'`
255. `ssh arduino@ada.local 'arduino-app-cli app stop user:balancing_bot_app; sleep 2; arduino-app-cli app start user:balancing_bot_app'`
256. `curl -s http://ada.local:7000/status | head -c 240`
257. `curl -s 'http://ada.local:7000/set_motor_invert?left=-1&right=1' | head -c 200`
258. `curl -s 'http://ada.local:7000/set_encoder_invert?left=-1&right=-1' | head -c 200`
259. `cat > /Users/trent/dev/codex-agents/brick_index.html`
260. `cat > /Users/trent/dev/codex-agents/brick_app.js`
261. `cat > /Users/trent/dev/codex-agents/tmp_sketch.ino`
262. `scp /Users/trent/dev/codex-agents/brick_index.html arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/assets/index.html`
263. `scp /Users/trent/dev/codex-agents/brick_app.js arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/assets/app.js`
264. `scp /Users/trent/dev/codex-agents/brick_balancing_robot.py arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py`
266. `scp /Users/trent/dev/codex-agents/tmp_sketch.ino arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app/sketch/sketch.ino`
268. `ssh arduino@ada.local 'cat > /home/arduino/ArduinoApps/balancing_bot_app/python/main.py <<\"PY\" ... PY'`
269. `ssh arduino@ada.local 'arduino-app-cli app stop user:balancing_bot_app; sleep 2; arduino-app-cli app start user:balancing_bot_app'`
270. `curl -s http://ada.local:7000/status | head -c 260`
271. `curl -s 'http://ada.local:7000/motor_test?left=120&right=0&duration_ms=500' | head -c 200`
272. `curl -s 'http://ada.local:7000/stop_motor_test' | head -c 200`
273. (removed: tar backup commands; backups now managed by git)

### Milestone 9: Bridge integration (MPU ↔ MCU)
- Switched MCU sketch to Arduino_RouterBridge RPC, with Bridge-provided handlers for PID/setpoint/mode/IMU/kick and Bridge.notify telemetry.
- Updated Python brick to register a Bridge provider (`record_telemetry`) and to send commands to the MCU when in real mode.
- Verified the app still runs and that switching to real mode yields bridge-fed telemetry.

Next up:
- Confirm dashboard updates properly when toggling real/sim and updating PID while Bridge is active.
- Decide on actual IMU/motor/encoder wiring and replace placeholder IMU read with real sensor integration.

### Milestone 10: Bridge handshake
- Added a Bridge handshake (`get_status`) on the MCU sketch and a ping in the Python brick before sending commands.
- Updated the MCU sketch to include the Bridge RPC handler and re-uploaded to both app + brick sketches.
- Re-started the app and verified real mode still toggles with Bridge enabled.

Next up:
- Verify dashboard PID updates and kick commands propagate over Bridge.
- Replace placeholder IMU read with MPU-6050/9250 integration and real sensor fusion.

### Milestone 11: Safety guard for kick
- Disabled kick/face-plant behavior in real mode; kick remains simulation-only.
- Updated both the MCU sketch and Python brick to ignore kick when in real hardware mode.

Next up:
- Verify dashboard PID updates propagate over Bridge in real mode.
- Replace placeholder IMU read with MPU-6050/9250 integration and real sensor fusion.

### Milestone 12: Bridge command verification
- Verified PID updates propagate in real mode over Bridge.
- Verified kick is ignored in real mode and still functions in simulation mode.

Next up:
- Replace placeholder IMU read with MPU-6050/9250 integration and real sensor fusion.

### Milestone 13: IMU integration (no extra libraries)
- Added raw I2C reads for MPU-6050/MPU-9250 using Wire, a simple complementary filter, and a fallback to simulation if IMU isn’t detected.
- Added a bridge status string that reports sim/real + IMU readiness.
- Rebuilt and restarted the app; real mode remains functional even without the physical IMU attached.

Next up:
- Confirm axis mapping for your physical IMU orientation.
- Wire the actual IMU and validate angle stability.

### Milestone 14: Axis mapping controls
- Added axis selection (pitch/roll) end-to-end: WebUI, Python brick config, Bridge calls, and MCU sketch mapping.
- Verified axis mode updates via HTTP and appears in /status config.

Next up:
- Wire the IMU and validate axis mapping against physical orientation.

### Milestone 15: Axis sign + motor/encoder direction controls
- Added axis sign inversion to the MCU filter, Bridge RPC, Python brick config, and WebUI.
- Added motor and encoder direction inversion controls (L/R) with Bridge RPC + HTTP endpoints.
- Verified config updates via /status and HTTP setters.

Next up:
- Wire motors/encoders and validate direction settings against your hardware.

### Milestone 16: Motor Shield Rev3 pin mapping
- Updated the MCU sketch to use Arduino Motor Shield Rev3 (L298P) pin mappings (DIR/PWM/BRAKE) and selected encoder pins.
- Switched encoder handling to quadrature (A/B) with direction.
- Rebuilt and restarted the app with the new pin map.

Next up:
- Physically wire the shield + encoders and validate motor/encoder direction settings.

### Milestone 17: Motor test controls
- Added a UI motor test panel (left/right forward/reverse + stop) with Bridge-backed motor test commands.
- Exposed HTTP endpoints for motor_test and stop_motor_test.
- Updated the MCU sketch to honor temporary motor test overrides.

Next up:
- Use the Motor Test buttons to confirm wiring and direction on hardware.

### Milestone 18: Backups refreshed (Dec 27, 2025)
- Created a fresh on-board archive: (historical; tar archives no longer used; git is the backup source of truth).
- Copied the archive to the host workspace for safekeeping.
  (Historical note: tar archives are no longer used; git is the backup source of truth.)
- Latest archive (Dec 27, 2025): no longer applicable (git-only backups).

### Milestone 19: Brick docs + examples (Dec 27, 2025)
- Added full Brick README, brick_config, and examples in the app-local brick package.
- Added Brick README + API docs into the App Lab assets catalog so the Brick can appear with proper docs.

Next up:
- Restart the App Lab daemon and verify the Balancing Robot Brick shows up in the Brick gallery.
- Connect IMU/motors/encoders and validate real mode end-to-end.

### Milestone 20: Brick README expanded for tabs (Dec 27, 2025)
- Expanded Brick README with a full Overview section and a richer "Code example and usage" section.
- README now clearly populates Overview and Usage Examples tabs in the Brick gallery.

Next up:
- Refresh the Brick view in App Lab to confirm the new Usage Examples tab content.
- Optionally add screenshots or a mini HTML guide in the README.

### Milestone 21: Usage Examples tab wired (Dec 27, 2025)
- Discovered Usage Examples tab is populated from code examples under `assets/0.6.2/examples/arduino/<brick>/`.
- Added three example scripts for the balancing_robot brick, so `arduino-app-cli brick details` now lists code_examples.

Next up:
- Refresh the Brick view in App Lab to confirm Usage Examples now shows the scripts.

### Milestone 22: Usage Examples descriptions (Dec 27, 2025)
- Added a short descriptive paragraph at the top of each Usage Example script to explain its purpose and how it differs.

Next up:
- Refresh App Lab and verify Usage Examples show the descriptions.

### Milestone 23: Usage Examples metadata (Dec 27, 2025)
- Updated Usage Example scripts with EXAMPLE_NAME / EXAMPLE_REQUIRES headers (as used by built-in bricks) so App Lab can list them properly.

Next up:
- Refresh App Lab and verify all three examples appear with descriptions.

### Milestone 24: Usage Examples header comments (Dec 27, 2025)
- Added short header comments at the top of each example file so the explanation appears inside the code block.

Next up:
- Refresh App Lab and confirm the comments appear above each example.

### Milestone 25: Local repo + archives synced (Dec 27, 2025)
- Created a fresh on-board archive including ArduinoApps and balancing_robot docs/examples/assets.
- Copied the new archive to the host workspace for safekeeping.
- Ready to commit local log updates.

### Milestone 26: Backup policy change (Dec 27, 2025)
- Stopped using tar archives for backups.
- Git repo is now the source of truth for backups; tar files removed and ignored.

### Milestone 27: App metadata + README refreshed (Dec 27, 2025)
- Updated balancing_bot_app app.yaml with a clear name, emoji icon, and description.
- Expanded the app README with quick start, modes, hardware notes, and file map.

Next up:
- Refresh App Lab and verify the app card shows the new icon and description.

### Milestone 28: App description expanded (Dec 27, 2025)
- Expanded balancing_bot_app description to highlight PID tuning, IMU alignment, motor tests, and simulation-first workflow.

### Milestone 29: App description doubled (Dec 27, 2025)
- Expanded balancing_bot_app description to roughly double length for richer app card detail.

### Milestone 30: App description refined (Dec 27, 2025)
- Shortened the trailing description and added WiFi dashboard mention.

### Milestone 31: App description spiced up (Dec 27, 2025)
- Added a more lively, friendly tone to the app description.

### Milestone 32: Removed unused apps (Dec 27, 2025)
- Confirmed they no longer appear in App Lab app list.

### Milestone 33: Documentation cleanup (Dec 27, 2025)
- Removed remaining references to deleted apps from the project README.
- Updated local helper script paths to only target the active balancing_bot_app brick.

### Milestone 34: Workspace cleanup (Dec 27, 2025)
- Removed local temporary files (brick_app.js, brick_index.html, brick_balancing_robot.py, tmp_app.js, tmp_sketch.ino, update_axis_sign.py).

### Milestone 35: Kick/face-plant persistence fix (Dec 27, 2025)
- Made the simulation kick persist by storing sim angle/rate state and applying it in the loop.
- Kick now updates sim state and pushes a telemetry update immediately.

### Milestone 36: Smooth kick wobble + UI overlay (Dec 27, 2025)
- Replaced the snap-to-angle kick with a damped wobble impulse so the kick eases out and recovers more slowly.
- Updated the wireframe overlay to animate a smooth kick wobble instead of a hard snap.
- Renamed the kick button label to “Kick.”

Next up:
- Restart the app and confirm the kick produces a smoother wobble in both waveform and wireframe.

### Milestone 37: PID loop rate control (Dec 27, 2025)
- Added a PID loop rate control in the dashboard and config.
- Default PID loop rate is now 50 Hz.
- Added HTTP/socket endpoint to update the PID loop rate from the UI.

Next up:
- Restart the app and confirm the PID rate control appears and applies.
