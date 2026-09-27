extends GbScenario
## A6 — at the shrine, action opens the upgrades; buying Vitality spends embers and raises max health for the next
## run; the shrine closes with attack. (Setup: 30 banked embers, as after a few runs.)


func run() -> void:
	await load_scene("res://scenes/run/run.tscn")
	var game := node(".") as RogueRun
	var bot := RogueBot.new(self, game)
	await wait_frames(5)
	game.meta.currency = 30
	var shrine := (game.hub.get_node("Shrine") as Node3D).global_position
	await bot.walk_to(shrine + Vector3(0, 0, 1.0), 0.4)
	await wait_frames(3)
	await tap("action")
	expect_eq(game.state, RogueRun.State.SHRINE, "A6 action at the shrine opens it")
	expect_eq(game.ui.mode, RogueUI.Mode.SHRINE, "A6 the shrine panel is open")
	var max_before := game.player.health.max_health
	await tap("action")
	expect_eq(game.meta.level(&"vitality"), 1, "A6 Vitality bought")
	expect_eq(game.meta.currency, 20, "A6 it cost 10")
	expect_eq(game.player.health.max_health, max_before + 10, "A6 max health +10 right away")
	await shot("a6_shrine")
	await tap("attack")
	expect_eq(game.state, RogueRun.State.HUB, "A6 attack closes the shrine")
	await bot.walk_to(Vector3(7, 0, 0), 0.8)
	await wait_until(func() -> bool: return game.state == RogueRun.State.ROOM, 2.0)
	expect_eq(game.player.health.max_health, max_before + 10, "A6 the next run starts with the upgrade")
