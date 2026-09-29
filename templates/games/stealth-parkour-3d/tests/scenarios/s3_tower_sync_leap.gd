extends GbScenario
## S3 — the viewpoint: the tower (15 m) is climbed lip by lip; the action key at the top synchronises and reveals the
## places within its radius (the target's house, the first poster) and the next viewpoint on the map; a jump off the
## top's east edge lands in the hay below, unhurt.


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	bot.calm_guards()
	var p := game.player
	await wait_frames(5)

	p.teleport(Vector3(-14, 0.05, 15.6))
	await wait(0.3)
	var t0 := game.clock
	expect(await bot.climb(Vector3(0, 0, -1), 14.9, 40.0), "climbed the tower (y %.2f)" % p.global_position.y)
	note("the climb took %.1f s, %d moves" % [game.clock - t0, p.climber.moves])
	expect(await bot.walk_to(Vector3(-14, 0, 12), false, 0.5), "at the viewpoint")
	await tap("action")
	var known := game.viewpoints.revealed()
	expect(known.has(&"target_house"), "the sync reveals the target's house")
	expect(known.has(&"poster_1"), "and the poster within 40 m")
	expect(not known.has(&"poster_2"), "not the one beyond it")
	expect(game.viewpoints.fast_travel_points().has(&"tower"), "the tower is a fast-travel point")
	shot("s3_synced")

	var health := p.health
	bot.stick(Vector3(1, 0, 0))
	await wait(1.0)
	expect_eq(p.state, "edge", "the top's edge holds")
	p.last_landing = {}
	await tap("jump")
	var landed := await wait_until(func() -> bool:
		bot.stick(Vector3(1, 0, 0))
		return p.last_landing.has("height"), 5.0)
	bot.let_go()
	expect(landed, "a leap from the top")
	expect(p.last_landing.get("soft", false) == true, "into the hay")
	expect_gt(float(p.last_landing.get("height", 0.0)), 13.0, "a fall of %.1f m" % float(p.last_landing.get("height", 0.0)))
	expect_eq(p.health, health, "unhurt")
