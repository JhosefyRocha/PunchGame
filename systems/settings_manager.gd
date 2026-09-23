extends Node

## Preferencias do jogador. Sobrevivem entre sessoes em `user://`, entao sao
## carregadas e aplicadas uma vez so, quando o autoload sobe -- antes da
## primeira cena tocar qualquer som.

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const MASTER_BUS := &"Master"

var master_volume := 0.8
var fullscreen := false


func _ready() -> void:
	load_settings()
	apply_settings()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_settings()
	save_settings()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply_settings()
	save_settings()


func apply_settings() -> void:
	var bus := AudioServer.get_bus_index(MASTER_BUS)
	AudioServer.set_bus_mute(bus, is_zero_approx(master_volume))
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))

	var current_mode := DisplayServer.window_get_mode()
	var is_fullscreen := current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	if fullscreen and not is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

	settings_changed.emit()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)
