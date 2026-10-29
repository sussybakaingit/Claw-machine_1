extends Camera3D
class_name CameraSway

@export var sway_amount: float = 0.025
@export var sway_speed: float = 0.8

var _base_pos: Vector3
var _time: float = 0.0

func _ready() -> void:
	_base_pos = position

func _process(delta: float) -> void:
	_time += delta * sway_speed
	var offset_x: float = sin(_time) * sway_amount
	var offset_y: float = cos(_time * 0.7) * (sway_amount * 0.5)
	position = _base_pos + Vector3(offset_x, offset_y, 0)
