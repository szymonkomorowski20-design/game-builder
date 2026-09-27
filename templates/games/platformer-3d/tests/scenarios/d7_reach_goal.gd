extends GbScenario
## D7 — reaching the goal completes the level, shows the message and freezes the player there; shots for the look.


func run() -> void:
	var level := get_tree().current_scene
	var player := node("Player") as Player
	await wait(0.3)
	await shot("level_start")
	player.teleport(Vector3(0.0, 0.05, -27.0))
	await press("move_up", 1.0)
	expect(bool(level.get("completed")), "D7 goal reached")
	expect((node("HUD/Message") as Label).visible, "D7 end message visible")
	hold("move_up")
	await wait(1.0)
	release("move_up")
	expect_eq(int(level.get("deaths")), 0, "D7 after the goal the player stays (no fall off the end, no death)")
	expect_gt(player.global_position.z, -31.0, "D7 player stopped at the goal")
	await shot("level_complete")
