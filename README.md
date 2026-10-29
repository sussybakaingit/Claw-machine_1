# 3D Claw Machine Arcade Game

A complete, polished, playable 3D claw-machine arcade game built in **Godot 4.x (GDScript)** with real-time **webcam hand tracking** via an OpenCV + MediaPipe sidecar and seamless **mouse fallback**.

---

## Features

- **Stylized Premium 3D Arcade Look**: Glass-walled cabinet with metal/neon-trimmed frame, glowing marquee sign, PBR materials (metallic, roughness, clearcoat, neon emissions), realistic reflection probes, cozy ambient room lighting, ACES tonemapping, and glow/bloom.
- **Physics-Based Claw & Prizes**: Powered by Godot 4 Jolt 3D physics. Articulated 3-prong claw gantry, physics collision, authentic grip mechanics where prizes can realistically slip or be cradled.
- **Multiple Prize Types & Scoring**:
  - Spheres / Capsule Plushies: 10 points
  - Gift Cubes with Ribbons: 20 points
  - Golden Stars / Gem Crystals: 50 points
- **Interactive Chute Scoring**: Prizes only count when physically dropped into the collection chute Area3D. Triggers confetti particle bursts and animated 3D floating score text popups.
- **Webcam Hand Tracking (Sidecar)**:
  - UDP streaming from `hand_tracker/hand_tracker.py` using OpenCV and MediaPipe Hands.
  - Normalized hand coordinates, palm center, pinch distance, and fist closure metric.
  - Smooth hysteresis filtering and gesture cooldown to prevent double-triggering.
  - Live landmark skeleton preview canvas in the corner.
  - Interactive Calibration step (hand detection, corner reach, grab gesture test).
- **Instant Mouse Fallback**:
  - If Python, camera, or dependencies are not available, the game detects this automatically and enables full mouse control (Mouse cursor moves the claw, Left Click triggers the grab sequence).
- **Settings Menu (Controls & Graphics)**:
  - **Controls**: Movement sensitivity (0.25x - 3.0x), Claw speed (0.5x - 2.5x), Gesture threshold (0.2 - 0.8), Hand smoothing (0.0 - 0.95), Control Mode (Direct / Joystick / Mouse), and Presets (Beginner, Normal, Precision, Custom).
  - **Graphics**: Presets (Low, Medium, High, Ultra, Custom), Render Scale (50% - 150%), Window Mode (Windowed / Fullscreen), VSync, Framerate Cap (30 / 60 / 120 / Unlimited), MSAA (Disabled / 2x / 4x / 8x), SSAO, Glow, Show FPS counter, Webcam Preview toggle.
  - Live persistence to `user://settings.cfg`.
- **Game Loop & Timed Rounds**:
  - Selectable 30s or 60s round length on the Main Menu.
  - 3-2-1-GO! countdown sequence before start.
  - Dynamic HUD with digital clock, animated score counter, high score persistence to `user://save_data.cfg`, and tracking status badges.
  - Pause Menu (Esc or on-screen button) with resume, settings, and quit.
  - Victory Results Screen showing final score, prizes won, personal best, and Play Again button.

---

## Quick Start & Running

### 1. Run in Godot 4
Open the project folder in Godot 4 (or use Godot CLI / MCP) and run:
- **Main Scene**: `res://scenes/main_menu.tscn`

### 2. (Optional) Enable Webcam Hand Tracking
To play using real-time webcam hand tracking:

```bash
cd hand_tracker
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Godot automatically detects the virtual environment at `hand_tracker/.venv/bin/python` or the system `python3` and launches the tracker process upon starting the game.

*If you do not set up Python or don't have a webcam, the game automatically switches to Mouse Mode and is 100% playable out of the box!*

---

## Controls

| Action | Hand Tracking (Webcam) | Mouse Fallback |
| :--- | :--- | :--- |
| **Move Claw** | Hand position in camera frame (Direct) or Hand offset from center (Joystick) | Move mouse cursor over play area |
| **Grab Sequence** | Pinch (thumb & index together) OR close fist | Left Mouse Click |
| **Pause / Resume** | Pause button in top right | `Esc` key or Pause button |

---

## Project Structure

```
├── project.godot                     # Project configuration, autoloads, Jolt physics
├── scenes/
│   ├── main_menu.tscn                # Main menu with 3D cabinet background and round length selector
│   ├── game.tscn                     # Main game scene with 3D environment & camera sway
│   ├── claw_machine.tscn             # Complete 3D arcade cabinet, neon pillars, glass, chute
│   ├── claw.tscn                     # Gantry rails, motor carriage, cable, 3 articulated prongs
│   ├── prize.tscn                    # Physics RigidBody3D prizes (spheres, capsules, cubes, stars)
│   ├── hud.tscn                      # In-game HUD, digital timer, score, hand status, camera preview
│   ├── settings_menu.tscn            # Comprehensive controls and graphics settings tabs
│   ├── pause_menu.tscn               # In-game pause modal with settings integration
│   ├── results.tscn                  # End-of-round results summary and play again
│   └── calibration.tscn              # Hand tracking calibration sequence
├── scripts/
│   ├── game_manager.gd               # State machine autoload (MENU, CALIBRATION, COUNTDOWN, PLAYING, etc.)
│   ├── settings_manager.gd           # Settings persistence autoload (user://settings.cfg)
│   ├── hand_input.gd                 # UDP packet parsing, smoothing, gesture hysteresis, sidecar manager
│   ├── claw_controller.gd            # 3-axis claw motion and grab state machine
│   ├── claw_machine.gd               # Cabinet chute detection, particle emission, floating 3D text
│   ├── prize.gd                      # Prize physics tuning, material types, and score logic
│   ├── prize_spawner.gd              # Pool population and automatic top-up manager
│   ├── hud.gd                        # HUD UI management and countdown animation
│   ├── landmark_canvas.gd            # Custom drawing control for MediaPipe 21-point hand skeleton
│   ├── settings_menu.gd              # Settings UI bindings to SettingsManager
│   ├── pause_menu.gd                 # Pause menu actions
│   ├── results.gd                    # Results screen presentation
│   ├── calibration.gd                # Interactive calibration controller
│   ├── camera_sway.gd                # Subtle camera motion script
│   └── main_menu.gd                  # Main menu actions and duration selection
├── hand_tracker/
│   ├── hand_tracker.py               # Python sidecar (OpenCV + MediaPipe Hands -> UDP JSON)
│   ├── requirements.txt              # opencv-python, mediapipe
│   └── README.md                     # Hand tracker documentation
└── tasks/
    └── lessons.md                    # Project development lessons and standards
```

---

## Acceptance Verification

- [x] Click Play -> 3-2-1 countdown -> 30s or 60s round works, score updates, results screen shows
- [x] Claw is controlled by webcam hand tracking (pinch / fist gesture triggers grab)
- [x] Mouse fallback works automatically when no camera/dependencies
- [x] All 5 sensitivity options + 3 presets (Beginner, Normal, Precision) work and persist
- [x] Graphics settings change visuals/performance immediately and persist to `user://settings.cfg`
- [x] Prizes are physics-based RigidBody3Ds with Jolt physics; points awarded on valid chute drops
- [x] Visuals are polished 3D with neon lighting, glass transparency/refraction, glow, and confetti particles
- [x] Zero console errors during full playthrough
