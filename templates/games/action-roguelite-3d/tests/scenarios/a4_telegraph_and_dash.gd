extends GbScenario
## A4 — enemies show their attack before it lands (red + "!") for the full telegraph, and a hit lands if the hero
## just stands there; dashing away during the telegraph avoids the strike.


func run() -> void:
	await load_scene("res://scenes/run/run.tscn")
	var game := node(".") as RogueRun
	var bot := RogueBot.new(self, game)
	await wait_frames(5)
	await bot.walk_to(Vector3(7, 0, 0), 0.8)
	await wait_until(func() -> bool: return game.state == RogueRun.State.ROOM, 2.0)
	var p := game.player
	# Stand still: the first enemy to reach the hero telegraphs, then hits.
	var first := await wait_until(func() -> bool: return _telegraphing(game) != null, 10.0)
	expect(first, "A4 an enemy telegraphs when in range")
	await shot("a4_telegraph")
	var hp := p.health.current
	await wait(0.6)
	expect_lt(p.health.current, hp, "A4 standing still in a telegraph gets you hit")
	# Next telegraph: dash away from it.
	await wait(0.7)
	var second := await wait_until(func() -> bool: return _telegraphing(game) != null and not p.health.is_invulnerable(), 10.0)
	expect(second, "A4 another telegraph")
	var e := _telegraphing(game)
	var away := p.global_position - e.global_position
	away.y = 0.0
	hp = p.health.current
	bot.steer(away.normalized())
	await tap("dash")
	await wait(0.5)
	bot.stop()
	expect_eq(p.health.current, hp, "A4 dashing out of the telegraph avoids the strike")


func _telegraphing(game: RogueRun) -> RogueEnemy:
	for n in game.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as RogueEnemy
		if e != null and e.brain.is_telegraphing() and e.global_position.distance_to(game.player.global_position) < 2.2:
			return e
	return null
