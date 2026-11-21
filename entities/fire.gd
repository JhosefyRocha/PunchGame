extends Area2D

const EXTINGUISH_SCORE := 150
const FireQuiz := preload("res://entities/fire_quiz.gd")

@onready var flames: Node2D = $Flames
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var quiz_zone: Area2D = $QuizZone

var is_out := false
var quiz_open := false


func _ready() -> void:
	add_to_group(&"fires")
	quiz_zone.body_entered.connect(_on_quiz_zone_body_entered)
	quiz_zone.body_exited.connect(_on_quiz_zone_body_exited)
	var flicker := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flicker.tween_property(flames, "scale", Vector2(1.08, 0.9), 0.22)
	flicker.tween_property(flames, "scale", Vector2.ONE, 0.22)


func _on_body_entered(body: Node2D) -> void:
	if is_out:
		return
	if body.has_method(&"take_damage"):
		body.take_damage()
	elif body.has_method(&"die"):
		body.die()


func _on_quiz_zone_body_entered(body: Node2D) -> void:
	if is_out or quiz_open or not body.is_in_group(&"player"):
		return
	quiz_open = true
	get_tree().paused = true
	var quiz := FireQuiz.new()
	quiz.finished.connect(_on_quiz_finished)
	get_tree().current_scene.add_child(quiz)


func _on_quiz_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		quiz_open = false


func _on_quiz_finished(correct: bool) -> void:
	get_tree().paused = false
	if correct:
		_extinguish()


func take_damage(_amount: int = 1, _source_position: Vector2 = Vector2.INF) -> void:
	_extinguish()


func _extinguish() -> void:
	if is_out:
		return
	is_out = true
	ScoreManager.add_points(EXTINGUISH_SCORE)
	ScoreManager.register_fire_put_out()
	SaveManager.unlock(&"primeiro_incendio")
	remove_from_group(&"fires")
	set_deferred(&"monitoring", false)
	quiz_zone.set_deferred(&"monitoring", false)
	collision.set_deferred(&"disabled", true)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(flames, "scale", Vector2(1.4, 0.2), 0.35)
	tween.tween_property(flames, "modulate:a", 0.0, 0.35)
	await tween.finished
	queue_free()
