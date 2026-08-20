extends Node

signal score_changed(current_score: int)

var current_score := 0


func add_points(amount: int) -> int:
	if amount <= 0:
		return current_score

	current_score += amount
	score_changed.emit(current_score)
	return current_score


func reset_score() -> void:
	current_score = 0
	score_changed.emit(current_score)
