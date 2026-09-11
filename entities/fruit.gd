@tool
extends Area2D
class_name HealingFruit

@export var heal_amount := 1
@export var score_reward := 25
## Com `false`, encostar na fruta com 3/3 coracoes nao a consome -- ela fica no
## mapa para quando fizer falta. Regra descrita em AUDITORIA_GDD.md 4.4.
@export var consume_at_full_health := false

## Deixe vazio para usar a arte procedural desenhada na cena. Ao atribuir um PNG
## aqui, a maca procedural some sozinha -- nenhuma mudanca de codigo.
@export var art_texture: Texture2D:
	set(value):
		art_texture = value
		if is_node_ready():
			apply_art()

@onready var art_root: Node2D = $Art
@onready var procedural_art: Node2D = $Art/ProceduralArt
@onready var art_override: Sprite2D = $Art/ArtOverride

var was_collected := false


func _ready() -> void:
	apply_art()
	if Engine.is_editor_hint():
		return

	# Balanco de repouso: e o que faz a fruta ler como item coletavel em vez de
	# cenario. Um tween por fruta, duas por fase.
	var bob := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(art_root, "position:y", -1.5, 0.6)
	bob.tween_property(art_root, "position:y", 1.5, 0.6)


func apply_art() -> void:
	var has_texture := art_texture != null
	art_override.texture = art_texture
	art_override.visible = has_texture
	procedural_art.visible = not has_texture


func _on_body_entered(body: Node2D) -> void:
	if was_collected or not body.is_in_group(&"player"):
		return
	if HealthManager.is_full_health() and not consume_at_full_health:
		return

	was_collected = true
	monitoring = false
	HealthManager.heal(heal_amount)
	ScoreManager.add_points(score_reward)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.35, 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	await tween.finished
	queue_free()
