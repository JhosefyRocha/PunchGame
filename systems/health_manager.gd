extends Node

signal lives_changed(current: int, maximum: int)

const MAX_LIVES := 3

var current_lives := MAX_LIVES


func lose_life(amount: int = 1) -> int:
	current_lives = maxi(0, current_lives - maxi(amount, 0))
	lives_changed.emit(current_lives, MAX_LIVES)
	return current_lives


func heal(amount: int = 1) -> int:
	var previous_lives := current_lives
	current_lives = mini(MAX_LIVES, current_lives + maxi(amount, 0))
	if current_lives != previous_lives:
		lives_changed.emit(current_lives, MAX_LIVES)
	return current_lives


func is_full_health() -> bool:
	return current_lives >= MAX_LIVES


func reset_lives() -> void:
	current_lives = MAX_LIVES
	lives_changed.emit(current_lives, MAX_LIVES)
