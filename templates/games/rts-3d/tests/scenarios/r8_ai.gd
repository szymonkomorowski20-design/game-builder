extends GbScenario
## R8 — the computer player alone (recipe 64 in the game; the player does nothing): it keeps its workers busy, builds
## farms before its supply runs out, a barracks and a stable, trains an army, and by six minutes sends a wave that
## reaches the player's base (the player hears "Jesteśmy atakowani!").

const GB_MINUTES := 9


func run() -> void:
	await load_scene("res://scenes/skirmish/skirmish.tscn")
	var g := get_tree().current_scene as RtsGame
	var hands := RtsHands.new(self, g)
	var ai := g.get_node("AI") as RtsAiPlayer
	var attacked := [false]
	g.alert.connect(func(_at: Vector3) -> void: attacked[0] = true)
	await wait(180.0)
	var workers := hands.team_units(1, &"worker")
	var busy := workers.filter(func(u: RtsUnit) -> bool: return not u.orders.idle()).size()
	note("3 min: workers %d (busy %d), gold %d wood %d food %d/%d" % [workers.size(), busy, g.stockpile(1).amount(&"gold"), g.stockpile(1).amount(&"wood"), g.stockpile(1).supply_used, g.stockpile(1).supply_cap])
	expect_gt(workers.size(), 9, "R8 it trains workers")
	expect_gt(busy, workers.size() - 2, "R8 … and keeps them busy")
	expect(hands.team_building(1, &"barracks") != null and hands.team_building(1, &"barracks").finished, "R8 a barracks by 3 minutes")
	expect_gt(g.stockpile(1).supply_cap, 10, "R8 farms raise its food")
	var came := await wait_until(func() -> bool: return attacked[0], 240.0)
	note("wave: sent %d, elapsed %.0f s" % [ai.waves_sent(), g.elapsed])
	expect(ai.waves_sent() >= 1, "R8 it sends a wave")
	expect(came, "R8 the wave reaches the player's base by 7 minutes")
