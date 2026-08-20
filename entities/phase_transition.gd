extends CanvasLayer

@export var fade_color := Color(0.025, 0.055, 0.035, 1.0)
@export_range(0.1, 2.0, 0.05) var fade_duration := 0.45

@onready var veil: ColorRect = $Veil


func _ready() -> void:
	add_to_group(&"phase_transition")
	veil.color = fade_color
	veil.modulate.a = 1.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(veil, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func transition_to(scene_path: String) -> void:
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(veil, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
