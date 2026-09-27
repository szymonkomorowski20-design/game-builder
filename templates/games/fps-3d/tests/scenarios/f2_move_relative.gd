extends GbScenario
## F2 — movement follows the view: after turning 90° left, "up" walks toward -X at walk_speed.


func run() -> void:
	var player := node("Player") as FpsPlayer
	await wait(0.2)
	player.look(PI / 2.0, 0.0)
	var start := player.global_position
	await press("move_up", 1.0)
	var moved := player.global_position - start
	var t := player.tuning
	var ramp := t.walk_speed / t.acceleration
	var expected := t.walk_speed * (1.0 - ramp) + 0.5 * t.walk_speed * ramp
	expect_near(-moved.x, expected, 0.15, "F2 walked toward -X (%s)" % moved)
	expect_near(moved.z, 0.0, 0.02, "F2 no drift along Z")
