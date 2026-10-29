extends Control
class_name SettingsMenu

signal back_pressed

# Controls UI
@onready var sensitivity_slider: HSlider = $Panel/Margin/VBox/TabContainer/Controls/VBox/SensBox/Slider
@onready var sensitivity_val: Label = $Panel/Margin/VBox/TabContainer/Controls/VBox/SensBox/Val
@onready var speed_slider: HSlider = $Panel/Margin/VBox/TabContainer/Controls/VBox/SpeedBox/Slider
@onready var speed_val: Label = $Panel/Margin/VBox/TabContainer/Controls/VBox/SpeedBox/Val
@onready var threshold_slider: HSlider = $Panel/Margin/VBox/TabContainer/Controls/VBox/ThreshBox/Slider
@onready var threshold_val: Label = $Panel/Margin/VBox/TabContainer/Controls/VBox/ThreshBox/Val
@onready var smoothing_slider: HSlider = $Panel/Margin/VBox/TabContainer/Controls/VBox/SmoothBox/Slider
@onready var smoothing_val: Label = $Panel/Margin/VBox/TabContainer/Controls/VBox/SmoothBox/Val
@onready var mode_option: OptionButton = $Panel/Margin/VBox/TabContainer/Controls/VBox/ModeBox/OptionButton
@onready var preset_label: Label = $Panel/Margin/VBox/TabContainer/Controls/VBox/PresetBox/PresetLabel

# Graphics UI
@onready var quality_option: OptionButton = $Panel/Margin/VBox/TabContainer/Graphics/VBox/QualityBox/OptionButton
@onready var render_scale_slider: HSlider = $Panel/Margin/VBox/TabContainer/Graphics/VBox/ScaleBox/Slider
@onready var render_scale_val: Label = $Panel/Margin/VBox/TabContainer/Graphics/VBox/ScaleBox/Val
@onready var window_mode_option: OptionButton = $Panel/Margin/VBox/TabContainer/Graphics/VBox/WindowBox/OptionButton
@onready var vsync_check: CheckBox = $Panel/Margin/VBox/TabContainer/Graphics/VBox/VsyncBox/CheckBox
@onready var fps_cap_option: OptionButton = $Panel/Margin/VBox/TabContainer/Graphics/VBox/FPSCapBox/OptionButton
@onready var msaa_option: OptionButton = $Panel/Margin/VBox/TabContainer/Graphics/VBox/MSAABox/OptionButton
@onready var ssao_check: CheckBox = $Panel/Margin/VBox/TabContainer/Graphics/VBox/SSAOBox/CheckBox
@onready var glow_check: CheckBox = $Panel/Margin/VBox/TabContainer/Graphics/VBox/GlowBox/CheckBox
@onready var show_fps_check: CheckBox = $Panel/Margin/VBox/TabContainer/Graphics/VBox/ShowFPSBox/CheckBox
@onready var cam_preview_check: CheckBox = $Panel/Margin/VBox/TabContainer/Graphics/VBox/CamPreviewBox/CheckBox

var _updating_ui: bool = false

func _ready() -> void:
	_populate_dropdowns()
	sync_from_settings()

func _populate_dropdowns() -> void:
	mode_option.clear()
	mode_option.add_item("Direct (Camera 1:1)")
	mode_option.add_item("Joystick (Hand Offset)")
	mode_option.add_item("Mouse (Fallback/Testing)")
	
	quality_option.clear()
	quality_option.add_item("Low")
	quality_option.add_item("Medium")
	quality_option.add_item("High")
	quality_option.add_item("Ultra")
	quality_option.add_item("Custom")
	
	window_mode_option.clear()
	window_mode_option.add_item("Windowed")
	window_mode_option.add_item("Fullscreen")
	
	fps_cap_option.clear()
	fps_cap_option.add_item("30 FPS")
	fps_cap_option.add_item("60 FPS")
	fps_cap_option.add_item("120 FPS")
	fps_cap_option.add_item("Unlimited")
	
	msaa_option.clear()
	msaa_option.add_item("Disabled")
	msaa_option.add_item("2x")
	msaa_option.add_item("4x")
	msaa_option.add_item("8x")

