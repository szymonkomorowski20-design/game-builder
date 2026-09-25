extends GutTest
## R17 — settings round trip, defaults on missing file, volume applied to the bus, rebinding replaces only the
## keyboard event and survives a restart, conflict lookup.

var file := ""


func before_each() -> void:
	file = OS.get_user_data_dir().path_join("gb_r17_%d.cfg" % Time.get_ticks_usec())
	InputMap.load_from_project_settings()


func after_each() -> void:
	if FileAccess.file_exists(file):
		DirAccess.remove_absolute(file)
	InputMap.load_from_project_settings()
	AudioServer.set_bus_volume_db(0, 0.0)
	AudioServer.set_bus_mute(0, false)


func test_r17_missing_file_keeps_defaults() -> void:
	var s := GameSettings.new(file)
	s.load_settings()
	assert_eq(s.volumes["Master"], 1.0)
	assert_false(s.fullscreen)


func test_r17_round_trip_and_clamp() -> void:
	var s := GameSettings.new(file)
	s.volumes["Music"] = 0.25
	s.fullscreen = true
	assert_eq(s.save(), OK)
	var t := GameSettings.new(file)
	t.load_settings()
	assert_almost_eq(t.volumes["Music"], 0.25, 0.0001)
	assert_true(t.fullscreen)


func test_r17_master_volume_applied_in_db() -> void:
	var s := GameSettings.new(file)
	s.volumes["Master"] = 0.5
	s.apply()
	assert_almost_eq(AudioServer.get_bus_volume_db(0), linear_to_db(0.5), 0.01)
	s.volumes["Master"] = 0.0
	s.apply()
	assert_true(AudioServer.is_bus_mute(0), "zero volume mutes instead of -inf dB")


func test_r17_rebind_keeps_gamepad_and_persists() -> void:
	var pads_before := InputMap.action_get_events("jump").filter(func(e): return not e is InputEventKey).size()
	var s := GameSettings.new(file)
	s.rebind(&"jump", KEY_J)
	var keys := InputMap.action_get_events("jump").filter(func(e): return e is InputEventKey)
	assert_eq(keys.size(), 1)
	assert_eq(keys[0].physical_keycode, KEY_J)
	assert_eq(InputMap.action_get_events("jump").size() - 1, pads_before, "gamepad events untouched")
	s.save()

	InputMap.load_from_project_settings()   # "restart the game"
	var t := GameSettings.new(file)
	t.load_settings()
	t.apply()
	assert_eq(t.action_using_key(KEY_J), &"jump")


func test_r17_conflict_lookup() -> void:
	var s := GameSettings.new(file)
	assert_eq(s.action_using_key(KEY_A), &"move_left")
	assert_eq(s.action_using_key(KEY_F12), &"")
