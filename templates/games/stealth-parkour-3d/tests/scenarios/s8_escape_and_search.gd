extends GbScenario
## S8 — escaping: seen on a stall, the player is chased; out of sight (a teleport stands in for the run) and hidden in
## the hay, the pursuers lose the player, a search circle stays, and after 3 s hidden the player has escaped (recipe
## 72). The guard gets as close to the last seen place as the navigation mesh allows (the stall's top is off it),
## searches, gives up, and goes back with raised caution (recipe 69).


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	var g := bot.calm_guards(&"market")
	bot.freeze_crowd()
	var p := game.player
	await wait_frames(5)

	# Seen standing on a stall: the last seen place is off the navigation mesh, and the guard must still get there.
	p.teleport(Vector3(12, 1.25, 12))
	var chased := await wait_until(func() -> bool: return game.wanted.state == WantedSearch.State.SEEN, 5.0)
	expect(chased, "seen: chased")

	p.teleport(Vector3(-2.5, 0.05, -21.3))
	await wait(0.2)
	await tap("action")
	expect_eq(p.hidden_in, &"hay", "hidden in the hay, far from the guard")
	var lost := await wait_until(func() -> bool: return game.wanted.state == WantedSearch.State.LOST, 3.0)
	expect(lost, "the pursuers lost the player: a search circle stays")
	var escaped := await wait_until(func() -> bool: return game.wanted.state == WantedSearch.State.ESCAPED, 6.0)
	expect(escaped, "hidden long enough: escaped")
	var searching := await wait_until(func() -> bool: return g.brain.state == GuardBrain.State.SEARCH, 12.0)
	expect(searching, "the guard searches the last seen place")
	var gave_up := await wait_until(func() -> bool:
		return g.brain.state == GuardBrain.State.RETURN or g.brain.state == GuardBrain.State.PATROL, 50.0)
	expect(gave_up, "and gives up")
	expect_eq(g.brain.guard_state(game.clock), &"caution", "with raised caution")
