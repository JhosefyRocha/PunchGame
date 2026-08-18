@tool
extends StaticBody2D

@export var platform_size := Vector2(128, 32)
@export var use_autumn_tiles := false

const GRASS_TEXTURE := preload("res://sprites/Seasonal Tilesets/Seasonal Tilesets/1 - Grassland/Terrain (16 x 16).png")
const AUTUMN_TEXTURE := preload("res://sprites/Seasonal Tilesets/Seasonal Tilesets/2 - Autumn Forest/Terrain (16 x 16).png")


func _ready() -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = platform_size
	$CollisionShape2D.position = platform_size * 0.5
	$CollisionShape2D.shape = rectangle
	queue_redraw()


func _draw() -> void:
	var texture: Texture2D = AUTUMN_TEXTURE if use_autumn_tiles else GRASS_TEXTURE
	var columns := ceili(platform_size.x / 16.0)
	var rows := ceili(platform_size.y / 16.0)

	for row in range(rows):
		for column in range(columns):
			var atlas_column := 4
			if column == 0:
				atlas_column = 3
			elif column == columns - 1:
				atlas_column = 5

			var atlas_row := 1 if row == 0 else 2
			var destination := Rect2(column * 16, row * 16, 16, 16)
			var source := Rect2(atlas_column * 16, atlas_row * 16, 16, 16)
			draw_texture_rect_region(texture, destination, source)
