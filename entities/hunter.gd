extends Lumberjack

const DART_SCENE := preload("res://entities/dart.tscn")

@export var dart_speed := 120.0
@export var muzzle_offset := Vector2(12, 2)
@export var aim_at_player := false


func apply_axe_damage() -> void:
	var muzzle := global_position + Vector2(muzzle_offset.x * move_direction, muzzle_offset.y)
	var travel := Vector2(move_direction, 0.0)
	if aim_at_player:
		var target := find_target()
		if target != null:
			travel = (target.global_position - muzzle).normalized()
	var dart := DART_SCENE.instantiate()
	dart.velocity = travel * dart_speed
	get_parent().add_child(dart)
	dart.global_position = muzzle
