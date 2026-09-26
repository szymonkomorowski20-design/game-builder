extends GbScenario
## T3 — holding action fires in the facing direction at the cooldown rate; two hits kill an enemy.


func run() -> void:
	var arena := get_tree().current_scene
	var player := node("Player") as TopDownPlayer
	var enemies := nodes_in_group("enemies")
	expect_eq(enemies.size(), 2, "T3 wave 1 has 2 enemies")
	for e in enemies:
		e.move_speed = 0.0
	enemies[0].global_position = Vector2(230, 180)
	enemies[1].global_position = Vector2(600, 330)
	await wait_frames(2)
	await press("action", 0.55)
	expect_eq(player.shots_fired, 3, "T3 shots at t=0, 0.25, 0.5 (cooldown 0.25 s)")
	var killed := await wait_until(func() -> bool: return int(arena.get("kills")) == 1, 1.5)
	expect(killed, "T3 the enemy in front died after two hits")
	expect_eq(nodes_in_group("enemies").size(), 1, "T3 one enemy left")
