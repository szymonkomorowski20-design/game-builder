extends GbScenario
## A3 — the run door starts a run; the first room's waves are fought and cleared; a boon choice of three appears and
## taking one applies it; doors show their rewards; walking into one enters the next room.


func run() -> void:
	await load_scene("res://scenes/run/run.tscn")
	var game := node(".") as RogueRun
	var bot := RogueBot.new(self, game)
	await wait_frames(5)
	await bot.walk_to(Vector3(7, 0, 0), 0.8)
	var started := await wait_until(func() -> bool: return game.state == RogueRun.State.ROOM, 2.0)
	expect(started, "A3 the run door starts a run")
	expect_eq(game.run.depth, 0, "A3 room 1")
	var cleared := await bot.fight_until(func() -> bool: return game.state != RogueRun.State.ROOM, 60.0)
	expect(cleared, "A3 the first room was cleared")
	expect_eq(game.state, RogueRun.State.REWARD, "A3 the reward is a boon choice")
	expect_eq(game.offer.size(), 3, "A3 three boons offered")
	expect_eq(game.ui.mode, RogueUI.Mode.BOONS, "A3 the boon panel is open")
	await shot("a3_boons")
	await tap("move_right")
	var picked := game.offer[game.ui.selected].boon.id
	await tap("attack")
	expect(game.owned.has(picked), "A3 the chosen boon is owned")
	expect_eq(game.state, RogueRun.State.DOORS, "A3 doors after the reward")
	var doors := game.room.get_children().filter(func(n: Node) -> bool: return n is RogueDoor)
	expect_gt(doors.size(), 0, "A3 doors appeared")
	await shot("a3_doors")
	await bot.walk_to((doors[0] as RogueDoor).global_position, 0.5)
	var next := await wait_until(func() -> bool: return game.run.depth == 1 and game.state == RogueRun.State.ROOM, 3.0)
	expect(next, "A3 walking into a door enters room 2")
