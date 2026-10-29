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
@onready var camera_view_label: Label = $CameraViewLabel if has_node("CameraViewLabel") else null
@onready var camera_hint_label: Label = $CameraHintLabel if has_node("CameraHintLabel") else null

var _countdown_active: bool = false
var _cam_notification_tween: Tween = null

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
	
	# Set up camera view notification label
	_setup_camera_ui()
	
	_on_settings_changed()
	_update_tracking_ui()
	_on_score_changed(GameManager.current_score)
	_on_time_updated(GameManager.time_left)
	if GameManager.current_state == GameManager.GameState.COUNTDOWN:
		run_countdown()

func _setup_camera_ui() -> void:
	# Create camera view notification label if not in scene
	if not camera_view_label:
		camera_view_label = Label.new()
		camera_view_label.name = "CameraViewLabel"
		camera_view_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		camera_view_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		camera_view_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
		camera_view_label.anchor_left = 0.5
		camera_view_label.anchor_top = 1.0
		camera_view_label.anchor_right = 0.5
		camera_view_label.anchor_bottom = 1.0
		camera_view_label.offset_left = -150
		camera_view_label.offset_top = -80
		camera_view_label.offset_right = 150
		camera_view_label.offset_bottom = -50
		camera_view_label.add_theme_font_size_override("font_size", 18)
		camera_view_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0, 1.0))
		camera_view_label.modulate.a = 0.0
		add_child(camera_view_label)
	
	# Camera hint label (always visible)
	if not camera_hint_label:
		camera_hint_label = Label.new()
		camera_hint_label.name = "CameraHintLabel"
		camera_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		camera_hint_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
		camera_hint_label.anchor_left = 1.0
		camera_hint_label.anchor_top = 1.0
		camera_hint_label.anchor_right = 1.0
		camera_hint_label.anchor_bottom = 1.0
		camera_hint_label.offset_left = -220
		camera_hint_label.offset_top = -30
		camera_hint_label.offset_right = -12
		camera_hint_label.offset_bottom = -8
		camera_hint_label.add_theme_font_size_override("font_size", 11)
		camera_hint_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.8, 0.5))
		camera_hint_label.text = "TAB: Cycle Camera  |  1-5: Views"
		add_child(camera_hint_label)

func show_camera_notification(view_name: String) -> void:
	if not camera_view_label:
		return
	
	camera_view_label.text = "📷 %s View" % view_name
	camera_view_label.modulate.a = 1.0
	camera_view_label.scale = Vector2(1.3, 1.3)
	
	if _cam_notification_tween and _cam_notification_tween.is_valid():
		_cam_notification_tween.kill()
	
	_cam_notification_tween = create_tween().set_parallel(true)
	_cam_notification_tween.tween_property(camera_view_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_cam_notification_tween.tween_property(camera_view_label, "modulate:a", 0.0, 2.0).set_delay(0.8)

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
