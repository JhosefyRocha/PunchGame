extends Node

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "progress"
const UNLOCKED_KEY := "unlocked_levels"

const LEVELS: Array[Dictionary] = [
	{
		"title": "Fase 1",
		"scene": "res://scene/phase_1.tscn",
		"thumbnail": "res://sprites/environment/forest_canopy_fire.png",
	},
	{
		"title": "Fase 2",
		"scene": "res://scene/phase_2.tscn",
		"thumbnail": "res://sprites/environment/forest_canopy_orange.png",
	},
	{
		"title": "Fase 3",
		"scene": "res://scene/phase_3.tscn",
		"thumbnail": "res://sprites/environment/forest_canopy_phase_1.png",
	},
	{
		"title": "Fase 4",
		"scene": "res://scene/phase_4.tscn",
		"thumbnail": "res://sprites/environment/forest_canopy_dead_green.png",
	},
	{
		"title": "Fase 5",
		"scene": "res://scene/phase_5.tscn",
		"thumbnail": "res://sprites/environment/forest_canopy_phase_2.png",
	},
]

var has_save := false
var unlocked_levels := 1


func _ready() -> void:
	load_progress()


func get_level_count() -> int:
	return LEVELS.size()


func get_unlocked_count() -> int:
	return clampi(unlocked_levels, 1, LEVELS.size())


func is_level_unlocked(index: int) -> bool:
	return index >= 0 and index < get_unlocked_count()


func is_level_completed(index: int) -> bool:
	return index >= 0 and index < LEVELS.size() and index < unlocked_levels - 1


func has_progress() -> bool:
	return has_save and unlocked_levels > 1


func get_level_index(scene_path: String) -> int:
	for index in LEVELS.size():
		if LEVELS[index]["scene"] == scene_path:
			return index
	return -1


func start_new_game() -> void:
	has_save = true
	unlocked_levels = 1
	save_progress()


func complete_level(index: int) -> int:
	if index < 0 or index >= LEVELS.size():
		return -1

	var was_unlocked := unlocked_levels
	has_save = true
	unlocked_levels = maxi(unlocked_levels, index + 2)
	save_progress()

	var next_index := index + 1
	if unlocked_levels > was_unlocked and next_index < LEVELS.size():
		return next_index
	return -1


func complete_current_level() -> int:
	var scene := get_tree().current_scene
	if scene == null:
		return -1
	return complete_level(get_level_index(scene.scene_file_path))


func load_progress() -> void:
	has_save = false
	unlocked_levels = 1

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	if not config.has_section_key(SAVE_SECTION, UNLOCKED_KEY):
		return

	has_save = true
	var stored: Variant = config.get_value(SAVE_SECTION, UNLOCKED_KEY)
	if stored is int or stored is float:
		unlocked_levels = maxi(1, int(stored))


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, UNLOCKED_KEY, unlocked_levels)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("SaveManager: nao foi possivel gravar %s (erro %d)." % [SAVE_PATH, error])
