extends StaticBody2D

signal sacks_opened

@export var boss_path: NodePath

@onready var body: Node2D = $Body
@onready var cages: Node2D = $Body/Cages
@onready var exhaust: CPUParticles2D = $Exhaust
@onready var rescue_zone: Area2D = $RescueZone
@onready var interaction_hint: Label = $InteractionHint

var engine_tween: Tween
var can_rescue := false
var player_nearby := false


func _ready() -> void:
	interaction_hint.hide()
	rescue_zone.body_entered.connect(_on_rescue_zone_body_entered)
	rescue_zone.body_exited.connect(_on_rescue_zone_body_exited)
	engine_tween = create_tween().set_loops()
	engine_tween.tween_property(body, "position:y", -1.0, 0.09)
	engine_tween.tween_property(body, "position:y", 0.0, 0.09)
	var boss := get_node_or_null(boss_path)
	if boss != null:
		boss.defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)


func _process(_delta: float) -> void:
	if can_rescue and player_nearby and Input.is_action_just_pressed(&"interact"):
		_open_sacks()


func _on_boss_defeated(_points: int) -> void:
	engine_tween.kill()
	body.position.y = 0.0
	exhaust.emitting = false
	can_rescue = true
	_update_hint()


func _on_rescue_zone_body_entered(node: Node2D) -> void:
	if node.is_in_group(&"player"):
		player_nearby = true
		_update_hint()


func _on_rescue_zone_body_exited(node: Node2D) -> void:
	if node.is_in_group(&"player"):
		player_nearby = false
		_update_hint()


func _update_hint() -> void:
	interaction_hint.text = OS.get_keycode_string(SettingsManager.get_key(&"interact"))
	interaction_hint.visible = can_rescue and player_nearby


func _open_sacks() -> void:
	can_rescue = false
	_update_hint()
	rescue_zone.set_deferred(&"monitoring", false)
	for cage in cages.get_children():
		var tween := create_tween().set_parallel(true)
		tween.tween_property(cage, "scale", cage.scale * Vector2(1.3, 0.6), 0.15)
		tween.tween_property(cage, "modulate:a", 0.0, 0.35)
	sacks_opened.emit()
