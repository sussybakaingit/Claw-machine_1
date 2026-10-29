extends Node3D
class_name PrizeSpawner

@export var prize_scene: PackedScene = preload("res://scenes/prize.tscn")
@export var min_prizes: int = 25
@export var target_prizes: int = 35
@export var spawn_area_min: Vector3 = Vector3(-0.75, 1.2, -0.65)
@export var spawn_area_max: Vector3 = Vector3(0.75, 1.8, 0.65)
# Avoid spawning directly over the chute in the bottom left
@export var chute_avoid_min: Vector2 = Vector2(-0.9, 0.3)
@export var chute_avoid_max: Vector2 = Vector2(-0.4, 0.8)

var _active_prizes: Array[Prize] = []
var _check_timer: float = 0.0

func _ready() -> void:
	spawn_initial_prizes()

func spawn_initial_prizes() -> void:
	clear_prizes()
	for i in range(target_prizes):
		spawn_single_prize(i * 0.04)

func clear_prizes() -> void:
	for p in _active_prizes:
		if is_instance_valid(p):
			p.queue_free()
	_active_prizes.clear()

func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer >= 2.0:
		_check_timer = 0.0
		# Clean invalid references
		_active_prizes = _active_prizes.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
		if _active_prizes.size() < min_prizes:
			var needed: int = target_prizes - _active_prizes.size()
			for i in range(mini(needed, 4)):
				spawn_single_prize(i * 0.1)

func spawn_single_prize(delay_sec: float = 0.0) -> void:
	if delay_sec > 0.0:
		await get_tree().create_timer(delay_sec).timeout
	
	if not is_inside_tree():
		return
	
	var prize: Prize = prize_scene.instantiate() as Prize
	
	# Pick random position avoiding chute area
	var pos: Vector3 = Vector3.ZERO
	for attempt in range(10):
		var rx: float = randf_range(spawn_area_min.x, spawn_area_max.x)
		var rz: float = randf_range(spawn_area_min.z, spawn_area_max.z)
		if rx >= chute_avoid_min.x and rx <= chute_avoid_max.x and rz >= chute_avoid_min.y and rz <= chute_avoid_max.y:
			continue
		pos = Vector3(rx, randf_range(spawn_area_min.y, spawn_area_max.y), rz)
		break
	
	# Pick type based on rarity
	var roll: float = randf()
	if roll < 0.38:
		prize.prize_type = Prize.PrizeType.SPHERE
	elif roll < 0.72:
		prize.prize_type = Prize.PrizeType.CAPSULE
	elif roll < 0.93:
		prize.prize_type = Prize.PrizeType.CUBE
	else:
		prize.prize_type = Prize.PrizeType.STAR
	
	add_child(prize)
	prize.position = pos
	_active_prizes.append(prize)
