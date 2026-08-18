extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"enter_vine"):
		body.enter_vine()


func _on_body_exited(body: Node2D) -> void:
	if body.has_method(&"exit_vine"):
		body.exit_vine()
