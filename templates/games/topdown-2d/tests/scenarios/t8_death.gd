extends GbScenario
## T8 — at 0 health the player is dead, stops moving, and the lose message is shown.


func run() -> void:
	for e in nodes_in_group("enemies"):
		e.move_speed = 0.0
	var arena := get_tree().current_scene
	var player := node("Player") as TopDownPlayer
	player.take_damage(player.tuning.max_health)
	await wait_frames(2)
	expect(player.is_dead(), "T8 player dead at 0 health")
	expect(bool(arena.get("lost")), "T8 arena registered the loss")
	expect((node("HUD/Message") as Label).visible, "T8 lose message shown")
	var pos := player.global_position
	await press("move_right", 0.5)
	expect_near(player.global_position.x, pos.x, 0.5, "T8 a dead player does not move")
