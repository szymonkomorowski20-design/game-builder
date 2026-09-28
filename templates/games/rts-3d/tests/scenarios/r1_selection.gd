extends GbScenario
## R1 — selection with the real mouse (recipe 58 in the game): a drag box around the workers and the town hall takes
## the four workers, not the hall (units over buildings); a click takes the hall alone; Ctrl+1 stores the workers and 1
## brings them back after a click on empty ground; a double-click on a worker takes every worker on screen; the HUD
## shows the selection.


func run() -> void:
	await load_scene("res://tests/fixtures/sandbox.tscn")
	var g := get_tree().current_scene as RtsGame
	var hands := RtsHands.new(self, g)
	var inp := hands.input
	await wait_frames(10)
	var workers := hands.team_units(0, &"worker")
	var hall := hands.team_building(0, &"town_hall")
	expect_eq(workers.size(), 4, "R1 four workers to start")
	var all_nodes: Array = []
	all_nodes.append_array(workers)
	all_nodes.append(hall)
	await hands.box_select(all_nodes)
	expect_eq(inp.selection.selected.size(), 4, "R1 the box takes the four workers")
	expect(not inp.selection.selected.has(hall), "R1 … not the town hall (units over buildings)")
	expect((g.get_node("HUD") as RtsHud)._panel_text().contains("Robotnik ×4"), "R1 the HUD shows them")
	await hands.key(KEY_1, true)
	await hands.click(hands.screen_of(hall))
	expect_eq(inp.selection.selected, [hall] as Array[Object], "R1 a click takes the hall alone")
	await hands.click(hands.screen(g.bases[0] + Vector3(10, 0, -12)))
	expect(inp.selection.selected.is_empty(), "R1 a click on empty ground clears")
	await hands.key(KEY_1)
	expect_eq(inp.selection.selected.size(), 4, "R1 1 brings the group back")
	await hands.click(hands.screen(g.bases[0] + Vector3(10, 0, -12)))
	await hands.click(hands.screen_of(workers[0]), false, true)
	expect_eq(inp.selection.selected.size(), 4, "R1 a double-click takes every worker on screen")
	await shot("r1_selection")
