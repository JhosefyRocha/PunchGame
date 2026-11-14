extends Area2D

const LOCKED_TINT := Color(0.45, 0.45, 0.45, 1.0)

@export_file("*.tscn") var next_scene := "res://scene/phase_2.tscn"
@export var guardian_path: NodePath

@onready var guardian_hint: Label = $GuardianHint
@onready var banner: Node2D = $Banner
@onready var mark: Node2D = $Mark

var was_reached := false
var guardian: Node


func _ready() -> void:
	guardian_hint.hide()
	guardian = get_node_or_null(guardian_path)
	if guardian != null:
		banner.modulate = LOCKED_TINT
		mark.modulate = LOCKED_TINT
		guardian.defeated.connect(_on_guardian_defeated, CONNECT_ONE_SHOT)


func _on_body_entered(body: Node2D) -> void:
	if was_reached or not body.is_in_group(&"player"):
		return
	if guardian != null:
		guardian_hint.show()
		return
	reach()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		guardian_hint.hide()


func reach() -> void:
	was_reached = true
	set_deferred(&"monitoring", false)
	get_tree().call_group(&"level_complete_menu", &"show_level_complete", next_scene)


func _on_guardian_defeated(_points: int) -> void:
	guardian = null
	guardian_hint.hide()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(banner, "modulate", Color.WHITE, 0.4)
	tween.tween_property(mark, "modulate", Color.WHITE, 0.4)
	for body in get_overlapping_bodies():
		if body.is_in_group(&"player"):
			reach()
			return
