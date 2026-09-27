extends GbScenario
## A2 — the training dummy in the hub takes the three-swing combo in order, one hit per swing, scaled by the hero's
## attack power (1.0 at the start, so exactly the default combo's 10, 12, 25).


func run() -> void:
	await load_scene("res://scenes/run/run.tscn")
	var game := node(".") as RogueRun
	var bot := RogueBot.new(self, game)
	await wait_frames(5)
	var dummy := game.hub.dummy
	var near := await bot.walk_to(dummy.global_position + Vector3(0, 0, 1.3), 0.25)
	expect(near, "A2 the bot reached the dummy")
	await press("move_up", 0.05)      # face it
	await wait(0.3)
	dummy.hits.clear()
	await tap("attack")
	await wait(0.2)
	await tap("attack")
	await wait(0.2)
	await tap("attack")
	await wait(0.8)
	var expected := ComboMelee3D.default_combo().map(func(st: AttackStep): return roundi(st.damage * game.player.sheet.value(&"attack_power")))
	expect_eq(dummy.hits, expected, "A2 three swings, in order, once each")
	await shot("a2_dummy")
