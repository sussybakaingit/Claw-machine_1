extends Control
class_name PauseMenu

@onready var settings_modal: SettingsMenu = $SettingsMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if settings_modal:
		settings_modal.visible = false
		settings_modal.back_pressed.connect(_on_settings_back)
	GameManager.state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(state: GameManager.GameState) -> void:
	visible = (state == GameManager.GameState.PAUSED)
	if not visible and settings_modal:
		settings_modal.visible = false

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_settings_pressed() -> void:
	if settings_modal:
		settings_modal.visible = true

func _on_settings_back() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
