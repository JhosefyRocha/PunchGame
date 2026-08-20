extends CanvasLayer

const HEART_FULL := preload("res://sprites/hud/heart_full.png")
const HEART_EMPTY := preload("res://sprites/hud/heart_empty.png")

@onready var hearts: Array[Sprite2D] = [$HeartPanel/Heart1, $HeartPanel/Heart2, $HeartPanel/Heart3]


func _ready() -> void:
	HealthManager.lives_changed.connect(_on_lives_changed)
	_on_lives_changed(HealthManager.current_lives, HealthManager.MAX_LIVES)


func _on_lives_changed(current: int, _maximum: int) -> void:
	for index in hearts.size():
		hearts[index].texture = HEART_FULL if index < current else HEART_EMPTY
