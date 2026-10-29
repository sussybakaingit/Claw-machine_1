extends Node3D
class_name ClawController

enum ClawState {
	IDLE,
	DESCENDING,
	GRABBING,
	ASCENDING,
	TRAVEL_TO_CHUTE,
	RELEASING,
	RETURN_TO_PLAY_AREA
}

@export var move_speed: float = 2.6
@export var descend_speed: float = 2.0
@export var ascend_speed: float = 2.2
@export var min_x: float = -0.72
@export var max_x: float = 0.72
@export var min_z: float = -0.62
@export var max_z: float = 0.62
@export var top_y: float = 2.05
@export var bottom_y: float = 0.38
@export var chute_target_pos: Vector3 = Vector3(-0.65, 2.05, 0.55)

var current_state: ClawState = ClawState.IDLE
var target_prong_angle: float = 0.65 # Open in radians (~37 deg)
var current_prong_angle: float = 0.65

# Node references
@onready var gantry_x: Node3D = $GantryX
@onready var carriage_z: Node3D = $GantryX/CarriageZ
@onready var claw_hub: Node3D = $GantryX/CarriageZ/ClawHub
@onready var cable_mesh: MeshInstance3D = $GantryX/CarriageZ/CableMesh
@onready var prongs_root: Node3D = $GantryX/CarriageZ/ClawHub/Prongs
@onready var reticle_marker: MeshInstance3D = $GantryX/CarriageZ/ReticleMarker if has_node("GantryX/CarriageZ/ReticleMarker") else null
@onready var grip_area: Area3D = $GantryX/CarriageZ/ClawHub/GripArea if has_node("GantryX/CarriageZ/ClawHub/GripArea") else null
@onready var raycast_down: RayCast3D = $GantryX/CarriageZ/ClawHub/RayCastDown if has_node("GantryX/CarriageZ/ClawHub/RayCastDown") else null

var _prong_nodes: Array[Node3D] = []
var _prong_radial_angles: Array[float] = [0.0, TAU / 3.0, (TAU * 2.0) / 3.0]
var _sequence_timer: float = 0.0
var _gripped_prize: Prize = null
var _cradle_offset: Vector3 = Vector3.ZERO
var _slip_chance: float = 0.0

func _ready() -> void:
	if prongs_root:
		for child in prongs_root.get_children():
			if child is Node3D:
				_prong_nodes.append(child)
	
	# Initial positions
	gantry_x.position.x = 0.0
	carriage_z.position.z = 0.0
	claw_hub.position.y = top_y
	update_cable_length()
	set_prong_open(true, true)
	
	HandInput.grab_triggered.connect(_on_grab_triggered)

func _on_grab_triggered() -> void:
	if current_state == ClawState.IDLE and (GameManager.current_state == GameManager.GameState.PLAYING or GameManager.current_state == GameManager.GameState.COUNTDOWN):
		start_grab_sequence()

func start_grab_sequence() -> void:
	current_state = ClawState.DESCENDING

func _process(delta: float) -> void:
	match current_state:
		ClawState.IDLE:
			# Allow movement during PLAYING or COUNTDOWN so player has immediate control
			if GameManager.current_state == GameManager.GameState.PLAYING or GameManager.current_state == GameManager.GameState.COUNTDOWN:
				_handle_player_movement(delta)
				
		ClawState.DESCENDING:
			var speed: float = descend_speed * SettingsManager.claw_speed
			claw_hub.position.y -= speed * delta
			update_cable_length()
			
			var hit_bottom: bool = claw_hub.position.y <= bottom_y
			if raycast_down and raycast_down.is_colliding():
				var col_point: Vector3 = raycast_down.get_collision_point()
				if claw_hub.global_position.y - col_point.y < 0.36:
					hit_bottom = true
			
			if hit_bottom:
				current_state = ClawState.GRABBING
				_sequence_timer = 0.0
				set_prong_open(false)
				_try_grip_prize()
				
		ClawState.GRABBING:
			_sequence_timer += delta
			_maintain_gripped_prize()
			if _sequence_timer >= 0.6:
				current_state = ClawState.ASCENDING
				
		ClawState.ASCENDING:
			var speed: float = ascend_speed * SettingsManager.claw_speed
			claw_hub.position.y = move_toward(claw_hub.position.y, top_y, speed * delta)
			update_cable_length()
			_maintain_gripped_prize()
			_check_slip(delta * 0.15)
			
			if is_equal_approx(claw_hub.position.y, top_y):
				current_state = ClawState.TRAVEL_TO_CHUTE
				
		ClawState.TRAVEL_TO_CHUTE:
			var speed: float = move_speed * SettingsManager.claw_speed * 1.3
			gantry_x.position.x = move_toward(gantry_x.position.x, chute_target_pos.x, speed * delta)
			carriage_z.position.z = move_toward(carriage_z.position.z, chute_target_pos.z, speed * delta)
			_maintain_gripped_prize()
			_check_slip(delta * 0.25)
			
			if is_equal_approx(gantry_x.position.x, chute_target_pos.x) and is_equal_approx(carriage_z.position.z, chute_target_pos.z):
				current_state = ClawState.RELEASING
				_sequence_timer = 0.0
				set_prong_open(true)
				_release_gripped_prize()
				
		ClawState.RELEASING:
			_sequence_timer += delta
			if _sequence_timer >= 0.85:
				current_state = ClawState.RETURN_TO_PLAY_AREA
				
		ClawState.RETURN_TO_PLAY_AREA:
			var speed: float = move_speed * SettingsManager.claw_speed
			gantry_x.position.x = move_toward(gantry_x.position.x, 0.0, speed * delta)
			carriage_z.position.z = move_toward(carriage_z.position.z, 0.0, speed * delta)
			
			if is_equal_approx(gantry_x.position.x, 0.0) and is_equal_approx(carriage_z.position.z, 0.0):
				current_state = ClawState.IDLE

	# Smooth animate prongs
	current_prong_angle = lerpf(current_prong_angle, target_prong_angle, clampf(delta * 10.0, 0.0, 1.0))
	for i in range(_prong_nodes.size()):
		var prong: Node3D = _prong_nodes[i]
		if is_instance_valid(prong):
			var yaw: float = _prong_radial_angles[i] if i < _prong_radial_angles.size() else 0.0
			# Orient radially and pitch inwards/outwards
			prong.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, current_prong_angle)

