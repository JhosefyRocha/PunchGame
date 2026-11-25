extends Node

## Preferencias do jogador. Sobrevivem entre sessoes em `user://`, entao sao
## carregadas e aplicadas uma vez so, quando o autoload sobe -- antes da
## primeira cena tocar qualquer som.

const SETTINGS_PATH := "user://settings.cfg"
const MASTER_BUS := &"Master"
const CONTROLS_VERSION := 2

const KEY_ACTIONS: Array[StringName] = [&"left", &"right", &"jump", &"attack", &"interact", &"roll"]
const DEFAULT_KEYS := {
	&"left": KEY_A,
	&"right": KEY_D,
	&"jump": KEY_SPACE,
	&"attack": KEY_J,
	&"interact": KEY_I,
	&"roll": KEY_O,
}
const ALT_KEYS := {
	&"left": [KEY_LEFT],
	&"right": [KEY_RIGHT],
	&"jump": [KEY_UP, KEY_W],
	&"attack": [],
	&"interact": [],
	&"roll": [],
}

var master_volume := 0.8
var fullscreen := false
var key_bindings: Dictionary = {}


func _ready() -> void:
	load_settings()
	apply_settings()
	for action in KEY_ACTIONS:
		_apply_key(action)


func get_key(action: StringName) -> int:
	return key_bindings.get(action, DEFAULT_KEYS[action])


func set_key(action: StringName, keycode: int) -> void:
	var previous := get_key(action)
	for other in KEY_ACTIONS:
		if other != action and get_key(other) == keycode:
			key_bindings[other] = previous
			_apply_key(other)
	key_bindings[action] = keycode
	_apply_key(action)
	save_settings()


func _apply_key(action: StringName) -> void:
	InputMap.action_erase_events(action)
	var primary := InputEventKey.new()
	primary.physical_keycode = get_key(action)
	InputMap.action_add_event(action, primary)
	for alt in ALT_KEYS[action]:
		var event := InputEventKey.new()
		event.physical_keycode = alt
		InputMap.action_add_event(action, event)


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


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))
	if int(config.get_value("controls", "version", 1)) != CONTROLS_VERSION:
		return
	for action in KEY_ACTIONS:
		if config.has_section_key("controls", action):
			key_bindings[action] = int(config.get_value("controls", action))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("controls", "version", CONTROLS_VERSION)
	for action in key_bindings:
		config.set_value("controls", action, key_bindings[action])
	config.save(SETTINGS_PATH)
