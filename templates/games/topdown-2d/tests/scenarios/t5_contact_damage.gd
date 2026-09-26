extends GbScenario
## T5 — touching an enemy hurts once, invulnerability protects for its duration, staying in contact hurts again.


func run() -> void:
	var player := node("Player") as TopDownPlayer
	var e: TopDownEnemy = nodes_in_group("enemies")[0]
	nodes_in_group("enemies")[1].move_speed = 0.0
	e.move_speed = 0.0
	var max_hp := player.tuning.max_health
	e.global_position = player.global_position + Vector2(10, 0)
	await wait(0.1)
	expect_eq(player.health, max_hp - 1, "T5 contact deals 1 damage")
	await wait(0.5)
	expect_eq(player.health, max_hp - 1, "T5 no damage during invulnerability (0.8 s)")
	await wait(0.4)
	expect_eq(player.health, max_hp - 2, "T5 staying in contact hurts again after invulnerability")
