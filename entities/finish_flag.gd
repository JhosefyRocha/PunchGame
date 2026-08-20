extends Area2D

@export_file("*.tscn") var next_scene := "res://scene/phase_2.tscn"
var was_reached := false


func _on_body_entered(body: Node2D) -> void:
	if was_reached or not body.is_in_group(&"player"):
		return

	was_reached = true
	monitoring = false
	get_tree().call_group(&"level_complete_menu", &"show_level_complete", next_scene)
