extends CanvasLayer

var next_scene_path := "res://scene/phase_2.tscn"


func _ready() -> void:
	add_to_group(&"level_complete_menu")
	hide()


func show_level_complete(scene_path: String) -> void:
	next_scene_path = scene_path
	get_tree().call_group(&"game_menu", &"lock_for_level_complete")
	get_tree().paused = true
	show()
	$Overlay/Center/Panel/Margin/VBox/NextButton.grab_focus()


func _on_next_button_pressed() -> void:
	GameMenu.start_after_reload = true
	var transition := get_tree().get_first_node_in_group(&"phase_transition")
	if transition != null and transition.has_method(&"transition_to"):
		await transition.transition_to(next_scene_path)
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file(next_scene_path)


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	GameMenu.start_after_reload = false
	get_tree().change_scene_to_file("res://PrimeiraCena.tscn")
