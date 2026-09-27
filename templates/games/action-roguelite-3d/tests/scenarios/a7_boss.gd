extends GbScenario
## A7 — the boss room (run started at the last room via start_depth): the boss telegraphs, changes phase at 66% and
## 33% (calling adds), and a bot that dashes out of telegraphs beats it; victory banks the run and returns to the hub.


func run() -> void:
	await load_scene("res://scenes/run/run.tscn")
	var game := node(".") as RogueRun
	var bot := RogueBot.new(self, game)
	await wait_frames(5)
	game.start_depth = game.rooms_per_run - 1
	var phases := []
	await bot.walk_to(Vector3(7, 0, 0), 0.8)
	await wait_until(func() -> bool: return game.state == RogueRun.State.ROOM, 2.0)
	var boss := game.room.boss
	expect(boss != null, "A7 the last room holds the boss")
	boss.brain.phase_changed.connect(func(p: int) -> void: phases.append(p))
	var telegraphed := await wait_until(func() -> bool: return boss.brain.is_telegraphing(), 3.0)
	expect(telegraphed, "A7 the boss telegraphs")
	await wait(0.3)
	await shot("a7_boss_telegraph")
	var won := await bot.fight_until(func() -> bool: return game.state != RogueRun.State.ROOM, 120.0)
	expect(won, "A7 the fight ended")
	expect_eq(phases, [1, 2], "A7 both phase changes happened, in order")
	expect_eq(game.state, RogueRun.State.OVER, "A7 the run is over")
	expect_gt(game.player.health.current, 0, "A7 … with the hero alive: victory")
	var home := await wait_until(func() -> bool: return game.state == RogueRun.State.HUB, 4.0)
	expect(home, "A7 back in the hub after the victory")
