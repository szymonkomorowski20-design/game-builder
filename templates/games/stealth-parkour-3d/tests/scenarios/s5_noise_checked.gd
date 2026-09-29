extends GbScenario
## S5 — hearing and a cautious check: a sprint behind the market guard is heard; the guard stops and stares, walks to
## the noise, looks around, finds nothing, and walks back to its post (recipes 68–69). The player is gone by then (a
## teleport stands in for running off), so this tests hearing, not sight.


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	var g := bot.calm_guards(&"market")
	bot.freeze_crowd()
	var p := game.player
	await wait_frames(5)

	p.teleport(Vector3(6, 0.05, 5))
	await wait(0.4)
	expect_eq(g.senses.meter.value, 0.0, "behind the guard: unseen")
	await bot.push(Vector3(-1, 0, 0), 0.9, &"sprint")
	p.teleport(Vector3(-25, 0.05, 31))
	var heard := await wait_until(func() -> bool: return g.brain.state == GuardBrain.State.SUSPICIOUS, 2.0)
	expect(heard, "the guard heard the steps and stares")
	var checks := await wait_until(func() -> bool: return g.brain.state == GuardBrain.State.INVESTIGATE, 3.0)
	expect(checks, "then goes to check")
	var spot: Vector3 = g.brain.goal
	var there := await wait_until(func() -> bool: return Vector2(g.global_position.x - spot.x,
			g.global_position.z - spot.z).length() < 1.2, 12.0)
	expect(there, "walking to the noise (%.1f m from it)" % g.global_position.distance_to(spot))
	var back := await wait_until(func() -> bool: return g.brain.state == GuardBrain.State.PATROL, 20.0)
	expect(back, "finds nothing and goes back")
	await wait(3.0)
	expect_lt(Vector2(g.global_position.x - g.brain.post.x, g.global_position.z - g.brain.post.z).length(), 1.0,
			"to its post")
