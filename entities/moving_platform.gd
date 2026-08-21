@tool
extends AnimatableBody2D

@export var platform_size := Vector2(56, 16):
	set(value):
		platform_size = value
		refresh_shape()
@export var movement := Vector2(0, -44)
@export_range(0.5, 10.0, 0.1) var travel_time := 2.0

const AUTUMN_TEXTURE := preload("res://sprites/Seasonal Tilesets/Seasonal Tilesets/2 - Autumn Forest/Terrain (16 x 16).png")


func _ready() -> void:
	refresh_shape()
	if Engine.is_editor_hint():
		return

	var origin := position
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", origin + movement, travel_time)
	tween.tween_property(self, "position", origin, travel_time)


func refresh_shape() -> void:
	if not is_node_ready():
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = platform_size
	$CollisionShape2D.position = platform_size * 0.5
	$CollisionShape2D.shape = rectangle
	queue_redraw()


func _draw() -> void:
	var columns := ceili(platform_size.x / 16.0)
	for column in range(columns):
		var atlas_column := 4
		if column == 0:
			atlas_column = 3
		elif column == columns - 1:
			atlas_column = 5
		draw_texture_rect_region(
			AUTUMN_TEXTURE,
			Rect2(column * 16, 0, 16, 16),
			Rect2(atlas_column * 16, 16, 16, 16)
		)
