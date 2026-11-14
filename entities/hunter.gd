extends Lumberjack

const DART_SCENE := preload("res://entities/dart.tscn")

@export var dart_speed := 120.0
@export var muzzle_offset := Vector2(12, 2)


func apply_axe_damage() -> void:
	var dart := DART_SCENE.instantiate()
	dart.direction = move_direction
	dart.speed = dart_speed
	get_parent().add_child(dart)
	dart.global_position = global_position + Vector2(muzzle_offset.x * move_direction, muzzle_offset.y)
