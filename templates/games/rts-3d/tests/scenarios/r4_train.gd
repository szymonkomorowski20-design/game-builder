extends GbScenario
## R4 — production (recipe 60 in the game): the town hall clicked, Q three times queues three workers and takes their
## gold at once; they come out one by one after their time and walk to the rally point (a right click on the ground);
## a queue past the food cap waits, and the HUD says to build a farm (once).


func run() -> void:
	await load_scene("res://tests/fixtures/sandbox.tscn")
	var g := get_tree().current_scene as RtsGame
	var hands := RtsHands.new(self, g)
	await wait_frames(10)
	var hall := hands.team_building(0, &"town_hall")
	await hands.click(hands.screen_of(hall))
	var rally := g.bases[0] + Vector3(6, 0, -8)
	await hands.right_click(hands.screen(rally))
	expect_lt(hall.rally_point.distance_to(rally), 0.5, "R4 a right click sets the rally point")
	var gold := g.stockpile(0).amount(&"gold")
	for i in 3:
		await tap("cmd_1")
	expect_eq(hall.production.queue.size(), 3, "R4 three queued")
	expect_eq(g.stockpile(0).amount(&"gold"), gold - 150, "R4 paid at once")
	var before := hands.team_units(0, &"worker").size()
	await wait(8.5)
	expect_eq(hands.team_units(0, &"worker").size(), before + 1, "R4 the first after 8 s")
	await wait(17.0)
	expect_eq(hands.team_units(0, &"worker").size(), before + 3, "R4 all three after 24 s")
	await wait(4.0)
	var newest := hands.team_units(0, &"worker").back() as RtsUnit
	expect_lt(newest.global_position.distance_to(rally), 3.0, "R4 they walk to the rally point")
	# Food: 7 of 10 used; three more need 10 → the third waits.
	g.stockpile(0).add(&"gold", 500)
	for i in 4:
		await tap("cmd_1")
	await wait(30.0)
	expect(hall.production.is_blocked(), "R4 a queue past the food cap waits")
	expect_eq(g.stockpile(0).supply_used, 10, "R4 at the cap, not past it")
	await shot("r4_blocked")
