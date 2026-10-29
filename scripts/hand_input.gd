extends Node

signal grab_triggered
signal tracking_status_changed(is_tracking: bool)
signal gesture_changed(gesture_name: String)
signal sidecar_error(message: String)

const UDP_PORT: int = 4242
const TIMEOUT_DURATION: float = 0.5
const GESTURE_HOLD_TIME: float = 0.15
const GESTURE_COOLDOWN: float = 0.4

# Public state
var hand_detected: bool = false
var is_tracking: bool = false
var raw_hand_pos: Vector2 = Vector2(0.5, 0.5)
var smoothed_hand_pos: Vector2 = Vector2(0.5, 0.5)
var pinch_distance: float = 1.0
var fist_amount: float = 0.0
var current_gesture: String = "Open"
var is_grabbing_gesture: bool = false
var is_mouse_mode: bool = false
var sidecar_status_message: String = ""

# Landmarks data for HUD camera overlay
var landmarks_dict: Dictionary = {}

# Internal tracking variables
var _udp_server: PacketPeerUDP = PacketPeerUDP.new()
var _last_packet_time: float = 0.0
var _gesture_held_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _grab_latched: bool = false
var _sidecar_pid: int = -1

# Mouse tracking fallback variables
var _mouse_screen_pos: Vector2 = Vector2(0.5, 0.5)

func _ready() -> void:
	var bind_err: Error = _udp_server.bind(UDP_PORT, "127.0.0.1")
	if bind_err != OK:
		push_warning("HandInput: Unable to bind UDP port %d: %d" % [UDP_PORT, bind_err])
	
	try_start_sidecar()

func _exit_tree() -> void:
	stop_sidecar()
	if _udp_server.is_bound():
		_udp_server.close()

func try_start_sidecar() -> void:
	var script_path: String = ProjectSettings.globalize_path("res://hand_tracker/hand_tracker.py")
	if not FileAccess.file_exists("res://hand_tracker/hand_tracker.py"):
		sidecar_status_message = "Sidecar script not found."
		is_mouse_mode = true
		return
	
	# Determine python executable
	var py_exec: String = "python3"
	# Check virtualenv inside hand_tracker if present
	var venv_py: String = ProjectSettings.globalize_path("res://hand_tracker/.venv/bin/python")
	if FileAccess.file_exists("res://hand_tracker/.venv/bin/python"):
		py_exec = venv_py
	
	var args: PackedStringArray = [script_path, str(UDP_PORT)]
	_sidecar_pid = OS.create_process(py_exec, args)
	if _sidecar_pid <= 0:
		sidecar_status_message = "Failed to launch Python sidecar. Mouse fallback active."
		is_mouse_mode = true
		sidecar_error.emit(sidecar_status_message)
	else:
		sidecar_status_message = "Python sidecar launched (PID %d)" % _sidecar_pid

func stop_sidecar() -> void:
	if _sidecar_pid > 0:
		OS.kill(_sidecar_pid)
		_sidecar_pid = -1

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp_size: Vector2 = get_viewport().get_visible_rect().size
		if vp_size.x > 0.0 and vp_size.y > 0.0:
			_mouse_screen_pos = Vector2(
				clampf(event.position.x / vp_size.x, 0.0, 1.0),
				clampf(event.position.y / vp_size.y, 0.0, 1.0)
			)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_mouse_mode or SettingsManager.control_mode == 2 or not is_tracking:
				trigger_grab()

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
	
	# Monitor sidecar process status
	if _sidecar_pid > 0 and not OS.is_process_running(_sidecar_pid):
		_sidecar_pid = -1
		is_mouse_mode = true
		sidecar_status_message = "Hand tracker process ended. Mouse fallback enabled."
		sidecar_error.emit(sidecar_status_message)
	
	# Check UDP packets
	_process_udp_packets()
	
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var time_since_packet: float = current_time - _last_packet_time
	
	var prev_tracking: bool = is_tracking
	
	if SettingsManager.control_mode == 2: # Explicit Mouse Mode
		is_tracking = true
		hand_detected = true
		smoothed_hand_pos = _mouse_screen_pos
		current_gesture = "Mouse"
	elif time_since_packet > TIMEOUT_DURATION or not hand_detected:
		is_tracking = false
		if prev_tracking:
			tracking_status_changed.emit(false)
			gesture_changed.emit("Lost")
	else:
		is_tracking = true
		if not prev_tracking:
			tracking_status_changed.emit(true)
		
		# Smooth hand position
		var smoothing_factor: float = clampf(SettingsManager.hand_smoothing, 0.0, 0.98)
		# 0 smoothing = 1.0 alpha (instant), 1.0 smoothing = 0.05 alpha (heavy)
		var lerp_weight: float = lerp(1.0, 0.05, smoothing_factor) * clampf(delta * 60.0, 0.1, 2.0)
		smoothed_hand_pos = smoothed_hand_pos.lerp(raw_hand_pos, clampf(lerp_weight, 0.01, 1.0))
		
		# Process gestures
		_process_gestures(delta)