func sync_from_settings() -> void:
	_updating_ui = true
	
	# Controls
	sensitivity_slider.value = SettingsManager.movement_sensitivity
	sensitivity_val.text = "%.2fx" % SettingsManager.movement_sensitivity
	
	speed_slider.value = SettingsManager.claw_speed
	speed_val.text = "%.2fx" % SettingsManager.claw_speed
	
	threshold_slider.value = SettingsManager.gesture_threshold
	threshold_val.text = "%.2f" % SettingsManager.gesture_threshold
	
	smoothing_slider.value = SettingsManager.hand_smoothing
	smoothing_val.text = "%.2f" % SettingsManager.hand_smoothing
	
	mode_option.selected = SettingsManager.control_mode
	preset_label.text = "Preset: %s" % SettingsManager.current_preset
	
	# Graphics
	quality_option.selected = SettingsManager.quality_preset
	render_scale_slider.value = SettingsManager.render_scale
	render_scale_val.text = "%.0f%%" % (SettingsManager.render_scale * 100.0)
	window_mode_option.selected = SettingsManager.window_mode
	vsync_check.button_pressed = SettingsManager.vsync
	
	match SettingsManager.fps_cap:
		30: fps_cap_option.selected = 0
		60: fps_cap_option.selected = 1
		120: fps_cap_option.selected = 2
		_: fps_cap_option.selected = 3
	
	msaa_option.selected = SettingsManager.msaa_3d
	ssao_check.button_pressed = SettingsManager.ssao_enabled
	glow_check.button_pressed = SettingsManager.glow_enabled
	show_fps_check.button_pressed = SettingsManager.show_fps
	cam_preview_check.button_pressed = SettingsManager.camera_preview
	
	_updating_ui = false

# Controls callbacks
func _on_sens_changed(val: float) -> void:
	if _updating_ui: return
	SettingsManager.movement_sensitivity = val
	sensitivity_val.text = "%.2fx" % val
	mark_custom_preset()

func _on_speed_changed(val: float) -> void:
	if _updating_ui: return
	SettingsManager.claw_speed = val
	speed_val.text = "%.2fx" % val
	mark_custom_preset()

func _on_thresh_changed(val: float) -> void:
	if _updating_ui: return
	SettingsManager.gesture_threshold = val
	threshold_val.text = "%.2f" % val
	mark_custom_preset()

func _on_smooth_changed(val: float) -> void:
	if _updating_ui: return
	SettingsManager.hand_smoothing = val
	smoothing_val.text = "%.2f" % val
	mark_custom_preset()

func _on_mode_selected(idx: int) -> void:
	if _updating_ui: return
	SettingsManager.control_mode = idx
	mark_custom_preset()

func mark_custom_preset() -> void:
	SettingsManager.current_preset = "Custom"
	preset_label.text = "Preset: Custom"
	SettingsManager.save_settings()

func _on_preset_beginner_pressed() -> void:
	SettingsManager.apply_preset("Beginner")
	sync_from_settings()

func _on_preset_normal_pressed() -> void:
	SettingsManager.apply_preset("Normal")
	sync_from_settings()

func _on_preset_precision_pressed() -> void:
	SettingsManager.apply_preset("Precision")
	sync_from_settings()

func _on_reset_controls_pressed() -> void:
	SettingsManager.apply_preset("Normal")
	sync_from_settings()

# Graphics callbacks
func _on_quality_selected(idx: int) -> void:
	if _updating_ui: return
	SettingsManager.apply_graphics_preset(idx)
	sync_from_settings()

func _on_scale_changed(val: float) -> void:
	if _updating_ui: return
	SettingsManager.render_scale = val
	render_scale_val.text = "%.0f%%" % (val * 100.0)
	SettingsManager.quality_preset = 4
	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()

func _on_window_selected(idx: int) -> void:
	if _updating_ui: return
	SettingsManager.window_mode = idx
	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()

func _on_vsync_toggled(toggled_on: bool) -> void:
	if _updating_ui: return
	SettingsManager.vsync = toggled_on
	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()

func _on_fps_cap_selected(idx: int) -> void:
	if _updating_ui: return
	match idx:
		0: SettingsManager.fps_cap = 30
		1: SettingsManager.fps_cap = 60
		2: SettingsManager.fps_cap = 120
		_: SettingsManager.fps_cap = 0
	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()

func _on_msaa_selected(idx: int) -> void:
	if _updating_ui: return
	SettingsManager.msaa_3d = idx
	SettingsManager.quality_preset = 4
	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()

func _on_ssao_toggled(toggled_on: bool) -> void:
	if _updating_ui: return
	SettingsManager.ssao_enabled = toggled_on
	SettingsManager.quality_preset = 4
	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()

func _on_glow_toggled(toggled_on: bool) -> void:
	if _updating_ui: return
	SettingsManager.glow_enabled = toggled_on
	SettingsManager.quality_preset = 4
	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()

func _on_show_fps_toggled(toggled_on: bool) -> void:
	if _updating_ui: return
	SettingsManager.show_fps = toggled_on
	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()

func _on_cam_preview_toggled(toggled_on: bool) -> void:
	if _updating_ui: return
	SettingsManager.camera_preview = toggled_on
	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()

func _on_back_pressed() -> void:
	SettingsManager.save_settings()
	back_pressed.emit()
	visible = false
