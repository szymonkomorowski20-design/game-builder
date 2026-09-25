extends GbScenario
## P8 — reaching the goal completes the level and shows the message; the level can be shot as a visual check.


func run() -> void:
	var level := get_tree().current_scene
	var player := node("Player") as Player
	await shot("level_start")
	player.teleport(Vector2(1340.0, 301.0))
	await press("move_right", 0.8)
	expect(bool(level.get("completed")), "P8 goal reached")
	expect((node("HUD/Message") as Label).visible, "P8 end message visible")
	hold("move_right")
	await wait(1.5)
	release("move_right")
	expect_eq(int(level.get("deaths")), 0, "P8 after the goal the player stays in the level (no fall, no death)")
	expect_lt(player.global_position.x, 1440.0, "P8 player stopped at the goal")
	await shot("level_complete")
