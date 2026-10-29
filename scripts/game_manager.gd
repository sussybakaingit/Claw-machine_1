extends Node

signal state_changed(new_state: int)
signal score_changed(new_score: int)
signal time_updated(time_left: float)
signal prize_scored(points: int, world_pos: Vector3)

enum GameState {
	MENU,
	CALIBRATION,
	COUNTDOWN,
	PLAYING,
	PAUSED,
	RESULTS
}

const SAVE_FILE: String = "user://save_data.cfg"

var current_state: GameState = GameState.MENU
var round_duration: float = 60.0 # 30.0 or 60.0
var time_left: float = 60.0
var current_score: int = 0
var high_score: int = 0
var prizes_won_count: int = 0
var previous_state: GameState = GameState.MENU

var _save_config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	load_save_data()

func load_save_data() -> void:
	if _save_config.load(SAVE_FILE) == OK:
		high_score = _save_config.get_value("stats", "high_score", 0)
	else:
		high_score = 0

func save_high_score() -> void:
	if current_score > high_score:
		high_score = current_score
	_save_config.set_value("stats", "high_score", high_score)
	_save_config.save(SAVE_FILE)

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	previous_state = current_state
	current_state = new_state
	state_changed.emit(new_state)

func start_game_round(duration: float = 60.0) -> void:
	round_duration = duration
	time_left = duration
	current_score = 0
	prizes_won_count = 0
	score_changed.emit(current_score)
	time_updated.emit(time_left)
	change_state(GameState.COUNTDOWN)

func begin_playing() -> void:
	change_state(GameState.PLAYING)

func add_points(pts: int, drop_pos: Vector3 = Vector3.ZERO) -> void:
	if current_state != GameState.PLAYING:
		return
	current_score += pts
	prizes_won_count += 1
	score_changed.emit(current_score)
	prize_scored.emit(pts, drop_pos)
	if current_score > high_score:
		high_score = current_score

func finish_round() -> void:
	save_high_score()
	change_state(GameState.RESULTS)

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		get_tree().paused = true
	elif current_state == GameState.PAUSED:
		get_tree().paused = false
		change_state(GameState.PLAYING)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		time_left = maxf(0.0, time_left - delta)
		time_updated.emit(time_left)
		if time_left <= 0.0:
			finish_round()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameState.PLAYING or current_state == GameState.PAUSED:
			toggle_pause()
