# Lessons and Best Practices

## Godot 4.x & GDScript
- Always use typed GDScript (`var score: int = 0`, `func _ready() -> void:`) for clean code and editor warnings avoidance.
- Ensure all Resource and Scene paths match exact case (e.g. `res://scenes/main_menu.tscn`).
- When creating UI, use Anchor Presets and theme overrides rather than hardcoded positions so responsive scaling works at all resolutions.
- For Jolt 3D physics: keep RigidBody3D mass and shape dimensions reasonable (avoid zero scale, set continuous collision detection where necessary for fast moving pieces).
- For Hand Tracking UDP: use PacketPeerUDP with non-blocking polling inside `_process` or `_physics_process`. Gracefully catch parse errors or missing packets without throwing runtime exceptions.
- Provide clear fallbacks for hardware/system dependencies (webcam, Python sidecar) so the game is always 100% playable and testable via mouse/keyboard.
- State Machine Transitions: Always transition via `change_state()` and never mutate state variables directly from caller scenes. Ensure initial state entering a new scene always cleanly triggers necessary setup and signals.
- Completion Signals & Polling: In multi-step or countdown controllers, always disable `_process` (`set_process(false)`) or latch the completion boolean before emitting completion signals to avoid repeating the event 60 times a second.
- 3D Claw Grabbing Mechanics: Combine physical articulated prongs with an internal Grip Area3D / physical cradle hold so RigidBodies are reliably lifted and transported across the cabinet before being dropped by gravity.
