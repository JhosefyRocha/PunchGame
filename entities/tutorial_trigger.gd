extends Area2D

@export_multiline var tip := ""

var was_shown := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if was_shown or not body.is_in_group(&"player"):
		return
	was_shown = true
	var hud := get_tree().get_first_node_in_group(&"gameplay_hud")
	if hud != null and hud.has_method(&"show_tip"):
		hud.show_tip(tip)
