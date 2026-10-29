extends Control
class_name MainMenu

@onready var btn_play: Button = $UI/Margin/VBox/MenuCard/Margin/VBox/BtnPlay
@onready var round_30_btn: Button = $UI/Margin/VBox/MenuCard/Margin/VBox/DurationBox/Btn30s
@onready var round_60_btn: Button = $UI/Margin/VBox/MenuCard/Margin/VBox/DurationBox/Btn60s
@onready var btn_settings: Button = $UI/Margin/VBox/MenuCard/Margin/VBox/BtnSettings
@onready var btn_calibrate: Button = $UI/Margin/VBox/MenuCard/Margin/VBox/BtnCalibrate
@onready var high_score_label: Label = $UI/Margin/VBox/MenuCard/Margin/VBox/HighScoreLabel
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var status_badge: Label = $UI/Margin/VBox/MenuCard/Margin/VBox/StatusBadge

var selected_duration: float = 60.0

func _ready() -> void:
	if settings_menu:
		settings_menu.visible = false
		settings_menu.back_pressed.connect(_on_settings_back)
	
	_update_duration_buttons()
	_update_high_score()
	_update_status_badge()
	HandInput.tracking_status_changed.connect(func(_t): _update_status_badge())

func _update_duration_buttons() -> void:
	if selected_duration == 30.0:
		round_30_btn.modulate = Color(0.2, 0.9, 1.0, 1.0)
		round_60_btn.modulate = Color(0.7, 0.7, 0.7, 0.7)
	else:
		selected_duration = 60.0
		round_30_btn.modulate = Color(0.7, 0.7, 0.7, 0.7)
		round_60_btn.modulate = Color(0.2, 0.9, 1.0, 1.0)

func _update_high_score() -> void:
	if high_score_label:
		high_score_label.text = "🏆 HIGH SCORE: %d" % GameManager.high_score

func _update_status_badge() -> void:
	if not status_badge:
		return
	if SettingsManager.control_mode == 2:
		status_badge.text = "🖱 Control Mode: Mouse Active"
		status_badge.modulate = Color(0.3, 0.8, 1.0)
	elif HandInput.is_tracking:
		status_badge.text = "✋ Webcam Hand Tracker Connected"
		status_badge.modulate = Color(0.3, 1.0, 0.5)
	else:
		status_badge.text = "🖱 Hand Tracker Waiting (Mouse Fallback Active)"
		status_badge.modulate = Color(1.0, 0.8, 0.3)

func _on_duration_30_pressed() -> void:
	selected_duration = 30.0
	_update_duration_buttons()

func _on_duration_60_pressed() -> void:
	selected_duration = 60.0
	_update_duration_buttons()

func _on_play_pressed() -> void:
	GameManager.round_duration = selected_duration
	GameManager.current_state = GameManager.GameState.COUNTDOWN
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_calibrate_pressed() -> void:
	GameManager.round_duration = selected_duration
	GameManager.current_state = GameManager.GameState.CALIBRATION
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_settings_pressed() -> void:
	if settings_menu:
		settings_menu.visible = true

func _on_settings_back() -> void:
	_update_status_badge()

func _on_quit_pressed() -> void:
	get_tree().quit()
