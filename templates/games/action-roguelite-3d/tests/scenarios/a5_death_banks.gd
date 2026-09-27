extends GbScenario
## A5 — dying ends the run, sends the hero back to the hub and banks every ember collected (one per kill); the meta
## progress is saved to disk.


func run() -> void:
	await load_scene("res://scenes/run/run.tscn")
	var game := node(".") as RogueRun
	var bot := RogueBot.new(self, game)
	await wait_frames(5)
	await bot.walk_to(Vector3(7, 0, 0), 0.8)
	await wait_until(func() -> bool: return game.state == RogueRun.State.ROOM, 2.0)
	await bot.fight_until(func() -> bool: return game.run.collected >= 1, 20.0)
	expect_eq(game.run.collected, 1, "A5 one kill = one ember")
	var died := await wait_until(func() -> bool: return game.state == RogueRun.State.OVER, 40.0)
	expect(died, "A5 the hero dies when it stops fighting")
	var home := await wait_until(func() -> bool: return game.state == RogueRun.State.HUB, 4.0)
	expect(home, "A5 back in the hub")
	expect_eq(game.meta.currency, 1, "A5 the ember was banked")
	var saved := SaveSystem.load_save(game.save_path)
	expect_eq(int(saved.data.get("meta", {}).get("currency", -1)), 1, "A5 and saved to disk")
