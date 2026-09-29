extends GbScenario
## S6 — blending into the crowd: standing between two calm townspeople in the market guard's main zone, the player is
## blended and not noticed; three metres from them, alone, the player is (recipes 68 and 70).


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	var g := bot.calm_guards(&"market")
	bot.freeze_crowd()
	var p := game.player
	await wait_frames(5)

	game.civilians[0].position = Vector3(13.8, 0, 12.4)
	game.civilians[1].position = Vector3(12.3, 0, 13.7)
	p.teleport(Vector3(13, 0.05, 13))
	await wait(0.3)
	expect(p.blended, "between two calm townspeople: blended")
	g.senses.meter.reset()
	await wait(4.0)
	expect_eq(g.senses.meter.value, 0.0, "the guard doesn't notice")
	shot("s6_blended")

	p.teleport(Vector3(15.5, 0.05, 10.5))
	await wait(0.3)
	expect(not p.blended, "three metres away, alone")
	g.senses.meter.reset()
	var noticed := await wait_until(func() -> bool: return g.senses.meter.detected, 8.0)
	expect(noticed, "and noticed")
