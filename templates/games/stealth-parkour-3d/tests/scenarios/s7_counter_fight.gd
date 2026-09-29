extends GbScenario
## S7 — the fight: seen close by, the market guard hunts and strikes; the first strike, unanswered, costs the player a
## hit; then the bot presses counter 0.2 s before each hit (inside recipe 71's window, outside the perfect one), each
## counter costs the guard a hit, three kill it, and the player takes no more damage.


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	var g := bot.calm_guards(&"market")
	bot.freeze_crowd()
	var p := game.player
	await wait_frames(5)

	p.teleport(Vector3(11, 0.05, 11))
	var hunts := await wait_until(func() -> bool: return g.brain.state == GuardBrain.State.ALERT, 3.0)
	expect(hunts, "seen close by: the guard hunts")
	var health := p.health
	var first := await wait_until(func() -> bool: return p.health < health, 8.0)
	expect(first, "an unanswered strike lands: one hit off the player's health")
	await bot.counter_strikes(g, 20.0)
	expect(not g.alive, "three counters kill the guard (health %d)" % g.health)
	expect_eq(p.health, health - 1, "no more damage after the first")
	expect_gt(g.strikes, 2, "the guard struck %d times" % g.strikes)
	shot("s7_countered")
