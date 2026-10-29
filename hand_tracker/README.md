# Hand Tracker for 3D Claw Machine

This module tracks hand gestures via webcam and streams real-time landmark coordinates and gesture metrics (pinch and fist) over local UDP to Godot.

## Quick Setup

1. (Optional but recommended) Create a virtual environment:
```bash
python3 -m venv .venv
source .venv/bin/activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Test standalone tracker:
```bash
python3 hand_tracker.py --debug
```

## Godot Integration
- Godot automatically launches `hand_tracker.py` on game startup.
- If Python or MediaPipe is not installed, Godot gracefully displays an in-game helper panel and switches to **Mouse Fallback Mode** (Mouse moves claw, Left Click grabs).
