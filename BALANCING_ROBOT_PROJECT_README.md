# Balancing Robot - Arduino Uno Q Project Documentation

**Project Created:** December 26, 2024
**Development Time:** 5+ hours
**Status:** ✅ Functional, in development, **LIVE ON BOARD NOW**
**Board Hostname:** `ada.local`
**Backup policy:** This project now uses the local git repo as the backup source of truth. No tar archives are created or used.

---

## 🚀 QUICK START - Connect to Your Board Right Now

### The Project Is LIVE and Ready to Continue!

**The working project files are on the Arduino Uno Q board RIGHT NOW at:**
```
/home/arduino/ArduinoApps/balancing_bot_app/
```

**To SSH into the board from your Mac:**
```bash
ssh arduino@ada.local
```

Once connected:
```bash
# Navigate to the live project
cd /home/arduino/ArduinoApps/balancing_bot_app

# Check if the app is running
arduino-app-cli app list

# View the web dashboard
# Open browser to: http://ada.local:7000
```

**Backups are handled by git.** The live, working project is already on the board and ready for you to continue developing.

---

## 📦 About the Backup Archive

**Archive Name:** (not used)
**Location:** (not used)
**Size:** n/a
**Purpose:** Git is the backup; the real project is live on the board.

### When to Use the Archive

