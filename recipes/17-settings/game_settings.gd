class_name GameSettings
extends RefCounted
## Player settings persisted in user://settings.cfg (ConfigFile — human-readable, tolerant of missing keys):
## audio volumes per bus, fullscreen, and key rebinding for input actions.

const DEFAULT_PATH := "user://settings.cfg"

var path := DEFAULT_PATH
var volumes: Dictionary = {"Master": 1.0, "Music": 0.8, "SFX": 1.0}   ## bus name -> linear 0..1
var fullscreen := false
var bindings: Dictionary = {}   ## action -> physical keycode (only rebound actions)


func _init(file_path: String = DEFAULT_PATH) -> void:
	path = file_path


func save() -> Error:
	var cfg := ConfigFile.new()
	for bus in volumes:
		cfg.set_value("audio", bus, volumes[bus])
	cfg.set_value("video", "fullscreen", fullscreen)
	for action in bindings:
		cfg.set_value("input", action, bindings[action])
	return cfg.save(path)


## Missing file or keys keep the defaults (first launch, or a settings file from an older version).
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for bus in volumes:
		volumes[bus] = clampf(float(cfg.get_value("audio", bus, volumes[bus])), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	if cfg.has_section("input"):
		for action in cfg.get_section_keys("input"):
			if InputMap.has_action(action):
				bindings[action] = int(cfg.get_value("input", action))


func apply() -> void:
	for bus in volumes:
		var idx := AudioServer.get_bus_index(bus)
		if idx == -1:
			continue
		var v: float = volumes[bus]
		AudioServer.set_bus_mute(idx, v <= 0.0)
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	for action in bindings:
		_apply_key(action, bindings[action])


## Which action already uses this physical key (for "already bound to Jump — swap?" prompts). Empty if none.
func action_using_key(physical_keycode: int) -> StringName:
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey and ev.physical_keycode == physical_keycode:
				return action
	return &""


## Replaces the keyboard binding of `action`; gamepad events stay untouched.
func rebind(action: StringName, physical_keycode: int) -> void:
	bindings[action] = physical_keycode
	_apply_key(action, physical_keycode)


func _apply_key(action: StringName, physical_keycode: int) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	var key := InputEventKey.new()
	key.physical_keycode = physical_keycode as Key
	InputMap.action_add_event(action, key)
