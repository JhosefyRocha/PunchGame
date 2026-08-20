extends Area2D

@onready var visual: Node2D = $Visual
@onready var count_label: Label = $CountLabel

var completed := false


func _ready() -> void:
	RescueManager.rescue_count_changed.connect(_update_rescued_group)
	_update_rescued_group(RescueManager.get_rescue_count(), RescueManager.TOTAL_ANIMALS)


func _update_rescued_group(current: int, _total: int) -> void:
	count_label.text = "%d RESGATADOS" % current
	var fullness := clampf(float(current) / float(RescueManager.TOTAL_ANIMALS), 0.0, 1.0)
	visual.scale = Vector2.ONE * lerpf(0.72, 1.0, fullness)
	visual.modulate = Color(0.72, 0.72, 0.72, 0.72) if current == 0 else Color.WHITE


func _on_body_entered(body: Node2D) -> void:
	if completed or not body.has_method(&"die"):
		return

	completed = true
	monitoring = false
	body.set_physics_process(false)
	get_tree().call_group(&"game_complete_menu", &"show_victory")
