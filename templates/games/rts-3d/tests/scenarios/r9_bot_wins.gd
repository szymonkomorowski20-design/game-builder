extends GbScenario
## R9 — the skirmish can be won: a bot plays the player's side (recipe 64's brain with a counter-minded build order,
## the same rules and income as the player) against the computer at the default difficulty, and destroys every enemy
## building within 20 minutes. Its log every minute shows both economies and armies, for balance.

const GB_MINUTES := 25


func _line(g: RtsGame, t: int) -> String:
	var workers := 0
	var army := 0
	for u in g.units:
		if u.team == t:
			if u.is_worker():
				workers += 1
			else:
				army += 1
	var bs: Array[String] = []
	for b in g.buildings:
		if b.team == t:
			bs.append(String(b.kind).substr(0, 4) + ("" if b.finished else "*"))
	var s := g.stockpile(t)
	return "t%d: gold %d wood %d food %d/%d workers %d army %d [%s]" % [t, s.amount(&"gold"), s.amount(&"wood"), s.supply_used, s.supply_cap, workers, army, ",".join(bs)]


func run() -> void:
	await load_scene("res://tests/fixtures/bot_match.tscn")
	var g := get_tree().current_scene as RtsGame
	var minute := [0]                 # an array: a lambda captures a plain local by value
	var done := await wait_until(func() -> bool:
		if int(g.elapsed / 60.0) > minute[0]:
			minute[0] = int(g.elapsed / 60.0)
			note("%d min — %s | %s" % [minute[0], _line(g, 0), _line(g, 1)])
		return g.winner >= 0, 20.0 * 60.0)
	note("end %.0f s, winner %d — %s | %s" % [g.elapsed, g.winner, _line(g, 0), _line(g, 1)])
	expect(done, "R9 the match ends within 20 minutes")
	expect_eq(g.winner, 0, "R9 the bot wins")
