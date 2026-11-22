extends Area2D

@export var boss_path: NodePath

@onready var visual: Node2D = $Visual

var boss: Node


func _ready() -> void:
	boss = get_node_or_null(boss_path)
	if boss == null or RescueManager.plush_recovered:
		queue_free()
		return
	visible = false
	set_deferred(&"monitoring", false)
	boss.defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)


func _on_boss_defeated(_points: int) -> void:
	visible = true
	monitoring = true
	var bob := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(visual, "position:y", -2.0, 0.6)
	bob.tween_property(visual, "position:y", 2.0, 0.6)


func _on_body_entered(body: Node2D) -> void:
	if RescueManager.plush_recovered or not body.is_in_group(&"player"):
		return
	RescueManager.recover_plush()
	set_deferred(&"monitoring", false)
	queue_free()
