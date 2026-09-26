extends GbScenario
## T4 — enemies move toward the player at their move_speed.


func run() -> void:
	var player := node("Player") as TopDownPlayer
	var e: TopDownEnemy = nodes_in_group("enemies")[0]
	nodes_in_group("enemies")[1].move_speed = 0.0
	e.global_position = Vector2(500, 300)
	await wait_frames(1)
	var before := e.global_position.distance_to(player.global_position)
	await wait(1.0)
	var after := e.global_position.distance_to(player.global_position)
	expect_near(before - after, e.move_speed, 3.0, "T4 closes the distance by move_speed per second")
