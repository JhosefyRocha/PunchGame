extends CanvasLayer

@onready var message: Label = $Overlay/Center/Panel/Margin/VBox/Message


func _ready() -> void:
	add_to_group(&"game_complete_menu")
	hide()


func show_victory() -> void:
	get_tree().call_group(&"game_menu", &"lock_for_level_complete")
	message.text = "%d animais foram libertados!" % RescueManager.get_rescue_count()
	get_tree().paused = true
	show()
	$Overlay/Center/Panel/Margin/VBox/PlayAgainButton.grab_focus()


func _on_play_again_button_pressed() -> void:
	RescueManager.reset_run()
	HealthManager.reset_lives()
	ScoreManager.reset_score()
	GameMenu.start_after_reload = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://PrimeiraCena.tscn")


func _on_menu_button_pressed() -> void:
	RescueManager.reset_run()
	HealthManager.reset_lives()
	ScoreManager.reset_score()
	GameMenu.start_after_reload = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://PrimeiraCena.tscn")
