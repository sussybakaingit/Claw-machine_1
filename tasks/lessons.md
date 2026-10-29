# Lessons and Best Practices

## Godot 4.x & GDScript
- Always use typed GDScript (`var score: int = 0`, `func _ready() -> void:`) for clean code and editor warnings avoidance.
- Ensure all Resource and Scene paths match exact case (e.g. `res://scenes/main_menu.tscn`).
- When creating UI, use Anchor Presets and theme overrides rather than hardcoded positions so responsive scaling works at all resolutions.
- For Jolt 3D physics: keep RigidBody3D mass and shape dimensions reasonable (avoid zero scale, set continuous collision detection where necessary for fast moving pieces).
- For Hand Tracking UDP: use PacketPeerUDP with non-blocking polling inside `_process` or `_physics_process`. Gracefully catch parse errors or missing packets without throwing runtime exceptions.
- Provide clear fallbacks for hardware/system dependencies (webcam, Python sidecar) so the game is always 100% playable and testable via mouse/keyboard.
