@tool
extends Node2D
class_name LevelBounds

## Delimita a area jogavel de uma fase. Resolve tres coisas de uma vez:
##
## 1. Limites da `Camera2D` do jogador -- a camera da `player.tscn` nao define
##    `limit_right`, entao sem isto ela rola ate o infinito a direita.
## 2. Paredes invisiveis nas bordas -- limite de camera segura a VISAO, nao o
##    corpo; sem parede o jogador continua andando para fora do mapa.
## 3. Uma faixa de queda no fundo -- cair em um vao sem agua custa uma vida em
##    vez de despencar para sempre.
##
## Coloque um no destes por fase e ajuste `bounds` para cobrir o cenario.

## Retangulo jogavel em coordenadas globais. A altura deve ser >= a altura da
## viewport (208 px neste projeto), senao o intervalo vertical da camera fica
## degenerado e o enquadramento salta.
@export var bounds := Rect2(0.0, 0.0, 1280.0, 208.0):
	set(value):
		bounds = value
		queue_redraw()

@export var wall_thickness := 16.0
## Quanto abaixo de `bounds` a faixa de queda fica, e quanto as paredes se
## estendem acima/abaixo para nao deixar brecha nos cantos.
@export var fall_margin := 48.0
@export var build_walls := true
@export var build_fall_catch := true

const WORLD_LAYER := 1
const PLAYER_LAYER := 4


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return

	if build_walls:
		_build_wall(bounds.position.x - wall_thickness * 0.5)
		_build_wall(bounds.end.x + wall_thickness * 0.5)
	if build_fall_catch:
		_build_fall_catch()

	# O jogador entra no grupo "player" no proprio `_ready()`, e ele nem sempre
	# vem antes deste no na arvore (a fase 1 chama o no de "CharacterBody2D", a
	# fase 2 de "Player"). Adiar tira a ordem da equacao.
	_apply_camera_limits.call_deferred()


func _apply_camera_limits() -> void:
	var camera := _find_player_camera()
	if camera == null:
		push_warning("LevelBounds: nenhuma Camera2D encontrada no jogador; limites nao aplicados.")
		return

	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.reset_smoothing()


func _find_player_camera() -> Camera2D:
	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		return null
	for child in player.get_children():
		if child is Camera2D:
			return child
	return null


func _build_wall(center_x: float) -> void:
	var height := bounds.size.y + fall_margin * 2.0
	var wall := StaticBody2D.new()
	wall.name = "BoundsWall"
	wall.collision_layer = WORLD_LAYER
	wall.collision_mask = 0
	wall.global_position = Vector2(center_x, bounds.position.y + bounds.size.y * 0.5)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(wall_thickness, height)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)


func _build_fall_catch() -> void:
	var catcher := Area2D.new()
	catcher.name = "FallCatch"
	catcher.collision_layer = 0
	catcher.collision_mask = PLAYER_LAYER
	catcher.monitorable = false
	catcher.global_position = Vector2(
		bounds.position.x + bounds.size.x * 0.5,
		bounds.end.y + fall_margin
	)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(bounds.size.x + wall_thickness * 2.0, 32.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	catcher.add_child(collision)
	catcher.body_entered.connect(_on_fall_catch_body_entered)
	add_child(catcher)


func _on_fall_catch_body_entered(body: Node2D) -> void:
	if body.has_method(&"take_damage"):
		body.take_damage()
	elif body.has_method(&"die"):
		body.die()


func _draw() -> void:
	# Guia so de editor: mostra o retangulo jogavel para posicionar o cenario.
	if not Engine.is_editor_hint():
		return
	var local := Rect2(bounds.position - global_position, bounds.size)
	draw_rect(local, Color(0.35, 0.9, 0.55, 0.85), false, 2.0)
