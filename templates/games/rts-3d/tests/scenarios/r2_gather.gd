extends GbScenario
## R2 — gathering (recipe 59 in the game): the four workers, right-clicked onto the nearest gold mine, walk, gather and
## bring gold to the town hall; in a minute the stockpile grows by what `income_per_minute` predicts for that trip
## (within the walking and crowding a formula can't see); a worker ordered away keeps its load; wood works the same.


func run() -> void:
	await load_scene("res://tests/fixtures/sandbox.tscn")
	var g := get_tree().current_scene as RtsGame
	var hands := RtsHands.new(self, g)
	await wait_frames(10)
	var workers := hands.team_units(0, &"worker")
	var hall := hands.team_building(0, &"town_hall")
	var mine := hands.nearest_mine(&"gold", hall.global_position)
	await hands.box_select(workers)
	await hands.right_click(hands.screen_of(mine))
	for w in workers:
		expect_eq((w as RtsUnit).state_name(), "gather", "R2 %s gathers" % w.name)
	var gold0 := g.stockpile(0).amount(&"gold")
	await wait(60.0)
	var got := g.stockpile(0).amount(&"gold") - gold0
	var rules := g.rules.unit(&"worker")
	var trip := maxf(hall.edge_distance(mine.global_position) - mine.radius - 2.0 * (float(rules.radius) + 0.6), 0.5)
	var predicted := RtsResourceNode.income_per_minute(4, trip, float(rules.speed), float(rules.gather_time), int(rules.carry), int(g.rules.resources[&"gold"].slots))
	note("gold in a minute: %d (predicted %.0f for a %.1f m trip)" % [got, predicted, trip])
	expect_gt(got, predicted * 0.6, "R2 a minute's gold is near the prediction (%d of %.0f)" % [got, predicted])
	expect_lt(got, predicted * 1.3, "R2 … and not above it (%d of %.0f)" % [got, predicted])
	var w0 := workers[0] as RtsUnit
	await wait_until(func() -> bool: return w0.gatherer.carrying > 0, 10.0)
	var load := w0.gatherer.carrying
	w0.orders.give(RtsOrders.make(RtsOrders.Kind.MOVE, w0.global_position + Vector3(3, 0, 0)))
	await wait(1.0)
	expect_eq(w0.gatherer.carrying, load, "R2 a worker ordered away keeps its load")
	var tree := hands.nearest_mine(&"wood", hall.global_position)
	var wood0 := g.stockpile(0).amount(&"wood")
	w0.orders.give(RtsOrders.make(RtsOrders.Kind.GATHER, tree.global_position, tree))
	await wait(30.0)
	expect_gt(g.stockpile(0).amount(&"wood"), wood0, "R2 wood comes in too")
	await shot("r2_gather")
