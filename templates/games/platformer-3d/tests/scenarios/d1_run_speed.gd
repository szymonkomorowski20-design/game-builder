extends GbScenario
## D1 — holding move_up runs away from the camera (-Z), accelerating to run_speed; distance in 1 s matches the
## kinematics; friction stops the player after release.


func run() -> void:
	var player := node("Player") as Player
	await wait(0.3)
	var t := player.tuning
	var start := player.global_position
	await press("move_up", 1.0)
	var ramp := t.run_speed / t.acceleration
	var expected := t.run_speed * (1.0 - ramp) + 0.5 * t.run_speed * ramp
	expect_near(start.z - player.global_position.z, expected, 0.15, "D1 distance toward -Z after 1 s of running")
	expect_near(player.global_position.x, start.x, 0.01, "D1 no sideways drift")
	expect_eq(player.state, "run", "D1 state is run right after releasing (friction still slowing)")
	await wait(1.0)
	expect_near(Vector2(player.velocity.x, player.velocity.z).length(), 0.0, 0.05, "D1 friction stops the player")
