extends Control

## Tela inicial do jogo. Os botoes ja estao desenhados na arte de fundo; aqui
## ficam apenas areas clicaveis transparentes posicionadas por cima deles, com
## destaque de hover/foco para o mouse e o teclado.

const LevelSelect := preload("res://entities/level_select.gd")

@onready var background: TextureRect = $Frame/Background
@onready var main_buttons: Control = $Frame/Background/Buttons
@onready var play_button: Button = $Frame/Background/Buttons/PlayButton
@onready var settings_button: Button = $Frame/Background/Buttons/SettingsButton
@onready var settings_overlay: Panel = $SettingsOverlay
@onready var volume_slider: HSlider = $SettingsOverlay/Center/Panel/Margin/VBox/VolumeRow/VolumeSlider
@onready var volume_value: Label = $SettingsOverlay/Center/Panel/Margin/VBox/VolumeRow/VolumeValue
@onready var fullscreen_check: CheckButton = $SettingsOverlay/Center/Panel/Margin/VBox/FullscreenCheck
@onready var play_overlay: Panel = $PlayOverlay
@onready var mode_panel: PanelContainer = $PlayOverlay/Center/ModePanel
@onready var new_game_button: Button = $PlayOverlay/Center/ModePanel/Margin/VBox/NewGameButton
@onready var saved_game_button: Button = $PlayOverlay/Center/ModePanel/Margin/VBox/SavedGameButton
@onready var save_info: Label = $PlayOverlay/Center/ModePanel/Margin/VBox/SaveInfo
@onready var confirm_panel: PanelContainer = $PlayOverlay/Center/ConfirmPanel
@onready var confirm_cancel_button: Button = $PlayOverlay/Center/ConfirmPanel/Margin/VBox/CancelButton
@onready var level_select: LevelSelect = $PlayOverlay/Center/LevelSelect

var previous_scale_aspect := Window.CONTENT_SCALE_ASPECT_KEEP
var background_source: Image
var background_pixel_size := Vector2i.ZERO
var background_refresh_queued := false


func _enter_tree() -> void:
	# O jogo trava a proporcao em 400x208 e cria tarjas nas bordas; o menu usa a
	# janela inteira para a arte ocupar o maximo de pixels reais possivel.
	previous_scale_aspect = get_tree().root.content_scale_aspect
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND


func _exit_tree() -> void:
	get_tree().root.content_scale_aspect = previous_scale_aspect


func _ready() -> void:
	get_tree().paused = false
	# Navegador nao deixa a pagina se fechar; o botao Sair so faz sentido no desktop.
	$Frame/Background/Buttons/QuitButton.visible = not OS.has_feature("web")
	background_source = background.texture.get_image()
	background.resized.connect(queue_background_refresh)
	get_tree().root.size_changed.connect(queue_background_refresh)
	queue_background_refresh()
	sync_settings_controls()
	if GameMenu.open_level_select:
		GameMenu.open_level_select = false
		show_level_select()
	else:
		show_main()


## A arte e desenhada 1:1 com os pixels da tela: a imagem original e reamostrada
## (Lanczos) exatamente para o tamanho em que vai aparecer e exibida sem filtro.
## Deixar a GPU reduzir a imagem com filtro linear/mipmaps deixa tudo embacado.
func queue_background_refresh() -> void:
	if background_refresh_queued:
		return
	background_refresh_queued = true
	refresh_background.call_deferred()


func refresh_background() -> void:
	background_refresh_queued = false
	# Restaurar a proporcao em _exit_tree() tambem dispara size_changed.
	if not is_inside_tree():
		return
	var screen_scale := get_viewport().get_final_transform().get_scale()
	var target := Vector2i((background.size * screen_scale).round())
	if target.x <= 0 or target.y <= 0 or target == background_pixel_size:
		return

	background_pixel_size = target
	var image := background_source.duplicate() as Image
	# Metades exatas sao baratas e nitidas; o Lanczos so faz o ajuste final.
	while image.get_width() >= target.x * 2 and image.get_height() >= target.y * 2:
		image.shrink_x2()
	if target != image.get_size():
		image.resize(target.x, target.y, Image.INTERPOLATE_LANCZOS)
	background.texture = ImageTexture.create_from_image(image)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if settings_overlay.visible or (play_overlay.visible and mode_panel.visible):
		show_main()
	elif play_overlay.visible:
		show_play_menu()
	else:
		return
	get_viewport().set_input_as_handled()


func show_main() -> void:
	settings_overlay.hide()
	play_overlay.hide()
	main_buttons.show()
	play_button.grab_focus()


func show_settings() -> void:
	sync_settings_controls()
	main_buttons.hide()
	play_overlay.hide()
	settings_overlay.show()
	volume_slider.grab_focus()


func show_play_menu() -> void:
	show_play_panel(mode_panel)

	var has_save := SaveManager.has_save
	saved_game_button.disabled = not has_save
	saved_game_button.focus_mode = Control.FOCUS_ALL if has_save else Control.FOCUS_NONE
	if has_save:
		save_info.text = "Jogo salvo: %d de %d fases liberadas." % [
			SaveManager.get_unlocked_count(),
			SaveManager.get_level_count(),
		]
		saved_game_button.grab_focus()
	else:
		save_info.text = "Nenhum jogo salvo ainda."
		new_game_button.grab_focus()


func show_new_game_confirmation() -> void:
	show_play_panel(confirm_panel)
	confirm_cancel_button.grab_focus()


func show_level_select() -> void:
	show_play_panel(level_select)
	level_select.open()


func show_play_panel(panel: Control) -> void:
	main_buttons.hide()
	settings_overlay.hide()
	play_overlay.show()
	for candidate: Control in [mode_panel, confirm_panel, level_select]:
		candidate.visible = candidate == panel


func start_new_game() -> void:
	SaveManager.start_new_game()
	show_level_select()


func sync_settings_controls() -> void:
	volume_slider.set_value_no_signal(SettingsManager.master_volume * 100.0)
	volume_value.text = "%d%%" % roundi(SettingsManager.master_volume * 100.0)
	fullscreen_check.set_pressed_no_signal(SettingsManager.fullscreen)


func _on_play_button_pressed() -> void:
	show_play_menu()


func _on_new_game_button_pressed() -> void:
	if SaveManager.has_progress():
		show_new_game_confirmation()
	else:
		start_new_game()


func _on_saved_game_button_pressed() -> void:
	show_level_select()


func _on_confirm_new_game_button_pressed() -> void:
	start_new_game()


func _on_confirm_cancel_button_pressed() -> void:
	show_play_menu()
	new_game_button.grab_focus()


func _on_play_back_button_pressed() -> void:
	show_main()


func _on_level_select_back_requested() -> void:
	show_play_menu()


func _on_settings_button_pressed() -> void:
	show_settings()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_volume_slider_value_changed(value: float) -> void:
	SettingsManager.set_master_volume(value / 100.0)
	volume_value.text = "%d%%" % roundi(value)


func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	SettingsManager.set_fullscreen(toggled_on)


func _on_back_button_pressed() -> void:
	show_main()
	settings_button.grab_focus()
