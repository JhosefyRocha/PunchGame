@tool
extends Area2D

## Deixe vazio para usar a arte procedural desenhada na cena. Ao atribuir um PNG
## aqui, as estacas procedurais somem sozinhas -- nenhuma mudanca de codigo.
@export var art_texture: Texture2D:
	set(value):
		art_texture = value
		if is_node_ready():
			apply_art()

@onready var procedural_art: Node2D = $ProceduralArt
@onready var art_override: Sprite2D = $ArtOverride


func _ready() -> void:
	apply_art()


func apply_art() -> void:
	var has_texture := art_texture != null
	art_override.texture = art_texture
	art_override.visible = has_texture
	procedural_art.visible = not has_texture


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"take_damage"):
		body.take_damage()
	elif body.has_method(&"die"):
		body.die()
