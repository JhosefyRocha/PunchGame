extends Node2D

signal defeated(points_awarded: int)

const OPERATOR_SCENE := preload("res://entities/guardian_lumberjack.tscn")

@export var arena_left := 0.0
@export var arena_right := 0.0
@export var operator_delay := 0.6

@onready var machine: CharacterBody2D = $Machine

var operator: Node


func _ready() -> void:
	machine.arena_left = arena_left
	machine.arena_right = arena_right
	machine.broken.connect(_on_machine_broken, CONNECT_ONE_SHOT)


func _on_machine_broken() -> void:
	await get_tree().create_timer(operator_delay, false).timeout
	operator = OPERATOR_SCENE.instantiate()
	operator.patrol_distance = 40.0
	add_child(operator)
	operator.global_position = machine.global_position + Vector2(0.0, -40.0)
	operator.velocity = Vector2(0.0, -190.0)
	operator.defeated.connect(_on_operator_defeated, CONNECT_ONE_SHOT)


func _on_operator_defeated(points: int) -> void:
	defeated.emit(points)
