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

@export var move_speed: float = 2.4
@export var descend_speed: float = 1.8
@export var ascend_speed: float = 2.0
@export var min_x: float = -0.72
@export var max_x: float = 0.72
@export var min_z: float = -0.62
@export var max_z: float = 0.62
@export var top_y: float = 2.05
@export var bottom_y: float = 0.55
@export var chute_target_pos: Vector3 = Vector3(-0.65, 2.05, 0.55)

var current_state: ClawState = ClawState.IDLE
var target_prong_angle: float = 0.6 # Open in radians (~35 deg)
var current_prong_angle: float = 0.6

# Node references
@onready var gantry_x: Node3D = $GantryX
@onready var carriage_z: Node3D = $GantryX/CarriageZ
@onready var claw_hub: Node3D = $GantryX/CarriageZ/ClawHub
@onready var cable_mesh: MeshInstance3D = $GantryX/CarriageZ/CableMesh
@onready var prongs_root: Node3D = $GantryX/CarriageZ/ClawHub/Prongs
@onready var reticle_marker: MeshInstance3D = $GantryX/CarriageZ/ReticleMarker if has_node("GantryX/CarriageZ/ReticleMarker") else null

var _prong_nodes: Array[Node3D] = []
var _raycast_down: RayCast3D
var _sequence_timer: float = 0.0

func _ready() -> void:
	# Find the 3 prong base nodes
	if has_node("GantryX/CarriageZ/ClawHub/Prongs"):
		for child in prongs_root.get_children():
			if child is Node3D:
				_prong_nodes.append(child)
	
	if has_node("GantryX/CarriageZ/ClawHub/RayCastDown"):
		_raycast_down = $GantryX/CarriageZ/ClawHub/RayCastDown as RayCast3D
	
	# Initial positions
	gantry_x.position.x = 0.0
	carriage_z.position.z = 0.0
	claw_hub.position.y = top_y
	update_cable_length()
	set_prong_open(true, true)
	
	HandInput.grab_triggered.connect(_on_grab_triggered)

func _on_grab_triggered() -> void:
	if current_state == ClawState.IDLE and GameManager.current_state == GameManager.GameState.PLAYING:
		start_grab_sequence()

func start_grab_sequence() -> void:
	current_state = ClawState.DESCENDING

func _process(delta: float) -> void:
	match current_state:
		ClawState.IDLE:
			if GameManager.current_state == GameManager.GameState.PLAYING:
				_handle_player_movement(delta)
				
		ClawState.DESCENDING:
			var speed: float = descend_speed * SettingsManager.claw_speed
			claw_hub.position.y -= speed * delta
			update_cable_length()
			
			var hit_bottom: bool = claw_hub.position.y <= bottom_y
			if _raycast_down and _raycast_down.is_colliding():
				var col_point: Vector3 = _raycast_down.get_collision_point()
				if claw_hub.global_position.y - col_point.y < 0.42:
					hit_bottom = true
			
			if hit_bottom:
				current_state = ClawState.GRABBING
				_sequence_timer = 0.0
				set_prong_open(false)
				
		ClawState.GRABBING:
			_sequence_timer += delta
			if _sequence_timer >= 0.65:
				current_state = ClawState.ASCENDING
				
		ClawState.ASCENDING:
			var speed: float = ascend_speed * SettingsManager.claw_speed
			claw_hub.position.y = move_toward(claw_hub.position.y, top_y, speed * delta)
			update_cable_length()
			if is_equal_approx(claw_hub.position.y, top_y):
				current_state = ClawState.TRAVEL_TO_CHUTE
				
		ClawState.TRAVEL_TO_CHUTE:
			var speed: float = move_speed * SettingsManager.claw_speed * 1.2
			gantry_x.position.x = move_toward(gantry_x.position.x, chute_target_pos.x, speed * delta)
			carriage_z.position.z = move_toward(carriage_z.position.z, chute_target_pos.z, speed * delta)
			
			if is_equal_approx(gantry_x.position.x, chute_target_pos.x) and is_equal_approx(carriage_z.position.z, chute_target_pos.z):
				current_state = ClawState.RELEASING
				_sequence_timer = 0.0
				set_prong_open(true)
				
		ClawState.RELEASING:
			_sequence_timer += delta
			if _sequence_timer >= 1.0:
				current_state = ClawState.RETURN_TO_PLAY_AREA
				
		ClawState.RETURN_TO_PLAY_AREA:
			var speed: float = move_speed * SettingsManager.claw_speed
			gantry_x.position.x = move_toward(gantry_x.position.x, 0.0, speed * delta)
			carriage_z.position.z = move_toward(carriage_z.position.z, 0.0, speed * delta)
			
			if is_equal_approx(gantry_x.position.x, 0.0) and is_equal_approx(carriage_z.position.z, 0.0):
				current_state = ClawState.IDLE

	# Smooth animate prongs
	current_prong_angle = lerpf(current_prong_angle, target_prong_angle, clampf(delta * 10.0, 0.0, 1.0))
	for prong in _prong_nodes:
		if is_instance_valid(prong):
			prong.rotation.z = current_prong_angle

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

func set_prong_open(is_open: bool, instant: bool = false) -> void:
	# Open angle: 0.65 rad (~37 deg flared out)
	# Closed angle: -0.25 rad (~ -15 deg curved in to grip)
	target_prong_angle = 0.65 if is_open else -0.28
	if instant:
		current_prong_angle = target_prong_angle
		for prong in _prong_nodes:
			if is_instance_valid(prong):
				prong.rotation.z = current_prong_angle

func update_cable_length() -> void:
	if cable_mesh and claw_hub:
		var dist: float = maxf(0.05, top_y - claw_hub.position.y)
		cable_mesh.position.y = top_y - (dist * 0.5)
		if cable_mesh.mesh is CylinderMesh:
			var cyl: CylinderMesh = cable_mesh.mesh as CylinderMesh
			cyl.height = dist