func _process_udp_packets() -> void:
	while _udp_server.is_bound() and _udp_server.get_available_packet_count() > 0:
		var packet: PackedByteArray = _udp_server.get_packet()
		var text: String = packet.get_string_from_utf8()
		var json: JSON = JSON.new()
		var parse_err: Error = json.parse(text)
		if parse_err == OK and json.data is Dictionary:
			var data: Dictionary = json.data
			_last_packet_time = Time.get_ticks_msec() / 1000.0
			hand_detected = data.get("hand_detected", false)
			
			if hand_detected:
				landmarks_dict = data
				var palm: Dictionary = data.get("palm_center", {"x": 0.5, "y": 0.5})
				raw_hand_pos = Vector2(palm.get("x", 0.5), palm.get("y", 0.5))
				pinch_distance = data.get("pinch_distance", 1.0)
				fist_amount = data.get("fist_amount", 0.0)

func _process_gestures(delta: float) -> void:
	var threshold: float = SettingsManager.gesture_threshold
	# Hysteresis: press threshold is tighter, release threshold is looser
	var pinch_press_thresh: float = threshold * 0.45
	var pinch_release_thresh: float = threshold * 0.65
	var fist_press_thresh: float = 0.5 + (1.0 - threshold) * 0.3
	var fist_release_thresh: float = fist_press_thresh - 0.2
	
	var is_pinch: bool = pinch_distance < pinch_press_thresh
	var is_fist: bool = fist_amount > fist_press_thresh
	
	if is_grabbing_gesture:
		# Check if released
		if pinch_distance > pinch_release_thresh and fist_amount < fist_release_thresh:
			is_grabbing_gesture = false
			_gesture_held_timer = 0.0
			_grab_latched = false
			current_gesture = "Open"
			gesture_changed.emit(current_gesture)
	else:
		if is_pinch or is_fist:
			_gesture_held_timer += delta
			current_gesture = "Pinch" if is_pinch else "Fist"
			gesture_changed.emit(current_gesture)
			
			if _gesture_held_timer >= GESTURE_HOLD_TIME and not _grab_latched and _cooldown_timer <= 0.0:
				is_grabbing_gesture = true
				_grab_latched = true
				trigger_grab()
		else:
			_gesture_held_timer = 0.0
			if current_gesture != "Open":
				current_gesture = "Open"
				gesture_changed.emit(current_gesture)

func trigger_grab() -> void:
	if _cooldown_timer <= 0.0:
		_cooldown_timer = GESTURE_COOLDOWN
		grab_triggered.emit()

# Utility to get claw target vector in normalized -1..1 coordinates
func get_normalized_control_vector(deadzone: float = 0.05) -> Vector2:
	if SettingsManager.control_mode == 2 or (not is_tracking and is_mouse_mode):
		# Mouse direct position mapped from 0..1 to -1..1
		return Vector2((_mouse_screen_pos.x - 0.5) * 2.0, (_mouse_screen_pos.y - 0.5) * 2.0)
	
	if SettingsManager.control_mode == 0:
		# Direct Mode: mapped 0..1 to -1..1
		var mapped: Vector2 = Vector2((smoothed_hand_pos.x - 0.5) * 2.0, (smoothed_hand_pos.y - 0.5) * 2.0)
		return mapped
	else:
		# Joystick Mode: offset from center (0.5, 0.5)
		var offset: Vector2 = smoothed_hand_pos - Vector2(0.5, 0.5)
		if offset.length() < deadzone:
			return Vector2.ZERO
		return offset.normalized() * clampf((offset.length() - deadzone) / (0.4 - deadzone), 0.0, 1.0)
