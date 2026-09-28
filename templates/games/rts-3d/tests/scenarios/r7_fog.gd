extends GbScenario
## R7 — the fog of war (recipe 62 in the game): at the start the enemy's base is black and its units and buildings are
## hidden; a scout sent there reveals them; when it leaves, the enemy buildings stay drawn (seen once) but their units
## are hidden again; nothing can be built in unexplored ground.


func run() -> void:
	await load_scene("res://tests/fixtures/fog_sandbox.tscn")
	var g := get_tree().current_scene as RtsGame
	var hands := RtsHands.new(self, g)
	await wait_frames(10)
	var enemy_hall := hands.team_building(1, &"town_hall")
	var enemy_worker := hands.team_units(1, &"worker")[0] as RtsUnit
	expect(not enemy_hall.visible and not enemy_worker.visible, "R7 the enemy base starts hidden")
	expect_eq(g.why_not_place(0, &"farm", g.grid.footprint_at(g.bases[1] + Vector3(0, 0, 8), Vector2i(2, 2))), "unexplored", "R7 no building in the black")
	var scout := g.spawn_unit(0, &"rider", g.bases[0] + Vector3(6, 0, -6))
	scout.orders.give(RtsOrders.make(RtsOrders.Kind.MOVE, g.bases[1] + Vector3(-2, 0, 8)))
	var seen := await wait_until(func() -> bool: return enemy_hall.visible and enemy_worker.visible, 40.0)
	expect(seen, "R7 the scout reveals the enemy base and its workers")
	hands.input.rig.jump_to(g.bases[1])
	await wait_frames(3)
	await shot("r7_scouted")
	scout.orders.give(RtsOrders.make(RtsOrders.Kind.MOVE, g.bases[0]))
	await wait(12.0)
	expect(enemy_hall.visible, "R7 the enemy hall stays drawn after the scout leaves (seen once)")
	expect(not enemy_worker.visible, "R7 … but its units are hidden again")
	expect_eq(g.fog(0).state_at(enemy_hall.global_position), RtsFog.EXPLORED, "R7 the ground there is explored, not visible")
