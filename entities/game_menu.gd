extends CanvasLayer

class_name GameMenu

static var start_after_reload := false

@onready var death_tint: ColorRect = $Overlay/DeathTint
@onready var menu_panel: PanelContainer = $Overlay/Center/MenuPanel
@onready var controls_panel: PanelContainer = $Overlay/Center/ControlsPanel
@onready var credits_panel: PanelContainer = $Overlay/Center/CreditsPanel
@onready var death_panel: PanelContainer = $Overlay/Center/DeathPanel
@onready var start_button: Button = $Overlay/Center/MenuPanel/Margin/VBox/StartButton

var is_death_screen := false
var completion_locked := false
var run_was_started := false


func _ready() -> void:
	add_to_group(&"game_menu")
	if start_after_reload:
		start_after_reload = false
		run_was_started = true
		start_game()
	else:
		show_menu()


func _unhandled_input(event: InputEvent) -> void:
	if completion_locked:
		return

	if event.is_action_pressed("ui_cancel"):
		if is_death_screen:
			return

		if controls_panel.visible or credits_panel.visible:
			show_main_panel()
		elif get_tree().paused:
			start_game()
		else:
			show_menu()

		get_viewport().set_input_as_handled()


func show_menu() -> void:
	is_death_screen = false
	get_tree().paused = true
	show()
	death_tint.hide()
	show_main_panel()
	start_button.grab_focus()


func start_game() -> void:
	hide()
	get_tree().paused = false


func show_main_panel() -> void:
	menu_panel.show()
	controls_panel.hide()
	credits_panel.hide()
	death_panel.hide()


func show_controls() -> void:
	menu_panel.hide()
	controls_panel.show()
	credits_panel.hide()
	death_panel.hide()
	$Overlay/Center/ControlsPanel/Margin/VBox/BackButton.grab_focus()


func show_credits() -> void:
	menu_panel.hide()
	controls_panel.hide()
	credits_panel.show()
	death_panel.hide()
	$Overlay/Center/CreditsPanel/Margin/VBox/BackButton.grab_focus()


func restart_game() -> void:
	HealthManager.reset_lives()
	start_after_reload = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func show_death_screen() -> void:
	is_death_screen = true
	get_tree().paused = true
	show()
	death_tint.show()
	menu_panel.hide()
	controls_panel.hide()
	credits_panel.hide()
	death_panel.show()
	$Overlay/Center/DeathPanel/Margin/VBox/RestartButton.grab_focus()


func lock_for_level_complete() -> void:
	completion_locked = true
	hide()


func return_to_menu() -> void:
	HealthManager.reset_lives()
	start_after_reload = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_start_button_pressed() -> void:
	if not run_was_started and get_tree().current_scene.scene_file_path == "res://PrimeiraCena.tscn":
		RescueManager.reset_run()
		HealthManager.reset_lives()
		ScoreManager.reset_score()
	run_was_started = true
	start_game()


func _on_controls_button_pressed() -> void:
	show_controls()


func _on_restart_button_pressed() -> void:
	restart_game()


func _on_credits_button_pressed() -> void:
	show_credits()


func _on_back_button_pressed() -> void:
	show_main_panel()
	start_button.grab_focus()


func _on_death_restart_button_pressed() -> void:
	restart_game()


func _on_death_menu_button_pressed() -> void:
	return_to_menu()
