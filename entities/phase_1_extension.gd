@tool
extends TileMapLayer

@export var first_tile := 78
@export var last_tile := 219


func _ready() -> void:
	# A extensão fica no próprio TileMapLayer, portanto aparece também no editor.
	for x in range(first_tile, last_tile + 1):
		set_cell(Vector2i(x, 4), 1, Vector2i(4, 1))
		set_cell(Vector2i(x, 5), 1, Vector2i(4, 3))
