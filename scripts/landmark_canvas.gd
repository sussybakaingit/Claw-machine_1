extends Control
class_name LandmarkCanvas

# MediaPipe connections: pairs of landmark indices
const CONNECTIONS = [
	[0, 1], [1, 2], [2, 3], [3, 4],       # Thumb
	[0, 5], [5, 6], [6, 7], [7, 8],       # Index
	[5, 9], [9, 10], [10, 11], [11, 12],  # Middle
	[9, 13], [13, 14], [14, 15], [15, 16],# Ring
	[13, 17], [17, 18], [18, 19], [19, 20],# Pinky
	[0, 17]                                # Palm base
]

func _draw() -> void:
	# Draw dark background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.12, 0.85))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.8, 1.0, 0.5), false, 1.5)
	
	if not HandInput.is_tracking or not HandInput.landmarks_dict.has("landmarks"):
		draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.15, size.y * 0.5), "No Hand Tracked", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.7, 0.7, 0.7, 0.7))
		return
	
	var pts: Array = HandInput.landmarks_dict.get("landmarks", [])
	if pts.size() < 21:
		return
	
	var screen_pts: Array[Vector2] = []
	for p in pts:
		var x: float = (p.get("x", 0.5) as float) * size.x
		var y: float = (p.get("y", 0.5) as float) * size.y
		screen_pts.append(Vector2(x, y))
	
	# Draw connections
	for conn in CONNECTIONS:
		var idx1: int = conn[0]
		var idx2: int = conn[1]
		if idx1 < screen_pts.size() and idx2 < screen_pts.size():
			draw_line(screen_pts[idx1], screen_pts[idx2], Color(0.0, 0.9, 1.0, 0.8), 2.0)
	
	# Draw landmark dots
	for i in range(screen_pts.size()):
		var pt: Vector2 = screen_pts[i]
		var dot_color: Color = Color(1.0, 0.3, 0.5) if (i == 4 or i == 8) else Color(0.2, 1.0, 0.4)
		var rad: float = 4.0 if (i == 4 or i == 8) else 2.5
		draw_circle(pt, rad, dot_color)
