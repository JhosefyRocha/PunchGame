extends Area2D
class_name HealingFruit

@export var heal_amount := 1
@export var score_reward := 25

var was_collected := false


func _on_body_entered(body: Node2D) -> void:
	if was_collected or not body.is_in_group(&"player"):
		return

	was_collected = true
	monitoring = false
	HealthManager.heal(heal_amount)
	ScoreManager.add_points(score_reward)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.35, 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	await tween.finished
	queue_free()
