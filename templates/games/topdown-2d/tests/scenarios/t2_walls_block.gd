extends GbScenario
## T2 — walls and the pillar stop the player.


func run() -> void:
	for e in nodes_in_group("enemies"):
		e.move_speed = 0.0
	var player := node("Player") as TopDownPlayer
	player.global_position = Vector2(260, 180)
	await press("move_right", 1.2)
	expect_lt(player.global_position.x, 304.0 - 7.0, "T2 the pillar (left edge x=304) blocks the player")
	player.global_position = Vector2(60, 180)
	await press("move_left", 1.0)
	expect_gt(player.global_position.x, 16.0 + 7.0, "T2 the left wall blocks the player")
