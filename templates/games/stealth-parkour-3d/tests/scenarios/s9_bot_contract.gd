extends GbScenario
## S9 — a bot completes the contract in the live district (every guard and the crowd running): it walks to the tower
## unseen, climbs it and synchronises (the target's house is revealed), leaps into the hay and hides; it waits until
## the target stands at its quiet stop by the hay and both patrols are far off, steps out, strikes, and walks 20 m away
## with nobody chasing — the contract is done, unseen.


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	var p := game.player
	await wait_frames(5)

	expect(await bot.walk_to(Vector3(-6, 0, 22)), "past the square")
	expect(await bot.walk_to(Vector3(-14, 0, 16.2)), "at the foot of the tower")
	expect(await bot.climb(Vector3(0, 0, -1), 14.9, 40.0), "climbed the tower")
	expect(await bot.walk_to(Vector3(-14, 0, 12), false, 0.5), "at the viewpoint")
	await tap("action")
	expect(game.viewpoints.revealed().has(&"target_house"), "the sync reveals the target's house")

	bot.stick(Vector3(1, 0, 0))
	await wait(1.0)
	await tap("jump")
	var landed := await wait_until(func() -> bool:
		bot.stick(Vector3(1, 0, 0))
		return p.is_on_floor() and p.global_position.y < 2.0, 6.0)
	bot.let_go()
	expect(landed and p.last_landing.get("soft", false) == true, "a leap into the hay")
	await wait(0.3)
	await tap("action")
	expect(p.is_hidden(), "hidden in the hay")
	note("hidden at %.1f s" % game.clock)

	var patrols := [game.guards[0], game.guards[1]]
	var ready := await wait_until(func() -> bool:
		if game.target.routine.waiting_at(game.clock) != 2:
			return false
		for g: GuardAgent in patrols:
			if g.global_position.distance_to(game.target.global_position) < 14.0:
				return false
		return true, 120.0)
	expect(ready, "the target stands at its quiet stop, the patrols far off (%.1f s)" % game.clock)
	var chase := func() -> bool:
		var d := game.target.global_position - p.global_position
		d.y = 0.0
		if d.length() <= 1.2:
			return true
		bot.stick(d.normalized())
		if p.state == "edge":
			Input.action_press(&"drop")
		else:
			Input.action_release(&"drop")
		return false
	var close := await wait_until(chase, 8.0)
	bot.let_go()
	Input.action_release(&"drop")
	expect(close, "stepped out of the hay and up to the target")
	await tap("strike")
	expect(not game.target.alive, "the strike kills the target")
	expect_eq(game.contract.phase, Contract.Phase.ESCAPE, "escape now")
	shot("s9_struck")

	expect(await bot.walk_to(Vector3(-2.5, 0, 10)), "away, around the hay")
	expect(await bot.walk_to(Vector3(-2.5, 0, 29)), "and south")
	var done := await wait_until(func() -> bool: return game.contract.phase == Contract.Phase.DONE, 10.0)
	expect(done, "far from the body with nobody chasing: the contract is done (%.1f s)" % game.clock)
	expect(game.contract.bonuses().get("unseen", false) == true, "unseen")
