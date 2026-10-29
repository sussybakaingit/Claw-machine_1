extends Control
class_name ResultsMenu

@onready var final_score_label: Label = $Panel/Margin/VBox/ScoreBox/FinalScoreLabel
@onready var prizes_count_label: Label = $Panel/Margin/VBox/StatsBox/PrizesHBox/PrizesVal
@onready var best_score_label: Label = $Panel/Margin/VBox/StatsBox/BestHBox/BestVal
@onready var new_record_badge: Label = $Panel/Margin/VBox/ScoreBox/NewRecordBadge

func _ready() -> void:
	visible = false
	GameManager.state_changed.connect(_on_state_changed)

func _on_state_changed(state: GameManager.GameState) -> void:
	if state == GameManager.GameState.RESULTS:
		show_results()
	else:
		visible = false

func show_results() -> void:
	visible = true
	final_score_label.text = str(GameManager.current_score)
	prizes_count_label.text = str(GameManager.prizes_won_count)
	best_score_label.text = str(GameManager.high_score)
	
	var is_new_record: bool = (GameManager.current_score >= GameManager.high_score and GameManager.current_score > 0)
	if new_record_badge:
		new_record_badge.visible = is_new_record
	
	# Scale animation for victory presentation
	$Panel.scale = Vector2(0.8, 0.8)
	var tw: Tween = create_tween()
	tw.tween_property($Panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_play_again_pressed() -> void:
	visible = false
	GameManager.start_game_round(GameManager.round_duration)

func _on_main_menu_pressed() -> void:
	visible = false
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
