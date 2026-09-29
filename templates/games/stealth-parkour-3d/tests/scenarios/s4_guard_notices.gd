extends GbScenario
## S4 — a guard notices: standing in the market guard's main zone, the player is detected after 1 / rate seconds (the
## rate from recipe 68's cone and the player's cues, times notoriety's multiplier); the guard hunts, the chase is on,
## and the contract's target runs for the palazzo.


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	var g := bot.calm_guards(&"market")
	bot.freeze_crowd()
	var p := game.player
	await wait_frames(5)

	p.teleport(Vector3(13, 0.05, 13))
	await wait_frames(3)
	expect(not p.blended, "nobody around to blend with")
	var eye := g.senses.global_position
	var head := p.global_position + Vector3.UP * 1.7
	var zone := g.senses.cone.zone(eye, -g.global_transform.basis.z, head)
	expect_eq(zone, VisionCone.MAIN, "in front of the guard: its main zone")
	var expected := 1.0 / (g.senses.cone.rate(zone, eye.distance_to(head), p.stealth_cues()) * game.notice_scale())
	g.senses.meter.reset()
	var t0 := game.clock
	var noticed := await wait_until(func() -> bool: return g.senses.meter.detected, expected + 2.0)
	expect(noticed, "noticed")
	expect_near(game.clock - t0, expected, 0.3, "after 1 / rate seconds (%.2f s expected)" % expected)
	var hunts := await wait_until(func() -> bool: return g.brain.state == GuardBrain.State.ALERT, 1.0)
	expect(hunts, "the guard hunts")
	await wait_frames(3)
	expect(game.wanted.is_chased(), "the chase is on")
	expect(game.contract.target_alerted, "and the target runs for the palazzo")
	shot("s4_noticed")
