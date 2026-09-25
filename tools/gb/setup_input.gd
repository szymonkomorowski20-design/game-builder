extends SceneTree
## game-builder: add the default input actions to project.godot through the engine itself, so the
## serialized InputEvent format is always the one THIS Godot version writes. Existing actions are
## never touched. Run: godot --headless --path <project> --script <this file>

const DEADZONE := 0.2

# action -> [keycodes], [joypad buttons], [joypad axis, direction]
var actions := {
	"move_left": [[KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [JOY_AXIS_LEFT_X, -1.0]],
	"move_right": [[KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [JOY_AXIS_LEFT_X, 1.0]],
	"move_up": [[KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], [JOY_AXIS_LEFT_Y, -1.0]],
	"move_down": [[KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [JOY_AXIS_LEFT_Y, 1.0]],
	"jump": [[KEY_SPACE], [JOY_BUTTON_A], []],
	"action": [[KEY_E, KEY_ENTER], [JOY_BUTTON_X], []],
	"pause": [[KEY_ESCAPE], [JOY_BUTTON_START], []],
}


func _init() -> void:
	var added := 0
	for name: String in actions:
		var key: String = "input/" + name
		if ProjectSettings.has_setting(key):
			continue
		var spec: Array = actions[name]
		var events: Array = []
		for code: int in spec[0]:
			var k := InputEventKey.new()
			k.physical_keycode = code as Key
			k.device = -1
			events.append(k)
		for b: int in spec[1]:
			var jb := InputEventJoypadButton.new()
			jb.button_index = b as JoyButton
			jb.device = -1
			events.append(jb)
		if spec[2].size() == 2:
			var ja := InputEventJoypadMotion.new()
			ja.axis = spec[2][0] as JoyAxis
			ja.axis_value = spec[2][1]
			ja.device = -1
			events.append(ja)
		ProjectSettings.set_setting(key, {"deadzone": DEADZONE, "events": events})
		added += 1
	var err := ProjectSettings.save()
	print("GB_INPUT_DONE added=%d err=%d" % [added, err])
	quit(0 if err == OK else 1)
