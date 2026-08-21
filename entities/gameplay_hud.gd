extends CanvasLayer

@export_multiline var tutorial_text := "J RESGATA  •  E ATACA"

@onready var hearts: Array[TextureRect] = [
	$SafeArea/TopBar/HealthPanel/Padding/Hearts/Heart1,
	$SafeArea/TopBar/HealthPanel/Padding/Hearts/Heart2,
	$SafeArea/TopBar/HealthPanel/Padding/Hearts/Heart3,
]
@onready var score_label: Label = $SafeArea/TopBar/ScorePanel/Padding/Score
@onready var rescue_label: Label = $SafeArea/TopBar/RescuePanel/Padding/Rescues
@onready var tutorial_label: Label = $SafeArea/TopBar/TutorialPanel/Padding/Tutorial

const HEART_FULL := preload("res://sprites/hud/heart_full.png")
const HEART_EMPTY := preload("res://sprites/hud/heart_empty.png")


func _ready() -> void:
	HealthManager.lives_changed.connect(_on_lives_changed)
	ScoreManager.score_changed.connect(_on_score_changed)
	RescueManager.rescue_count_changed.connect(_on_rescue_count_changed)

	tutorial_label.text = tutorial_text
	_on_lives_changed(HealthManager.current_lives, HealthManager.MAX_LIVES)
	_on_score_changed(ScoreManager.current_score)
	_on_rescue_count_changed(RescueManager.get_rescue_count(), RescueManager.TOTAL_ANIMALS)


func _on_lives_changed(current: int, _maximum: int) -> void:
	for index in hearts.size():
		hearts[index].texture = HEART_FULL if index < current else HEART_EMPTY


func _on_score_changed(value: int) -> void:
	score_label.text = "PONTOS %06d" % value


func _on_rescue_count_changed(current: int, total: int) -> void:
	rescue_label.text = "RESGATES %d/%d" % [current, total]
