extends GbScenario
## D2 — holding jump reaches jump_height (± 5 cm); releasing early (variable jump) gives a clearly lower jump.


func _apex(player: Player, hold_seconds: float) -> float:
	var floor_y := player.global_position.y
	var top := floor_y
	hold("jump")
	for i in int(1.2 * Engine.physics_ticks_per_second):
		if i == int(hold_seconds * Engine.physics_ticks_per_second):
			release("jump")
		await wait_frames(1)
		top = maxf(top, player.global_position.y)
	release("jump")
	await wait_until(func() -> bool: return player.is_on_floor(), 2.0)
	return top - floor_y


func run() -> void:
	var player := node("Player") as Player
	await wait(0.3)
	var full := await _apex(player, 1.0)
	expect_near(full, player.tuning.jump_height, 0.05, "D2 a held jump reaches jump_height")
	var short := await _apex(player, 0.08)
	expect_lt(short, full * 0.6, "D2 a tapped jump is clearly lower (variable height)")
