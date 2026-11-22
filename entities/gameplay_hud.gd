extends CanvasLayer

@onready var hearts: Array[TextureRect] = [
	$SafeArea/TopBar/HealthPanel/Padding/Hearts/Heart1,
	$SafeArea/TopBar/HealthPanel/Padding/Hearts/Heart2,
	$SafeArea/TopBar/HealthPanel/Padding/Hearts/Heart3,
]
@onready var score_label: Label = $SafeArea/TopBar/ScorePanel/Padding/Score
@onready var rescue_label: Label = $SafeArea/TopBar/RescuePanel/Padding/Rescues

const HEART_FULL := preload("res://sprites/hud/heart_full.png")
const HEART_EMPTY := preload("res://sprites/hud/heart_empty.png")
const CAGES_PER_PHASE := 3

var rescue_prefix := ""


func _ready() -> void:
	rescue_prefix = "phase_%d_cage_" % (SaveManager.get_level_index(owner.scene_file_path) + 1)
	HealthManager.lives_changed.connect(_on_lives_changed)
	ScoreManager.score_changed.connect(_on_score_changed)
	RescueManager.rescue_count_changed.connect(_on_rescue_count_changed)

	_on_lives_changed(HealthManager.current_lives, HealthManager.MAX_LIVES)
	_on_score_changed(ScoreManager.current_score)
	_on_rescue_count_changed(RescueManager.get_rescue_count(), RescueManager.TOTAL_ANIMALS)


func _on_lives_changed(current: int, _maximum: int) -> void:
	for index in hearts.size():
		hearts[index].texture = HEART_FULL if index < current else HEART_EMPTY


func _on_score_changed(value: int) -> void:
	score_label.text = "PONTOS %06d" % value


func _on_rescue_count_changed(_current: int, _total: int) -> void:
	rescue_label.text = "RESGATES %d/%d" % [RescueManager.count_rescued(rescue_prefix), CAGES_PER_PHASE]
