extends Camera3D
class_name CameraController

signal camera_changed(view_name: String)

enum CameraView {
	FRONT,
	SIDE_LEFT,
	TOP_DOWN,
	ISOMETRIC,
	CLOSE_UP
}

@export var transition_speed: float = 3.0
@export var sway_amount: float = 0.02
@export var sway_speed: float = 0.6
@export var orbit_amount: float = 0.008

# Camera presets: {position, rotation_degrees, fov}
var _camera_presets: Dictionary = {
	CameraView.FRONT: {
		"pos": Vector3(0.0, 2.05, 2.45),
		"rot": Vector3(-15.0, 0.0, 0.0),
		"fov": 52.0,
		"name": "Front"
	},
	CameraView.SIDE_LEFT: {
		"pos": Vector3(-2.6, 1.8, 0.6),
		"rot": Vector3(-12.0, 55.0, 0.0),
		"fov": 48.0,
		"name": "Side Left"
	},
	CameraView.TOP_DOWN: {
		"pos": Vector3(0.0, 3.8, 0.3),
		"rot": Vector3(-72.0, 0.0, 0.0),
		"fov": 45.0,
		"name": "Top View"
	},
	CameraView.ISOMETRIC: {
		"pos": Vector3(2.0, 2.6, 2.0),
		"rot": Vector3(-22.0, -35.0, 0.0),
		"fov": 42.0,
		"name": "Isometric"
	},
	CameraView.CLOSE_UP: {
		"pos": Vector3(0.0, 1.2, 1.4),
		"rot": Vector3(-5.0, 0.0, 0.0),
		"fov": 60.0,
		"name": "Close-Up"
	}
}

var current_view: CameraView = CameraView.FRONT
var _target_pos: Vector3
var _target_rot: Vector3
var _target_fov: float
var _time: float = 0.0
var _transitioning: bool = false

func _ready() -> void:
	var preset: Dictionary = _camera_presets[current_view]
	position = preset["pos"]
	rotation_degrees = preset["rot"]
	fov = preset["fov"]
	_target_pos = position
	_target_rot = rotation_degrees
	_target_fov = fov

func _process(delta: float) -> void:
	_time += delta * sway_speed
	
	# Smooth camera transition
	var lerp_weight: float = clampf(delta * transition_speed, 0.01, 0.5)
	
	# Sway offset (subtle breathing motion)
	var sway_x: float = sin(_time) * sway_amount
	var sway_y: float = cos(_time * 0.7) * (sway_amount * 0.5)
	# Very subtle orbit
	var orbit_x: float = sin(_time * 0.3) * orbit_amount
	
	var final_pos: Vector3 = _target_pos + Vector3(sway_x, sway_y, 0.0)
	var final_rot: Vector3 = _target_rot + Vector3(0.0, orbit_x * 10.0, 0.0)
	
	position = position.lerp(final_pos, lerp_weight)
	rotation_degrees = rotation_degrees.lerp(final_rot, lerp_weight)
	fov = lerpf(fov, _target_fov, lerp_weight)

func _unhandled_input(event: InputEvent) -> void:
	# Number keys 1-5 switch camera views
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				switch_to_view(CameraView.FRONT)
			KEY_2:
				switch_to_view(CameraView.SIDE_LEFT)
			KEY_3:
				switch_to_view(CameraView.TOP_DOWN)
			KEY_4:
				switch_to_view(CameraView.ISOMETRIC)
			KEY_5:
				switch_to_view(CameraView.CLOSE_UP)
			KEY_TAB:
				# Cycle through views
				cycle_next_view()

func switch_to_view(view: CameraView) -> void:
	if current_view == view:
		return
	current_view = view
	var preset: Dictionary = _camera_presets[view]
	_target_pos = preset["pos"]
	_target_rot = preset["rot"]
	_target_fov = preset["fov"]
	_transitioning = true
	camera_changed.emit(preset["name"])

func cycle_next_view() -> void:
	var next_idx: int = (current_view + 1) % _camera_presets.size()
	switch_to_view(next_idx as CameraView)

func get_current_view_name() -> String:
	return _camera_presets[current_view]["name"]

func get_view_count() -> int:
	return _camera_presets.size()
