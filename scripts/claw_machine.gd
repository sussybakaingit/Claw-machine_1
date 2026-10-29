extends Node3D
class_name ClawMachine

@onready var chute_area: Area3D = $ChuteArea
@onready var confetti_particles: GPUParticles3D = $ConfettiParticles
@onready var prize_spawner: PrizeSpawner = $PrizeSpawner
@onready var claw_controller: ClawController = $Claw
@onready var chute_light: OmniLight3D = $ChuteLight

func _ready() -> void:
	if chute_area:
		chute_area.body_entered.connect(_on_chute_body_entered)
	GameManager.prize_scored.connect(_on_prize_scored)

func _on_chute_body_entered(body: Node3D) -> void:
	if body is Prize:
		var prize: Prize = body as Prize
		prize.collect()

func _on_prize_scored(points: int, world_pos: Vector3) -> void:
	# Trigger confetti burst
	if confetti_particles:
		confetti_particles.restart()
		confetti_particles.emitting = true
	
	# Flash chute light
	if chute_light:
		var tw: Tween = create_tween()
		chute_light.light_energy = 3.5
		tw.tween_property(chute_light, "light_energy", 0.8, 0.6)
	
	# Spawn floating score 3D billboard
	spawn_floating_score(points, world_pos if world_pos != Vector3.ZERO else Vector3(-0.65, 0.8, 0.55))

func spawn_floating_score(points: int, spawn_pos: Vector3) -> void:
	var label: Label3D = Label3D.new()
	label.text = "+%d" % points
	label.font_size = 48
	label.modulate = Color(1.0, 0.9, 0.2, 1.0) if points >= 50 else (Color(0.2, 0.9, 1.0, 1.0) if points >= 20 else Color(0.3, 1.0, 0.4, 1.0))
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	label.global_position = spawn_pos + Vector3(0, 0.2, 0)
	
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y + 0.6, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(label.queue_free)
