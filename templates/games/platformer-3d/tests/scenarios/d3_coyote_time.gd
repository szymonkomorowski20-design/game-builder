extends GbScenario
## D3 — jump works within coyote_time after running off the ledge of the first ground (z = -10), not after it.


func _run_off(player: Player) -> void:
	player.teleport(Vector3(0.0, 0.05, -9.2))
	await wait(0.2)
	hold("move_up")
	await wait_until(func() -> bool: return not player.is_on_floor(), 2.0)
	release("move_up")


func run() -> void:
	var player := node("Player") as Player
	await _run_off(player)
	var before := player.jumps_started
	await wait(player.tuning.coyote_time * 0.5)
	await tap("jump")
	expect_eq(player.jumps_started, before + 1, "D3 jump inside the coyote window works")

	await _run_off(player)
	before = player.jumps_started
	await wait(player.tuning.coyote_time * 2.0)
	await tap("jump")
	expect_eq(player.jumps_started, before, "D3 jump after the coyote window does nothing")
