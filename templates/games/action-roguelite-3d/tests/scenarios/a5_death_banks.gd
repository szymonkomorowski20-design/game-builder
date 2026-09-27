extends GbScenario
## A5 — dying ends the run, sends the hero back to the hub and banks every ember collected (KILL_EMBERS per kill);
## the meta progress is saved to disk. (The rule is checked against the kills counted, not a fixed number: one
## swing can kill two enemies at once.)


func run() -> void:
	await load_scene("res://scenes/run/run.tscn")
	var game := node(".") as RogueRun
	var bot := RogueBot.new(self, game)
	await wait_frames(5)
	await bot.walk_to(Vector3(7, 0, 0), 0.8)
	await wait_until(func() -> bool: return game.state == RogueRun.State.ROOM, 2.0)
	var kills := [0]
	game.room.enemy_killed.connect(func() -> void: kills[0] += 1)
	await bot.fight_until(func() -> bool: return game.run.collected >= 1, 20.0)
	await wait_frames(10)
	expect_gt(kills[0], 0, "A5 the bot killed something")
	expect_eq(game.run.collected, kills[0] * RogueRun.KILL_EMBERS, "A5 one kill = KILL_EMBERS embers")
	var collected := game.run.collected
	var died := await wait_until(func() -> bool: return game.state == RogueRun.State.OVER, 40.0)
	expect(died, "A5 the hero dies when it stops fighting")
	var home := await wait_until(func() -> bool: return game.state == RogueRun.State.HUB, 4.0)
	expect(home, "A5 back in the hub")
	expect_eq(game.meta.currency, collected, "A5 every ember collected was banked")
	var saved := SaveSystem.load_save(game.save_path)
	expect_eq(int(saved.data.get("meta", {}).get("currency", -1)), collected, "A5 and saved to disk")
