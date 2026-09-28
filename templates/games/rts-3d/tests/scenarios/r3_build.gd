extends GbScenario
## R3 — building with the real hands (recipe 60 in the game): a worker selected, B then Q (a farm), the ghost over a
## free spot turns green, a click places the site and takes the wood, the worker walks over and builds it, and the
## finished farm raises the food cap by 6. Over a gold mine the ghost is red with its reason, and a click there places
## nothing and costs nothing.


func run() -> void:
	await load_scene("res://tests/fixtures/sandbox.tscn")
	var g := get_tree().current_scene as RtsGame
	var hands := RtsHands.new(self, g)
	var inp := hands.input
	await wait_frames(10)
	var worker := hands.team_units(0, &"worker")[0] as RtsUnit
	await hands.click(hands.screen_of(worker))
	expect_eq(inp.selection.selected, [worker] as Array[Object], "R3 one worker selected")
	await tap("build_menu")
	expect_eq(inp.mode, &"build_card", "R3 B opens the build card")
	await tap("cmd_1")
	expect(inp.mode == &"place" and inp.placing == &"farm", "R3 Q picks the farm")
	var spot := g.bases[0] + Vector3(9, 0, -2)
	await hands.move_mouse(hands.screen(spot))
	await wait_frames(2)
	expect_eq(inp.ghost_why, "", "R3 the ghost over a free spot is green")
	await shot("r3_ghost")
	var wood := g.stockpile(0).amount(&"wood")
	var cap := g.stockpile(0).supply_cap
	await hands.click(hands.screen(spot))
	var site := hands.team_building(0, &"farm")
	expect(site != null and not site.finished, "R3 the site is placed")
	expect_eq(g.stockpile(0).amount(&"wood"), wood - 60, "R3 it took the wood")
	expect_eq(worker.state_name(), "build", "R3 the worker goes to build it")
	await wait_until(func() -> bool: return site.finished, 40.0)
	expect(site.finished, "R3 the farm is finished")
	expect_eq(g.stockpile(0).supply_cap, cap + 6, "R3 food +6")
	# Over a gold mine: red, refused, free.
	await hands.click(hands.screen_of(worker))
	await tap("build_menu")
	await tap("cmd_1")
	var mine := hands.nearest_mine(&"gold", g.bases[0])
	await hands.move_mouse(hands.screen(mine.global_position))
	await wait_frames(2)
	expect_eq(inp.ghost_why, "blocked", "R3 the ghost over a mine is red: blocked")
	var sites := g.buildings.size()
	wood = g.stockpile(0).amount(&"wood")
	await hands.click(hands.screen(mine.global_position))
	expect_eq(g.buildings.size(), sites, "R3 nothing is placed there")
	expect_eq(g.stockpile(0).amount(&"wood"), wood, "R3 … and nothing is paid")
	expect_eq((g.get_node("HUD") as RtsHud).message_text, "Tu nie da się budować", "R3 the HUD says why")
	await tap("pause")
	expect_eq(inp.mode, &"normal", "R3 Esc leaves placing")
	# The tech tree: a stable needs a barracks — picked from the card, a click on free ground places nothing and says why.
	await hands.click(hands.screen_of(worker))
	await tap("build_menu")
	await tap("cmd_3")
	expect_eq(inp.placing, &"stable", "R3 E picks the stable")
	var free := g.bases[0] + Vector3(4, 0, -9)
	expect_eq(g.why_not_place(0, &"stable", g.grid.footprint_at(free, Vector2i(3, 3))), "", "R3 (the stable's spot is free and explored)")
	g.stockpile(0).add(&"gold", 500)
	g.stockpile(0).add(&"wood", 500)              # the tech is the only reason left
	sites = g.buildings.size()
	await hands.click(hands.screen(free))
	expect_eq(g.buildings.size(), sites, "R3 no stable without a barracks")
	expect_eq((g.get_node("HUD") as RtsHud).message_text, "Wymaga: Koszary", "R3 … and the HUD says what it needs")
	await tap("pause")
	# The farm is carved from the navigation mesh: a path past it goes around, not through.
	var a := site.global_position + Vector3(-3.5, 0, 0)
	var b := site.global_position + Vector3(3.5, 0, 0)
	var path := NavigationServer3D.map_get_path(g.nav.get_navigation_map(), a, b, true)
	var length := 0.0
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	expect_gt(length, a.distance_to(b) + 0.5, "R3 a path past the farm bends around it (%.1f m for %.1f straight)" % [length, a.distance_to(b)])
