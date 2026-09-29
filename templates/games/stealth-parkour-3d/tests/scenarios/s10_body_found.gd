extends GbScenario
## S10 — a body is found: a dead guard lies in the east-west street; the patrol walking that street sees it, goes to
## check, raises the alarm there and searches around it (recipe 69: a body is a stimulus that ends in an alarm).


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	var patrol := bot.calm_guards(&"patrol_ew")
	bot.freeze_crowd()
	var p := game.player
	p.teleport(Vector3(-25, 0.05, 31))
	await wait_frames(5)

	var dead: GuardAgent = null
	for g in game.guards:
		if g.guard_name == &"market":
			dead = g
	dead.global_position = Vector3(-12, 0.02, 1.0)
	dead.die()
	await wait_frames(2)
	expect(dead.is_in_group(&"body"), "a body lies in the street")

	var noticed := await wait_until(func() -> bool:
		return patrol.brain.state == GuardBrain.State.SUSPICIOUS or patrol.brain.state == GuardBrain.State.INVESTIGATE, 15.0)
	expect(noticed, "the patrol sees the body")
	expect_eq(String(patrol.brain.stimulus().get("kind", &"")), "body", "as a body")
	var alarm := await wait_until(func() -> bool: return game.board.alarm_id > 0, 15.0)
	expect(alarm, "checks it and raises the alarm")
	var searching := await wait_until(func() -> bool: return patrol.brain.state == GuardBrain.State.SEARCH, 3.0)
	expect(searching, "and searches around it")
	shot("s10_body_found")
