extends GbScenario
## F1 — mouse look: moving the mouse right turns right by screen_relative × sensitivity (independent of the window —
## `relative` is set to a scaled value to prove it is not used); looking up stops at max_pitch.


func run() -> void:
	var player := node("Player") as FpsPlayer
	player.require_captured_mouse = false
	await wait(0.2)
	var ev := InputEventMouseMotion.new()
	ev.screen_relative = Vector2(100, 0)
	ev.relative = Vector2(1000, 0)   # what a stretched viewport might report — must not be used
	Input.parse_input_event(ev)
	await wait_frames(2)
	expect_near(player.yaw, -100.0 * player.tuning.mouse_sensitivity, 0.0001, "F1 right = turn right by screen_relative × sensitivity")
	var up := InputEventMouseMotion.new()
	up.screen_relative = Vector2(0, -100000)
	Input.parse_input_event(up)
	await wait_frames(2)
	expect_near(player.pitch, deg_to_rad(player.tuning.max_pitch_deg), 0.0001, "F1 looking up stops at max_pitch")
