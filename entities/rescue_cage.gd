extends Area2D

@export var rescue_id: StringName
@export var animal_kind: StringName = &"animal"
@export var reward_points := 0

@onready var visual: Node2D = $Visual
@onready var interaction_hint: Label = $InteractionHint
@onready var collision: CollisionShape2D = $CollisionShape2D

var player_nearby := false
var is_opening := false


func _ready() -> void:
	add_to_group(&"rescue_cage")
	interaction_hint.hide()
	if RescueManager.is_rescued(rescue_id):
		queue_free()


func _process(_delta: float) -> void:
	if player_nearby and not is_opening and Input.is_action_just_pressed(&"interact"):
		free_animal()


func free_animal() -> void:
	if not RescueManager.rescue_animal(rescue_id, animal_kind):
		return

	ScoreManager.add_points(reward_points)
	_spawn_celebration()
	is_opening = true
	player_nearby = false
	monitoring = false
	collision.set_deferred(&"disabled", true)
	interaction_hint.hide()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual, "scale", Vector2(1.22, 0.72), 0.08).set_trans(Tween.TRANS_BACK)
	tween.tween_property(visual, "modulate:a", 0.0, 0.2).set_delay(0.04)
	await tween.finished
	queue_free()


func _spawn_celebration() -> void:
	var burst := CPUParticles2D.new()
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 24
	burst.lifetime = 1.0
	burst.direction = Vector2.UP
	burst.spread = 75.0
	burst.initial_velocity_min = 45.0
	burst.initial_velocity_max = 110.0
	burst.gravity = Vector2(0.0, 140.0)
	burst.scale_amount_min = 1.5
	burst.scale_amount_max = 2.5
	burst.color = Color(0.62, 0.95, 0.36, 1.0)
	burst.global_position = global_position + Vector2(0.0, -10.0)
	get_tree().current_scene.add_child(burst)
	burst.emitting = true
	get_tree().create_timer(1.6).timeout.connect(burst.queue_free)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"die"):
		player_nearby = true
		interaction_hint.show()


func _on_body_exited(body: Node2D) -> void:
	if body.has_method(&"die"):
		player_nearby = false
		interaction_hint.hide()
