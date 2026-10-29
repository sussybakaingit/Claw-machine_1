extends Control
class_name HUD

@onready var timer_label: Label = $TopBar/Margin/HBox/TimerContainer/TimerLabel
@onready var score_label: Label = $TopBar/Margin/HBox/ScoreContainer/ScoreLabel
@onready var high_score_label: Label = $TopBar/Margin/HBox/HighScoreContainer/HighScoreLabel
@onready var status_indicator: ColorRect = $TrackingBadge/Margin/HBox/StatusDot
@onready var status_label: Label = $TrackingBadge/Margin/HBox/StatusLabel
@onready var gesture_label: Label = $TrackingBadge/Margin/HBox/GestureLabel
@onready var countdown_panel: Control = $CountdownOverlay
@onready var countdown_label: Label = $CountdownOverlay/CountdownLabel
@onready var camera_preview_panel: PanelContainer = $CameraPreviewPanel
@onready var landmark_drawer: Control = $CameraPreviewPanel/VBox/LandmarkCanvas
@onready var fps_label: Label = $FPSLabel
@onready var error_banner: PanelContainer = $ErrorBanner if has_node("ErrorBanner") else null

var _countdown_active: bool = false

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.state_changed.connect(_on_state_changed)
	HandInput.tracking_status_changed.connect(_on_tracking_changed)
	HandInput.gesture_changed.connect(_on_gesture_changed)
	HandInput.sidecar_error.connect(_on_sidecar_error)
	SettingsManager.settings_changed.connect(_on_settings_changed)
	
	if has_node("CountdownOverlay"):
		countdown_panel.visible = false
	
	_on_settings_changed()
	_update_tracking_ui()
	_on_score_changed(GameManager.current_score)
	_on_time_updated(GameManager.time_left)
	if GameManager.current_state == GameManager.GameState.COUNTDOWN:
		run_countdown()

func _on_settings_changed() -> void:
	if camera_preview_panel:
		camera_preview_panel.visible = SettingsManager.camera_preview and SettingsManager.control_mode != 2
	if fps_label:
		fps_label.visible = SettingsManager.show_fps

func _process(_delta: float) -> void:
	if fps_label and fps_label.visible:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
	_update_tracking_ui()
	if camera_preview_panel and camera_preview_panel.visible and landmark_drawer:
		landmark_drawer.queue_redraw()

func _update_tracking_ui() -> void:
	if not status_indicator or not status_label:
		return
	
	if SettingsManager.control_mode == 2:
		status_indicator.color = Color(0.2, 0.8, 1.0)
		status_label.text = "MOUSE MODE"
		gesture_label.text = "Click to Grab"
	elif HandInput.is_tracking:
		status_indicator.color = Color(0.2, 1.0, 0.4)
		status_label.text = "TRACKING"
		gesture_label.text = HandInput.current_gesture
	else:
		status_indicator.color = Color(1.0, 0.7, 0.2)
		status_label.text = "HAND LOST"
		gesture_label.text = "Holding Pos (Mouse Active)"

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "SCORE: %d" % new_score
		var tw: Tween = create_tween()
		score_label.scale = Vector2(1.2, 1.2)
		tw.tween_property(score_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if high_score_label:
		high_score_label.text = "BEST: %d" % GameManager.high_score

func _on_time_updated(seconds_left: float) -> void:
	if timer_label:
		var mins: int = int(seconds_left / 60.0)
		var secs: int = int(seconds_left) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		if seconds_left <= 10.0:
			timer_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			timer_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_state_changed(state: GameManager.GameState) -> void:
	if state == GameManager.GameState.COUNTDOWN:
		run_countdown()

func run_countdown() -> void:
	if _countdown_active:
		return
	_countdown_active = true
	countdown_panel.visible = true
	
	for count in ["3", "2", "1", "GO!"]:
		countdown_label.text = count
		countdown_label.scale = Vector2(1.8, 1.8)
		countdown_label.modulate.a = 1.0
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(countdown_label, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(countdown_label, "modulate:a", 0.3, 0.8)
		await get_tree().create_timer(0.85).timeout
	
	countdown_panel.visible = false
	_countdown_active = false
	GameManager.begin_playing()

func _on_tracking_changed(_tracking: bool) -> void:
	_update_tracking_ui()

func _on_gesture_changed(_gesture: String) -> void:
	_update_tracking_ui()

func _on_pause_button_pressed() -> void:
	GameManager.toggle_pause()

func _on_sidecar_error(msg: String) -> void:
	if error_banner:
		var lbl: Label = error_banner.get_node_or_null("Margin/HBox/Msg")
		if lbl:
			lbl.text = msg
		error_banner.visible = true

func _on_close_error_banner_pressed() -> void:
	if error_banner:
		error_banner.visible = false