**You DON'T need the archive if:**
- ✅ You want to continue developing (work directly on the board)
- ✅ You want to test the app (it's already running)
- ✅ You want to make changes (edit files in `/home/arduino/ArduinoApps/`)

**You NEED a backup if:**
- ⚠️ Files get accidentally deleted
- ⚠️ You want to restore to a known good state
- ⚠️ You want to copy the project to another machine
- ⚠️ You want to version control or archive for posterity

### How to Restore from Git (If Needed)

**On your Mac:**
```bash
# Commit locally and push to GitHub (once you add a remote)
git status
git add .
git commit -m "Checkpoint"
git push
```

**On the Arduino Uno Q board:**
```bash
# Pull updates after you add a remote
git pull
```

---

## Table of Contents
1. [Project Origin Story](#project-origin-story)
2. [Project Overview](#project-overview)
3. [Architecture & File Structure](#architecture--file-structure)
4. [Development Environment Setup](#development-environment-setup)
5. [How to SSH into the Arduino Uno Q](#how-to-ssh-into-the-arduino-uno-q)
6. [How to Continue Development](#how-to-continue-development)
7. [Running the Application](#running-the-application)
8. [Technical Details](#technical-details)
9. [Next Steps](#next-steps)

---

## Project Origin Story

### How This Project Was Created

This project was developed **directly on the Arduino Uno Q board** during a 5-hour session using **Codex** (a CLI-based AI assistant), SSH'd in from a Mac host machine.

**The Development Session:**
- **Date:** December 26, 2024
- **Tool Used:** Codex CLI AI assistant (running on host Mac)
- **Connection:** SSH from Mac → Arduino Uno Q
- **Working Directory:** `/home/arduino/ArduinoApps/`
- **Reference Material:** https://deepwiki.com/arduino/app-bricks-py/3-brick-development-guide
- **Arduino.cc Datasheets:** Used for Arduino Uno Q specifications

**Why Files Are On The Board:**
When working via SSH directly on the Arduino Uno Q, all file edits happen **on the board's eMMC storage**, NOT on the Mac. This is different from the typical App Lab IDE workflow where projects start on the Mac and get deployed to the board.

**What Happened to Codex:**
After 5 hours of development, Codex "lost its mind" (likely context overflow or session termination), prompting the need to recover and document this project.

---

## Project Overview

### What Was Built

A complete **Balancing Robot** application for Arduino Uno Q consisting of:

1. **Custom App Lab Brick** (`balancing_robot`)
   - Reusable robotics component
   - PID controller with live tuning
   - IMU integration (MPU-6050, MPU-9250 support)
   - Dual-mode operation (simulation + real hardware)

2. **Web Dashboard Application** (`balancing_bot_app`)
   - Real-time telemetry visualization
   - Live PID tuning interface
   - 2D angle history chart
   - 3D wireframe robot visualization
   - Socket.IO + HTTP polling hybrid architecture

### Key Features

✅ **PID Controller** - Proportional-Integral-Derivative control with live tuning (P=12.0, I=0.0, D=0.4)
✅ **IMU Support** - MPU-6050 and MPU-9250 motion sensors
✅ **Simulation Mode** - Physics-based robot simulation for testing without hardware
✅ **Real Hardware Mode** - Ready for actual motor/IMU integration
✅ **Web Dashboard** - Professional HTML5/Canvas-based control interface
✅ **Real-time Telemetry** - Socket.IO streaming at 15Hz update rate
✅ **Motor Control** - PWM output simulation for dual motors
✅ **Encoder Tracking** - Simulated wheel encoder feedback
✅ **Disturbance Testing** - "Kick" function to test PID response

### Code Statistics

- **Python Backend:** 195 lines (brick implementation)
- **Web Frontend:** 464 lines (HTML + JavaScript + CSS)
- **Total Custom Code:** ~670 lines
- **Files:** Project spans one app plus Brick catalog docs/examples

---

## Architecture & File Structure

### Arduino Uno Q Storage Layout

The Arduino Uno Q has 16GB eMMC storage partitioned as:

```
/dev/mmcblk0p68  (9.8GB)  →  /           (Debian Linux OS)
/dev/mmcblk0p69  (3.6GB)  →  /home/arduino  (User apps & data)
/dev/mmcblk0p67  (488MB)  →  /boot/efi     (Boot partition)
```

**Your projects live in:** `/home/arduino/ArduinoApps/`

### Project Directory Structure (on the board)

```
/home/arduino/ArduinoApps/
│
└── balancing_bot_app/                  # Main Application (uses the brick)
    ├── app.yaml                        # App config (uses arduino:web_ui + arduino:balancing_robot)
    ├── README.md
    ├── .gitignore
    ├── sketch/
    │   ├── sketch.ino                  # Arduino sketch
    │   └── sketch.yaml
    ├── python/
    │   ├── main.py                     # App entry point
    │   └── arduino/
    │       └── app_bricks/
    │           └── balancing_robot/
    │               └── __init__.py     # FULL IMPLEMENTATION ⭐
    │                                   # (PID, IMU, simulation, WebUI integration)
    └── assets/                         # Web Dashboard
        ├── index.html                  # Dashboard UI
        ├── app.js                      # Interactive controls
        ├── style.css                   # Styling
        └── libs/
            └── socket.io.min.js        # Socket.IO library
```

Brick catalog docs/examples (used by App Lab UI):
- `/home/arduino/.local/share/arduino-app-cli/assets/0.6.2/docs/arduino/balancing_robot/README.md`
- `/home/arduino/.local/share/arduino-app-cli/assets/0.6.2/api-docs/arduino/app_bricks/balancing_robot/API.md`
- `/home/arduino/.local/share/arduino-app-cli/assets/0.6.2/examples/arduino/balancing_robot/`

### Repo Snapshot Layout (this repo)

The minimal custom files from the Uno Q are mirrored here for version control:

```
repo_root/
└── unoq/
    ├── ArduinoApps/
    │   └── balancing_bot_app/              # Full custom app (MPU + MCU + UI)
    └── arduino-app-cli-assets/0.6.2/
        ├── docs/arduino/balancing_robot/README.md
        ├── api-docs/arduino/app_bricks/balancing_robot/API.md
        ├── examples/arduino/balancing_robot/
        └── bricks-list.append.yaml         # Patch snippet to add brick to bricks-list.yaml
```

### The Dual-Environment Architecture

**Understanding App Lab Development:**

```
┌─────────────────────────────────────┐
│  HOST MAC                           │
│  ┌─────────────────────────────┐   │
│  │ Arduino App Lab IDE         │   │
│  │ - Visual editor             │   │
│  │ - Project files (local)     │   │
│  │ - Press "Launch" to deploy  │   │
│  └─────────────┬───────────────┘   │
└────────────────┼─────────────────────┘
                 │
                 │ USB-C or Network (Port 8800)
                 │
┌────────────────▼─────────────────────┐
│  ARDUINO UNO Q BOARD                │
│  ┌─────────────────────────────┐   │
│  │ arduino-app-cli daemon      │   │
│  │ (always running on :8800)   │   │
│  └─────────────┬───────────────┘   │
│                │                    │
│                ▼                    │
│  /home/arduino/ArduinoApps/         │
│  - Apps deployed here               │
│  - Run directly on board            │
│  - Persist after disconnect         │
└─────────────────────────────────────┘
```

**Two Development Modes:**

1. **App Lab IDE (Mac) → Deploy to Board**
   - Edit on Mac in visual IDE
   - Press "Launch"
   - IDE compiles & deploys to board
   - Files sync: Mac → Board

2. **Direct SSH Development (What Codex Did)** ⭐
   - SSH directly into board from Mac
   - Edit files on board with CLI tools
   - Files stay on board only
   - **Not automatically synced back to Mac**

---

## Development Environment Setup

### Prerequisites

- **Mac** (host machine) with:
  - Arduino App Lab IDE installed
  - SSH client (built into macOS Terminal)
  - Network connectivity to Arduino Uno Q

- **Arduino Uno Q** with:
  - IP address on same network as Mac
  - SSH server enabled (default)
  - Username: `arduino`
  - Password: (set during initial setup)

### Current Running Services

On the Arduino Uno Q, these services are running:

```bash
arduino-app-cli daemon --port 8800     # App Lab CLI daemon
/usr/lib/android-sdk/platform-tools/adbd  # Android Debug Bridge
```

**Currently Running App:**
```
user:balancing_bot_app    balancing_bot_app    running
```

Access the dashboard at: `http://<uno-q-ip>:7000`

---

## How to SSH into the Arduino Uno Q

### Your Board's Connection Info

**Hostname:** `ada.local` (mDNS/Bonjour name)
**Username:** `arduino`
**Board Name:** Arduino Uno Q

### Quick Connection

From your Mac's Terminal:

```bash
ssh arduino@ada.local
```

You'll be prompted for the Arduino user password.

**Alternative: Use IP Address**

If `ada.local` doesn't resolve, find the IP address:

**Method A: Check from the board itself** (if you have monitor/keyboard connected):
```bash
hostname -I
```

**Method B: From your Mac, scan the network:**
```bash
# Install nmap if needed: brew install nmap
nmap -sn 192.168.1.0/24 | grep -B 2 "arduino"
```

**Method C: Check your router's DHCP client list**

Then connect using IP:
```bash
ssh arduino@192.168.1.xxx
```

### Navigate to Projects

Once connected:
```bash
cd /home/arduino/ArduinoApps
ls -la
```

You should see:
- `balancing_bot_app/` ← **Your main project**

### Recommended: Set Up SSH Keys (No Password Required)

**On your Mac:**
```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy key to Arduino Uno Q
ssh-copy-id arduino@ada.local
```

Now you can SSH without entering password each time!

---

## How to Continue Development

### Option 1: Continue via SSH (Recommended for This Project)

Since this project was built directly on the board, continuing via SSH maintains consistency:

**1. SSH into the board:**
```bash
ssh arduino@ada.local
cd /home/arduino/ArduinoApps/balancing_bot_app
```

**2. Edit files using CLI editors:**
```bash
# Nano (beginner-friendly)
nano python/arduino/app_bricks/balancing_robot/__init__.py

# Vim (advanced)
vim assets/app.js

# Or use Claude Code CLI (recommended!)
claude
```

**3. Test changes:**
```bash
# Stop the app
arduino-app-cli app stop user:balancing_bot_app

# Start the app
arduino-app-cli app start user:balancing_bot_app

# View logs
arduino-app-cli app logs user:balancing_bot_app
```

**4. Access the dashboard:**
Open browser: `http://ada.local:7000`

### Option 2: Sync to Mac App Lab IDE

If you want to use the visual App Lab IDE:

**1. Copy project from board to Mac:**
```bash
# From your Mac terminal
scp -r arduino@ada.local:/home/arduino/ArduinoApps/balancing_bot_app ~/Documents/ArduinoApps/
```

**2. Open in App Lab IDE:**
- Launch Arduino App Lab
- File → Open Project
- Navigate to `~/Documents/ArduinoApps/balancing_bot_app`

**3. Make changes in IDE**

**4. Deploy back to board:**
- Press "Launch" button in App Lab IDE
- IDE will compile and deploy to board

**⚠️ WARNING:** After syncing to Mac, you'll have TWO copies:
- One on Mac (editable in App Lab IDE)
- One on board (what's actually running)

Keep them in sync manually or choose one development environment.

### Option 3: Hybrid Approach

- **Quick edits:** SSH into board, edit directly
- **Major refactoring:** Sync to Mac, use App Lab IDE, redeploy
- **Always backup before switching environments!**

---

## Running the Application

### Check App Status

```bash
arduino-app-cli app list
```

Look for:
```
user:balancing_bot_app    balancing_bot_app    running
```

### Start the App

```bash
arduino-app-cli app start user:balancing_bot_app
```

### Stop the App

```bash
arduino-app-cli app stop user:balancing_bot_app
```

### View Logs

```bash
# Real-time logs
arduino-app-cli app logs user:balancing_bot_app

# Python logs
arduino-app-cli app logs user:balancing_bot_app --follow
```

### Access the Dashboard

**Web Dashboard URL:**
```
http://ada.local:7000
```

**Alternative (using IP address):**
If `ada.local` doesn't work, find the IP and use:
```
http://192.168.1.xxx:7000
```

**Dashboard Features:**
- **PID Tuning Panel:** Adjust P, I, D gains in real-time
- **Setpoint Control:** Change target balance angle
- **IMU Selection:** Switch between MPU-6050 and MPU-9250
- **Mode Toggle:** Simulation vs Real hardware
- **Kick Button:** Apply disturbance to test PID response
- **Telemetry Display:** Real-time angle, gyro, accel, motor PWM, encoders
- **Angle History Chart:** Scrolling graph of tilt angle over time
- **3D Wireframe View:** Visual representation of robot orientation

---

## Technical Details

### Python Backend Implementation

**File:** `balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py`

**Class:** `BalancingRobot`

**Constructor Parameters:**
```python
BalancingRobot(
    imu_model: str = "mpu6050",    # IMU sensor model
    simulated: bool = True,         # Run in simulation mode
    update_hz: int = 15             # Telemetry update rate
)
```

**Key Methods:**
- `attach_webui(ui)` - Connect to WebUI brick for Socket.IO events
- `start()` - Start background telemetry/control thread
- `stop()` - Stop background thread
- `get_state()` - Get current config + telemetry snapshot
- `http_set_pid(p, i, d)` - HTTP endpoint for PID tuning
- `http_set_setpoint(setpoint)` - HTTP endpoint for setpoint
- `http_set_mode(mode)` - Toggle sim/real mode
- `http_kick(angle)` - Apply disturbance

**PID Controller:**
```python
# Default gains
P = 12.0
I = 0.0
D = 0.4

# Control loop (runs at update_hz)
error = setpoint - angle
integral += error * dt
derivative = (error - last_error) / dt
output = P * error + I * integral + D * derivative
```

**Simulation Physics:**
```python
# Simple spring-damper model
rate += (-0.25 * angle - 0.03 * rate + noise)
angle += rate * dt
```

### Web Frontend Implementation

**Technologies:**
- **HTML5 Canvas** - Charts and 3D visualization
- **Socket.IO** - Real-time bidirectional communication
- **Vanilla JavaScript** - No framework dependencies
- **HTTP Polling Fallback** - Works without Socket.IO

**Socket.IO Events:**

*Client → Server:*
- `get_initial_state` - Request current config
- `set_pid` - Update PID gains
- `set_setpoint` - Update balance target
- `set_imu_model` - Change IMU sensor
- `set_mode` - Toggle sim/real
- `kick` - Apply disturbance

*Server → Client:*
- `config` - Configuration update
- `telemetry` - Real-time sensor data (15Hz)

**HTTP Endpoints (polling fallback):**
- `GET /status` - Get full state
- `GET /set_pid?p=12&i=0&d=0.4` - Update PID
- `GET /set_setpoint?setpoint=0` - Update setpoint
- `GET /set_imu_model?imu_model=mpu6050` - Change IMU
- `GET /set_mode?mode=sim` - Toggle mode
- `GET /kick?angle=30` - Apply kick

### Brick Configuration

**File:** `balancing_bot_app/python/arduino/app_bricks/balancing_robot/brick_config.yaml`

```yaml
id: arduino:balancing_robot
name: Balancing Robot
category: robotics
description: >
  Balancing robot brick with dual motors + IMU + PID tuning dashboard.
variables:
  - name: IMU_MODEL
    description: Selected IMU model (e.g., mpu6050, mpu9250)
    default_value: mpu6050
```

### App Configuration

**File:** `balancing_bot_app/app.yaml`

```yaml
name: balancing_bot_app
description: "Balancing robot app"
icon:
ports: [7000]

bricks:
  - arduino:web_ui            # Provides WebUI.expose_api(), Socket.IO
  - arduino:balancing_robot   # Your custom brick
```

---

## Next Steps

### Immediate Tasks

1. **Backup Verification**
   - Download backups: use git (no tar archives)
   - Store in safe location

2. **Test Current Implementation**
   - Access dashboard: `http://ada.local:7000`
   - Verify PID tuning works
   - Test kick disturbance
   - Observe simulation behavior

3. **Document Mac-Side Project**
   - Primary source of truth is this git repo
   - Remote origin: `https://github.com/ripred/unoq-balancer-brick-bot` (public)
   - Running app + brick assets live on the Uno Q (accessible via `ssh arduino@ada.local`)
     - App: `/home/arduino/ArduinoApps/balancing_bot_app`
     - Brick docs/examples/assets: `/home/arduino/.local/share/arduino-app-cli/assets/0.6.2/`
   - App Lab IDE on macOS may show cached copies; refresh/restart if it looks stale

### Hardware Integration (Next Phase)

To connect real hardware:

1. **IMU Integration**
   - Wire MPU-6050 or MPU-9250 to I2C pins
   - Install IMU library for Arduino sketch
   - Modify sketch to read IMU data
   - Send data to Python via serial/RPC

2. **Motor Driver Integration**
   - Connect dual motor driver (L298N, TB6612, etc.)
   - Wire to PWM-capable pins
   - Implement motor control in sketch
   - Receive commands from Python

3. **Encoder Integration**
   - Wire rotary encoders to interrupt pins
   - Count encoder ticks in sketch
   - Send position data to Python

4. **Update Python Brick**
   - Replace simulation with real sensor reads
   - Implement actual motor commands
   - Handle serial/RPC communication

### Feature Enhancements

- **Auto-tuning:** Implement Ziegler-Nichols or similar PID auto-tuning
- **Data Logging:** Save telemetry to SQLite or CSV
- **Mobile UI:** Responsive design for phone/tablet
- **Video Overlay:** Camera feed with angle overlay
- **Multiple Robots:** Support fleet of balancing robots
- **Machine Learning:** Train ML model to optimize PID gains

### Code Quality Improvements

- **Unit Tests:** Add pytest tests for PID controller
- **Type Hints:** Complete type annotations
- **Documentation:** Add docstrings to all methods
- **Error Handling:** Robust error recovery
- **Configuration:** Move hardcoded values to config file

---

## Useful Commands Reference

### Arduino App CLI Commands

```bash
# List all apps
arduino-app-cli app list

# Start/stop apps
arduino-app-cli app start user:balancing_bot_app
arduino-app-cli app stop user:balancing_bot_app

# View logs
arduino-app-cli app logs user:balancing_bot_app
arduino-app-cli app logs user:balancing_bot_app --follow

# App info
arduino-app-cli app info user:balancing_bot_app

# Monitor Arduino serial
arduino-app-cli monitor

# System info
arduino-app-cli system info
```

### File Management

```bash
# Navigate to projects
cd /home/arduino/ArduinoApps

# List projects
ls -lah

# Create backup
git commit -m "Checkpoint"

# Check disk usage
df -h
du -sh ArduinoApps/*
```

### Network & Connectivity

```bash
# Check IP address
hostname -I
ip addr show

# Check if App Lab daemon is running
ps aux | grep arduino-app-cli
netstat -tuln | grep 8800

# Test web dashboard
curl http://localhost:7000/status
```

---

## Troubleshooting

### Dashboard Won't Load

**Check app is running:**
```bash
arduino-app-cli app list
# Should show "running" status
```

**Check port 7000 is open:**
```bash
netstat -tuln | grep 7000
```

**Restart app:**
```bash
arduino-app-cli app stop user:balancing_bot_app
arduino-app-cli app start user:balancing_bot_app
```

### Changes Not Showing Up

**If editing via SSH:**
- Stop and restart the app to reload Python code
- Frontend changes (HTML/JS/CSS) may need hard refresh (Cmd+Shift+R)

**If deploying from Mac:**
- Make sure App Lab IDE shows successful deployment
- Check logs for errors

### Socket.IO Not Connecting

Dashboard will automatically fall back to HTTP polling. Check browser console:
- If you see "socket.io not loaded, using polling" - polling mode active
- If you see "Connected" - Socket.IO working
- If you see "Disconnected, polling" - temporary network issue

### "Permission Denied" Errors

```bash
# Check file ownership
ls -la /home/arduino/ArduinoApps/balancing_bot_app/

# Fix if needed
sudo chown -R arduino:arduino /home/arduino/ArduinoApps/
```

---

## Additional Resources

### Documentation Links

- **Arduino App Lab Official Docs:** https://docs.arduino.cc/software/app-lab
- **App Lab Getting Started:** https://docs.arduino.cc/software/app-lab/tutorials/getting-started
- **Brick Development Guide:** https://deepwiki.com/arduino/app-bricks-py/3-brick-development-guide
- **Arduino Uno Q Product Page:** https://www.arduino.cc/product-uno-q
- **App Lab GitHub:** https://github.com/arduino/arduino-app-lab

### Community & Support

- **Arduino Forum:** https://forum.arduino.cc/
- **Arduino Discord:** https://discord.gg/arduino
- **Arduino UNO Q Documentation:** https://docs.arduino.cc/hardware/uno-q

---

## Project Metadata

**Backup Information:**
- **Filename:** (not used; git-only backups)
- **Location:** `/home/arduino/`
- **Size:** 23 KB (compressed)
- **Files:** 48 files
- **Created:** December 26, 2024 11:15:02 UTC

**Development Tools:**
- **Original:** Codex CLI (5 hour session)
- **Recovery:** Claude Code CLI
- **Platform:** Arduino Uno Q (16GB eMMC)
- **OS:** Debian Linux (custom Arduino distribution)

**Contact & Recovery:**
If you need to recover this project again, look for:
1. This README: `/home/arduino/BALANCING_ROBOT_PROJECT_README.md`
2. Backup archive: `/home/arduino/arduino_projects_backup_*.tar.gz`
3. Live project: `/home/arduino/ArduinoApps/balancing_bot_app/`

---

## License & Attribution

This project was created as a custom Arduino App Lab application. When sharing or distributing:

- Arduino App Lab is Open Source (GPL 3.0)
- Custom code (this project) can be licensed as you choose
- Include attribution to Arduino platform
- Reference any libraries/bricks used

---

**Document Version:** 1.0
**Last Updated:** December 26, 2024
**Maintained By:** Arduino user (via Claude Code CLI)

---

*Happy building! 🤖*
