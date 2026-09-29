extends GbScenario
## S2 — climbing and the roofs: a jump at a house's lipped face and holding the stick at the wall climbs it onto the
## roof; a sprint leaps the 2 m alleys between roofs (north, then west and back east); at the roof's edge over the
## main street the edge holds, the drop intent hangs from it, holding down climbs down the lips, and a last drop lands
## on the street unhurt.


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	bot.calm_guards()
	var p := game.player
	await wait_frames(5)

	p.teleport(Vector3(-7.5, 0.05, -3.2))
	await wait(0.3)
	expect(await bot.climb(Vector3(0, 0, -1), 5.9), "climbed a house's face onto its roof (y %.2f)" % p.global_position.y)
	shot("s2_on_roof")

	Input.action_press(&"sprint")
	var north := await wait_until(func() -> bool:
		bot.stick(Vector3(0, 0, -1))
		return p.is_on_floor() and p.global_position.z < -13.0, 5.0)
	bot.let_go()
	expect(north, "a sprint leaps the alley north to the next roof")
	expect_gt(p.global_position.y, 5.9, "and lands on it (y %.2f)" % p.global_position.y)
	await wait(0.4)

	Input.action_press(&"sprint")
	var west := await wait_until(func() -> bool:
		bot.stick(Vector3(-1, 0, 0))
		return p.is_on_floor() and p.global_position.x < -13.0, 5.0)
	bot.let_go()
	expect(west, "and the alley west")
	await wait(0.4)
	Input.action_press(&"sprint")
	var back := await wait_until(func() -> bool:
		bot.stick(Vector3(1, 0, 0))
		return p.is_on_floor() and p.global_position.x > -9.5, 5.0)
	bot.let_go()
	expect(back, "and back east")
	expect_gt(p.global_position.y, 5.9, "still on the roofs")
	await wait(0.4)

	bot.stick(Vector3(1, 0, 0))
	await wait(2.0)
	expect_eq(p.state, "edge", "running to the edge over the main street: the edge holds")
	await tap("drop")
	var hanging := await wait_until(func() -> bool: return p.climber.state == &"hang", 2.0)
	expect(hanging, "the drop intent hangs from the roof's edge")
	var health := p.health
	var down := await wait_until(func() -> bool:
		bot.stick(Vector3(0, 0, 1))
		return p.climber.state == &"hang" and float(p.climber.ledge.get("top_y", 9.0)) < 2.5, 8.0)
	bot.stick(Vector3.ZERO)
	expect(down, "holding down climbs down to the lowest lip")
	await tap("drop")
	var street := await wait_until(func() -> bool: return p.is_on_floor() and p.climber.state == &"none", 2.0)
	expect(street and p.global_position.y < 0.2, "a last drop lands on the street")
	expect_eq(p.health, health, "unhurt")
