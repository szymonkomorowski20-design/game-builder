extends GbScenario
## P3 — jump works within coyote_time after walking off the ledge (x = 400), not after it.


func _walk_off(player: Player) -> void:
	player.teleport(Vector2(380.0, 301.0))
	await wait(0.2)
	hold("move_right")
	await wait_until(func() -> bool: return not player.is_on_floor(), 2.0)
	release("move_right")


func run() -> void:
	var player := node("Player") as Player
	await _walk_off(player)
	var before := player.jumps_started
	await wait(player.tuning.coyote_time * 0.5)
	await tap("jump")
	expect_eq(player.jumps_started, before + 1, "P3 jump inside the coyote window works")

	await _walk_off(player)
	before = player.jumps_started
	await wait(player.tuning.coyote_time * 2.0)
	await tap("jump")
	expect_eq(player.jumps_started, before, "P3 jump after the coyote window does nothing")
