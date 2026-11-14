extends Node2D

@export var bar_width := 20.0
@export var bar_height := 2.0
@export var fill_color := Color(0.9, 0.22, 0.16, 1.0)
@export var back_color := Color(0.08, 0.05, 0.04, 1.0)

@onready var enemy: Node = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var maximum: int = enemy.max_health
	var current: int = enemy.current_health
	if maximum <= 0 or current <= 0:
		return
	var back := Rect2(-bar_width * 0.5 - 1.0, -1.0, bar_width + 2.0, bar_height + 2.0)
	draw_rect(back, back_color)
	draw_rect(Rect2(-bar_width * 0.5, 0.0, bar_width * float(current) / float(maximum), bar_height), fill_color)
