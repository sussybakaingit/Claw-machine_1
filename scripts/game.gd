extends Node3D
class_name GameRoot

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var claw_machine: ClawMachine = $ClawMachine
@onready var calibration_menu: CalibrationMenu = $Calibration
@onready var hud: HUD = $HUD
@onready var camera_controller: CameraController = $Camera3D if $Camera3D is CameraController else null

func _ready() -> void:
	SettingsManager.graphics_changed.connect(_on_graphics_changed)
	_on_graphics_changed()
	
	if calibration_menu:
		calibration_menu.calibration_finished.connect(_on_calibration_finished)
	
	# If entering game directly, check if calibration should run or jump to countdown
	if GameManager.current_state == GameManager.GameState.CALIBRATION:
		if calibration_menu:
			calibration_menu.visible = true
			calibration_menu.set_process(true)
	else:
		if calibration_menu:
			calibration_menu.visible = false
			calibration_menu.set_process(false)
		GameManager.start_game_round(GameManager.round_duration)
	
	# Connect camera view changes to HUD notification
	if camera_controller:
		camera_controller.camera_changed.connect(_on_camera_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.toggle_pause()

func _on_calibration_finished() -> void:
	GameManager.start_game_round(GameManager.round_duration)

func _on_graphics_changed() -> void:
	if world_env and world_env.environment:
		SettingsManager.apply_environment_settings(world_env.environment)

func _on_camera_changed(view_name: String) -> void:
	# Show camera view notification on HUD
	if hud and hud.has_method("show_camera_notification"):
		hud.show_camera_notification(view_name)
