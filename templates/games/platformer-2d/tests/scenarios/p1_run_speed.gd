extends GbScenario
## P1 — holding a direction accelerates to run_speed; distance in 1 s matches the kinematics.


func run() -> void:
	var player := node("Player") as Player
	await wait(0.3)
	var t := player.tuning
	var start_x := player.global_position.x
	await press("move_right", 1.0)
	var ramp := t.run_speed / t.acceleration
	var expected := t.run_speed * (1.0 - ramp) + 0.5 * t.run_speed * ramp
	expect_near(player.global_position.x - start_x, expected, 8.0, "P1 distance after 1 s of running")
	expect_eq(player.state, "run", "P1 state is run right after releasing (friction still slowing)")
	await wait(1.0)
	expect_near(player.velocity.x, 0.0, 0.5, "P1 friction stops the player")
