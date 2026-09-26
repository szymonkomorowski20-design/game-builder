extends GbScenario
## T6 — a heart is not used at full health; when hurt, it heals 1 and disappears.


func run() -> void:
	for e in nodes_in_group("enemies"):
		e.move_speed = 0.0
	var player := node("Player") as TopDownPlayer
	var max_hp := player.tuning.max_health
	await press("move_down", 1.0)   # walk onto the heart at (120, 300)
	expect_eq(nodes_in_group("hearts").size(), 1, "T6 heart stays at full health")
	await press("move_up", 0.6)
	player.take_damage(2)
	await press("move_down", 0.8)
	await wait_frames(3)
	expect_eq(player.health, max_hp - 1, "T6 heart heals 1")
	expect_eq(nodes_in_group("hearts").size(), 0, "T6 heart consumed")
