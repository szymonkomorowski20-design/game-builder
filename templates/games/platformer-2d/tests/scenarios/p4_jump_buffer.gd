extends GbScenario
## P4 — a jump pressed shortly before landing triggers on landing.


func run() -> void:
	var player := node("Player") as Player
	player.teleport(Vector2(100.0, 250.0))
	var before := player.jumps_started
	await wait_until(func() -> bool: return player.global_position.y > 290.0, 2.0)
	expect(not player.is_on_floor(), "P4 still in the air when jump is pressed")
	await tap("jump")
	var jumped := await wait_until(func() -> bool: return player.jumps_started > before, 0.3)
	expect(jumped, "P4 buffered jump fires on landing")
