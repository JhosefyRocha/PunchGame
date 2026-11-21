extends Node

signal score_changed(current_score: int)

var current_score := 0
var enemies_defeated := 0
var seeds_collected := 0
var phase_start_enemies := 0
var phase_start_seeds := 0
var fires_put_out := 0
var phase_start_fires := 0


func register_enemy_defeat() -> void:
	enemies_defeated += 1
	if enemies_defeated == 10:
		SaveManager.unlock(&"inimigos_10")


func register_seed() -> void:
	seeds_collected += 1


func register_fire_put_out() -> void:
	fires_put_out += 1


func mark_phase_counts() -> void:
	phase_start_enemies = enemies_defeated
	phase_start_seeds = seeds_collected
	phase_start_fires = fires_put_out


func restore_phase_counts() -> void:
	enemies_defeated = phase_start_enemies
	seeds_collected = phase_start_seeds
	fires_put_out = phase_start_fires


func get_phase_fires() -> int:
	return fires_put_out - phase_start_fires


func get_phase_enemies() -> int:
	return enemies_defeated - phase_start_enemies


func get_phase_seeds() -> int:
	return seeds_collected - phase_start_seeds


func add_points(amount: int) -> int:
	if amount <= 0:
		return current_score

	current_score += amount
	score_changed.emit(current_score)
	return current_score


func set_score(value: int) -> void:
	current_score = maxi(value, 0)
	score_changed.emit(current_score)


## Ponto unico de reinicio do autoload. Veja `GameMenu.reset_run_state()`.
func reset_game_state() -> void:
	current_score = 0
	enemies_defeated = 0
	seeds_collected = 0
	phase_start_enemies = 0
	phase_start_seeds = 0
	fires_put_out = 0
	phase_start_fires = 0
	score_changed.emit(current_score)