func _handle_player_movement(delta: float) -> void:
	var ctrl: Vector2 = HandInput.get_normalized_control_vector()
	var speed: float = move_speed * SettingsManager.claw_speed * SettingsManager.movement_sensitivity
	
	if SettingsManager.control_mode == 0 or SettingsManager.control_mode == 2 or (not HandInput.is_tracking and HandInput.is_mouse_mode):
		# Direct mapping
		var target_x: float = clampf(ctrl.x * max_x, min_x, max_x)
		var target_z: float = clampf(ctrl.y * max_z, min_z, max_z)
		
		# Smooth towards direct target
		var lerp_weight: float = clampf(delta * 8.0 * SettingsManager.movement_sensitivity, 0.05, 0.9)
		gantry_x.position.x = lerpf(gantry_x.position.x, target_x, lerp_weight)
		carriage_z.position.z = lerpf(carriage_z.position.z, target_z, lerp_weight)
	else:
		# Joystick Mode (velocity based)
		gantry_x.position.x = clampf(gantry_x.position.x + ctrl.x * speed * delta, min_x, max_x)
		carriage_z.position.z = clampf(carriage_z.position.z + ctrl.y * speed * delta, min_z, max_z)

func _try_grip_prize() -> void:
	if not grip_area:
		return
	var bodies: Array[Node3D] = grip_area.get_overlapping_bodies()
	var closest_prize: Prize = null
	var min_dist: float = 999.0
	
	for body in bodies:
		if body is Prize and is_instance_valid(body) and not body.is_queued_for_deletion():
			var dist: float = claw_hub.global_position.distance_to(body.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_prize = body as Prize
	
	if closest_prize:
		_gripped_prize = closest_prize
		_cradle_offset = _gripped_prize.global_position - claw_hub.global_position
		_gripped_prize.freeze = true
		# Slight slip chance if grabbed off-center
		var off_center: float = Vector2(_cradle_offset.x, _cradle_offset.z).length()
		_slip_chance = clampf((off_center - 0.12) * 1.5, 0.0, 0.25)

func _maintain_gripped_prize() -> void:
	if is_instance_valid(_gripped_prize) and not _gripped_prize.is_queued_for_deletion():
		_gripped_prize.global_position = claw_hub.global_position + _cradle_offset

func _check_slip(chance_step: float) -> void:
	if is_instance_valid(_gripped_prize) and _slip_chance > 0.0:
		if randf() < (_slip_chance * chance_step):
			# Slip prize!
			_release_gripped_prize()
			_slip_chance = 0.0

func _release_gripped_prize() -> void:
	if is_instance_valid(_gripped_prize) and not _gripped_prize.is_queued_for_deletion():
		_gripped_prize.freeze = false
		_gripped_prize.linear_velocity = Vector3(randf_range(-0.1, 0.1), -1.2, randf_range(-0.1, 0.1))
		_gripped_prize = null

func set_prong_open(is_open: bool, instant: bool = false) -> void:
	# Open angle: 0.65 rad (~37 deg flared out)
	# Closed angle: -0.32 rad (~ -18 deg curved in to grip)
	target_prong_angle = 0.65 if is_open else -0.32
	if instant:
		current_prong_angle = target_prong_angle
		for i in range(_prong_nodes.size()):
			var prong: Node3D = _prong_nodes[i]
			if is_instance_valid(prong):
				var yaw: float = _prong_radial_angles[i] if i < _prong_radial_angles.size() else 0.0
				prong.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, current_prong_angle)

func update_cable_length() -> void:
	if cable_mesh and claw_hub:
		var dist: float = maxf(0.05, top_y - claw_hub.position.y)
		cable_mesh.position.y = top_y - (dist * 0.5)
		if cable_mesh.mesh is CylinderMesh:
			var cyl: CylinderMesh = cable_mesh.mesh as CylinderMesh
			cyl.height = dist
