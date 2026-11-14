extends Area2D

@export var guardian_path: NodePath

@onready var visual: Node2D = $Visual
@onready var count_label: Label = $CountLabel
@onready var guardian_hint: Label = $GuardianHint

var completed := false
var guardian: Node


func _ready() -> void:
	guardian_hint.hide()
	RescueManager.rescue_count_changed.connect(_update_rescued_group)
	_update_rescued_group(RescueManager.get_rescue_count(), RescueManager.TOTAL_ANIMALS)
	guardian = get_node_or_null(guardian_path)
	if guardian != null:
		guardian.defeated.connect(_on_guardian_defeated, CONNECT_ONE_SHOT)


func _update_rescued_group(current: int, _total: int) -> void:
	count_label.text = "%d RESGATADOS" % current
	var fullness := clampf(float(current) / float(RescueManager.TOTAL_ANIMALS), 0.0, 1.0)
	visual.scale = Vector2.ONE * lerpf(0.72, 1.0, fullness)
	visual.modulate = Color(0.72, 0.72, 0.72, 0.72) if current == 0 else Color.WHITE


func _on_body_entered(body: Node2D) -> void:
	if completed or not body.has_method(&"die"):
		return
	if guardian != null:
		guardian_hint.show()
		return
	complete(body)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method(&"die"):
		guardian_hint.hide()


func complete(body: Node2D) -> void:
	completed = true
	set_deferred(&"monitoring", false)
	body.set_physics_process(false)
	get_tree().call_group(&"game_complete_menu", &"show_victory")


func _on_guardian_defeated(_points: int) -> void:
	guardian = null
	guardian_hint.hide()
	for body in get_overlapping_bodies():
		if body.has_method(&"die"):
			complete(body)
			return
