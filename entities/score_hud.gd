extends CanvasLayer

@onready var score_label: Label = $Margin/Panel/Margin/ScoreLabel


func _ready() -> void:
	ScoreManager.score_changed.connect(update_score)
	update_score(ScoreManager.current_score)


func update_score(value: int) -> void:
	score_label.text = "PONTOS  %06d" % value
