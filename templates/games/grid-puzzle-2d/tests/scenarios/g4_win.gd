extends GbScenario
## G4 — solving every level wins; the board looks right at the end (screenshot).

const ACTIONS := {Vector2i.LEFT: "move_left", Vector2i.RIGHT: "move_right", Vector2i.UP: "move_up", Vector2i.DOWN: "move_down"}


func run() -> void:
	var board := get_tree().current_scene
	var set: LevelSet = board.get("level_set")
	for i in set.count():
		await wait_until(func() -> bool: return int(board.get("level_index")) == i and not (node("HUD/Message") as Label).visible, 2.0)
		for d in GridPuzzle.solve(set.rows(i)):
			await tap(ACTIONS[d])
	expect(bool(board.get("won")), "G4 all levels solved → win")
	expect_eq(int(board.get("levels_solved")), set.count(), "G4 solved count")
	await shot("win")
