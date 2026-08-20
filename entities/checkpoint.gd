extends Area2D
class_name Checkpoint

signal activated(checkpoint: Checkpoint)

@export var respawn_offset := Vector2(0.0, -12.0)
@export var one_shot := true

@onready var flag_visual: Node2D = $FlagVisual

var is_active := false


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player") or not body.has_method(&"set_checkpoint"):
		return
	if one_shot and is_active:
		return

	is_active = true
	body.set_checkpoint(global_position + respawn_offset)
	flag_visual.modulate = Color(0.45, 1.0, 0.38, 1.0)
	activated.emit(self)
