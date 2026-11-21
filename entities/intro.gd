extends Control

@onready var continue_button: Button = $Overlay/Center/Panel/Margin/VBox/ContinueButton


func _ready() -> void:
	continue_button.grab_focus()


func _on_continue_button_pressed() -> void:
	GameMenu.reset_run_state()
	GameMenu.start_after_reload = true
	get_tree().change_scene_to_file(GameMenu.FIRST_SCENE)
