extends Node

signal rescue_count_changed(current: int, total: int)

const TOTAL_ANIMALS := 6

var rescued_animals: Dictionary = {}


func rescue_animal(rescue_id: StringName, animal_kind: StringName) -> bool:
	if rescue_id == &"" or rescued_animals.has(rescue_id):
		return false

	rescued_animals[rescue_id] = animal_kind
	rescue_count_changed.emit(get_rescue_count(), TOTAL_ANIMALS)
	return true


func is_rescued(rescue_id: StringName) -> bool:
	return rescued_animals.has(rescue_id)


func get_rescue_count() -> int:
	return rescued_animals.size()


func reset_run() -> void:
	rescued_animals.clear()
	rescue_count_changed.emit(0, TOTAL_ANIMALS)
