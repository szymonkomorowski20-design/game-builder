extends GbScenario
## T1 — holding a direction reaches move_speed; diagonals are not faster than straight lines.


func _freeze_enemies() -> void:
	for e in nodes_in_group("enemies"):
		e.move_speed = 0.0


func run() -> void:
	_freeze_enemies()
	var player := node("Player") as TopDownPlayer
	var speed := player.tuning.move_speed
	await press("move_down", 0.5)
	await wait(0.3)
	var start := player.global_position
	hold("move_right")
	await wait(0.6)
	expect_near(player.velocity.length(), speed, 1.0, "T1 straight speed = move_speed")
	hold("move_up")
	await wait(0.6)
	expect_near(player.velocity.length(), speed, 1.0, "T1 diagonal speed = move_speed (normalized)")
	release("move_right")
	release("move_up")
	await wait(0.5)
	expect_near(player.velocity.length(), 0.0, 0.5, "T1 friction stops the player")
	expect_gt(player.global_position.x, start.x + 100.0, "T1 the player moved right")
