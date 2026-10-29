extends Node

signal settings_changed
signal graphics_changed

const SETTINGS_FILE: String = "user://settings.cfg"

# Controls settings
var movement_sensitivity: float = 1.0
var claw_speed: float = 1.0
var gesture_threshold: float = 0.45
var hand_smoothing: float = 0.5
var control_mode: int = 0  # 0: Direct, 1: Joystick, 2: Mouse
var current_preset: String = "Normal"

# Graphics settings
var quality_preset: int = 2 # 0: Low, 1: Med, 2: High, 3: Ultra, 4: Custom
var render_scale: float = 1.0
var window_mode: int = 0    # 0: Windowed, 1: Fullscreen
var vsync: bool = true
var fps_cap: int = 60       # 0: unlimited
var msaa_3d: int = 2        # Viewport.MSAA_4X
var shadow_quality: int = 2 # 0: Low, 1: Med, 2: High, 3: Ultra
var ssao_enabled: bool = true
var ssil_enabled: bool = false
var glow_enabled: bool = true
var sdfgi_enabled: bool = false
var reflections_enabled: bool = true
var show_fps: bool = true
var camera_preview: bool = true

var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	load_settings()
	apply_all_settings()

func load_settings() -> void:
	var err: Error = _config.load(SETTINGS_FILE)
	if err == OK:
		movement_sensitivity = _config.get_value("controls", "movement_sensitivity", 1.0)
		claw_speed = _config.get_value("controls", "claw_speed", 1.0)
		gesture_threshold = _config.get_value("controls", "gesture_threshold", 0.45)
		hand_smoothing = _config.get_value("controls", "hand_smoothing", 0.5)
		control_mode = _config.get_value("controls", "control_mode", 0)
		current_preset = _config.get_value("controls", "current_preset", "Normal")
		
		quality_preset = _config.get_value("graphics", "quality_preset", 2)
		render_scale = _config.get_value("graphics", "render_scale", 1.0)
		window_mode = _config.get_value("graphics", "window_mode", 0)
		vsync = _config.get_value("graphics", "vsync", true)
		fps_cap = _config.get_value("graphics", "fps_cap", 60)
		msaa_3d = _config.get_value("graphics", "msaa_3d", 2)
		shadow_quality = _config.get_value("graphics", "shadow_quality", 2)
		ssao_enabled = _config.get_value("graphics", "ssao_enabled", true)
		ssil_enabled = _config.get_value("graphics", "ssil_enabled", false)
		glow_enabled = _config.get_value("graphics", "glow_enabled", true)
		sdfgi_enabled = _config.get_value("graphics", "sdfgi_enabled", false)
		reflections_enabled = _config.get_value("graphics", "reflections_enabled", true)
		show_fps = _config.get_value("graphics", "show_fps", true)
		camera_preview = _config.get_value("graphics", "camera_preview", true)
	else:
		apply_preset("Normal")
		save_settings()

func save_settings() -> void:
	_config.set_value("controls", "movement_sensitivity", movement_sensitivity)
	_config.set_value("controls", "claw_speed", claw_speed)
	_config.set_value("controls", "gesture_threshold", gesture_threshold)
	_config.set_value("controls", "hand_smoothing", hand_smoothing)
	_config.set_value("controls", "control_mode", control_mode)
	_config.set_value("controls", "current_preset", current_preset)
	
	_config.set_value("graphics", "quality_preset", quality_preset)
	_config.set_value("graphics", "render_scale", render_scale)
	_config.set_value("graphics", "window_mode", window_mode)
	_config.set_value("graphics", "vsync", vsync)
	_config.set_value("graphics", "fps_cap", fps_cap)
	_config.set_value("graphics", "msaa_3d", msaa_3d)
	_config.set_value("graphics", "shadow_quality", shadow_quality)
	_config.set_value("graphics", "ssao_enabled", ssao_enabled)
	_config.set_value("graphics", "ssil_enabled", ssil_enabled)
	_config.set_value("graphics", "glow_enabled", glow_enabled)
	_config.set_value("graphics", "sdfgi_enabled", sdfgi_enabled)
	_config.set_value("graphics", "reflections_enabled", reflections_enabled)
	_config.set_value("graphics", "show_fps", show_fps)
	_config.set_value("graphics", "camera_preview", camera_preview)
	
	_config.save(SETTINGS_FILE)

func apply_preset(preset: String) -> void:
	current_preset = preset
	match preset:
		"Beginner":
			movement_sensitivity = 0.7
			claw_speed = 0.75
			gesture_threshold = 0.35
			hand_smoothing = 0.8
			control_mode = 0 # Direct
		"Normal":
			movement_sensitivity = 1.0
			claw_speed = 1.0
			gesture_threshold = 0.45
			hand_smoothing = 0.5
			control_mode = 0 # Direct
		"Precision":
			movement_sensitivity = 1.4
			claw_speed = 1.1
			gesture_threshold = 0.55
			hand_smoothing = 0.25
			control_mode = 1 # Joystick
		_:
			current_preset = "Custom"
	save_settings()
	settings_changed.emit()

func apply_graphics_preset(preset_idx: int) -> void:
	quality_preset = preset_idx
	match preset_idx:
		0: # Low
			render_scale = 0.8
			msaa_3d = Viewport.MSAA_DISABLED
			shadow_quality = 0
			ssao_enabled = false
			ssil_enabled = false
			glow_enabled = false
			sdfgi_enabled = false
			reflections_enabled = false
		1: # Medium
			render_scale = 1.0
			msaa_3d = Viewport.MSAA_2X
			shadow_quality = 1
			ssao_enabled = true
			ssil_enabled = false
			glow_enabled = true
			sdfgi_enabled = false
			reflections_enabled = true
		2: # High
			render_scale = 1.0
			msaa_3d = Viewport.MSAA_4X
			shadow_quality = 2
			ssao_enabled = true
			ssil_enabled = false
			glow_enabled = true
			sdfgi_enabled = false
			reflections_enabled = true
		3: # Ultra
			render_scale = 1.0
			msaa_3d = Viewport.MSAA_8X
			shadow_quality = 3
			ssao_enabled = true
			ssil_enabled = true
			glow_enabled = true
			sdfgi_enabled = true
			reflections_enabled = true
		_:
			quality_preset = 4 # Custom
	apply_all_settings()
	save_settings()

func apply_all_settings() -> void:
	# Engine & Window
	Engine.max_fps = fps_cap
	
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	if window_mode == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Viewport settings
	var root_viewport: Viewport = get_viewport()
	if root_viewport:
		root_viewport.scaling_3d_scale = render_scale
		root_viewport.msaa_3d = msaa_3d as Viewport.MSAA
	
	graphics_changed.emit()
	settings_changed.emit()

func apply_environment_settings(env: Environment) -> void:
	if not env:
		return
	env.ssao_enabled = ssao_enabled
	env.ssil_enabled = ssil_enabled
	env.glow_enabled = glow_enabled
	env.sdfgi_enabled = sdfgi_enabled
