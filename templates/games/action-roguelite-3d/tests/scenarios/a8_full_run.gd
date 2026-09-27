extends GbScenario
## A8 — the whole run is completable at base stats by a simple bot: hub → every room (taking the first boon offered
## and the first door) → boss → victory → hub with the embers banked. If this fails after a tuning change, the base
## game got too hard for a competent player (or a room soft-locked) — see the spec's balance bands.


func run() -> void:
	await load_scene("res://scenes/run/run.tscn")
	var game := node(".") as RogueRun
	var bot := RogueBot.new(self, game)
	await wait_frames(5)
	await bot.walk_to(Vector3(7, 0, 0), 0.8)
	await wait_until(func() -> bool: return game.state == RogueRun.State.ROOM, 2.0)
	var entered := [1]
	var outcome := {"over": false, "alive": false}
	game.state_changed.connect(func(st: RogueRun.State) -> void:
		if st == RogueRun.State.ROOM:
			entered[0] += 1
		elif st == RogueRun.State.OVER:
			outcome.over = true
			outcome.alive = game.player.health.current > 0)
	var guard := 0
	while not outcome.over and guard < game.rooms_per_run + 3:
		guard += 1
		await bot.fight_until(func() -> bool: return game.state != RogueRun.State.ROOM, 90.0)
		if game.state == RogueRun.State.REWARD:
			await wait(0.4)   # the boon choice ignores a pick for its first pick_delay
			await tap("attack")
		if game.state == RogueRun.State.DOORS:
			var doors := game.room.get_children().filter(func(n: Node) -> bool: return n is RogueDoor)
			var depth := game.run.depth
			await bot.walk_to((doors[0] as RogueDoor).global_position, 0.5, 10.0)
			await wait_until(func() -> bool: return game.run.depth > depth and game.state == RogueRun.State.ROOM, 3.0)
	var banked := game.run.collected
	expect(outcome.over, "A8 the run ended")
	expect(outcome.alive, "A8 with a victory, not a death (rooms entered: %d)" % entered[0])
	expect_eq(entered[0], game.rooms_per_run, "A8 every room of the run was entered")
	await wait_until(func() -> bool: return game.state == RogueRun.State.HUB, 4.0)
	expect_eq(game.meta.currency, banked, "A8 the run's embers are banked")
