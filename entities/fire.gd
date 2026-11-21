extends Area2D

const EXTINGUISH_SCORE := 150

@onready var flames: Node2D = $Flames
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var interact_zone: Area2D = $InteractZone
@onready var interaction_hint: Label = $InteractionHint

var is_out := false
var player_nearby := false


func _ready() -> void:
	interaction_hint.hide()
	interact_zone.body_entered.connect(_on_interact_zone_body_entered)
	interact_zone.body_exited.connect(_on_interact_zone_body_exited)
	var flicker := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flicker.tween_property(flames, "scale", Vector2(1.08, 0.9), 0.22)
	flicker.tween_property(flames, "scale", Vector2.ONE, 0.22)


func _process(_delta: float) -> void:
	if player_nearby and not is_out and Input.is_action_just_pressed(&"interact"):
		_extinguish()


func _on_body_entered(body: Node2D) -> void:
	if is_out:
		return
	if body.has_method(&"take_damage"):
		body.take_damage()
	elif body.has_method(&"die"):
		body.die()


func _on_interact_zone_body_entered(body: Node2D) -> void:
	if is_out or not body.is_in_group(&"player"):
		return
	player_nearby = true
	interaction_hint.show()


func _on_interact_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		player_nearby = false
		interaction_hint.hide()


func _extinguish() -> void:
	if is_out:
		return
	is_out = true
	player_nearby = false
	interaction_hint.hide()
	ScoreManager.add_points(EXTINGUISH_SCORE)
	ScoreManager.register_fire_put_out()
	set_deferred(&"monitoring", false)
	interact_zone.set_deferred(&"monitoring", false)
	collision.set_deferred(&"disabled", true)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(flames, "scale", Vector2(1.4, 0.2), 0.35)
	tween.tween_property(flames, "modulate:a", 0.0, 0.35)
	await tween.finished
	queue_free()
