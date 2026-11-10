extends PanelContainer

signal back_requested

const LevelCard := preload("res://entities/level_card.gd")
const LEVEL_CARD_SCENE := preload("res://entities/level_card.tscn")

@onready var cards: HBoxContainer = $Margin/VBox/Cards
@onready var hint: Label = $Margin/VBox/Hint
@onready var back_button: Button = $Margin/VBox/BackButton


func _ready() -> void:
	for index in SaveManager.get_level_count():
		var card: LevelCard = LEVEL_CARD_SCENE.instantiate()
		cards.add_child(card)
		card.setup(index)
		card.pressed.connect(_on_card_pressed.bind(index))


func open() -> void:
	for card: LevelCard in cards.get_children():
		card.refresh()
	if SaveManager.get_unlocked_count() < SaveManager.get_level_count():
		hint.text = "Conclua uma fase para liberar a próxima."
	else:
		hint.text = "Todas as fases estão liberadas."
	show()
	link_focus()
	var newest: LevelCard = cards.get_child(SaveManager.get_unlocked_count() - 1)
	newest.grab_focus()


func link_focus() -> void:
	var last := SaveManager.get_unlocked_count() - 1
	for index in last + 1:
		var card: LevelCard = cards.get_child(index)
		card.focus_neighbor_left = card.get_path_to(cards.get_child(maxi(index - 1, 0)))
		card.focus_neighbor_right = card.get_path_to(cards.get_child(mini(index + 1, last)))
		card.focus_neighbor_top = card.get_path_to(card)
		card.focus_neighbor_bottom = card.get_path_to(back_button)
	back_button.focus_neighbor_top = back_button.get_path_to(cards.get_child(last))


func _on_card_pressed(index: int) -> void:
	if not SaveManager.is_level_unlocked(index):
		return

	GameMenu.reset_run_state()
	GameMenu.start_after_reload = true
	get_tree().change_scene_to_file(SaveManager.LEVELS[index]["scene"])


func _on_back_button_pressed() -> void:
	back_requested.emit()
