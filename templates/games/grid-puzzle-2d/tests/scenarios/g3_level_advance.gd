extends GbScenario
## G3 — solving a level (with the solver's own solution, as real key taps) loads the next one after the delay.

const ACTIONS := {Vector2i.LEFT: "move_left", Vector2i.RIGHT: "move_right", Vector2i.UP: "move_up", Vector2i.DOWN: "move_down"}


func run() -> void:
	var board := get_tree().current_scene
	var set: LevelSet = board.get("level_set")
	for d in GridPuzzle.solve(set.rows(0)):
		await tap(ACTIONS[d])
	expect_eq(int(board.get("levels_solved")), 1, "G3 level 1 solved")
	expect((node("HUD/Message") as Label).visible, "G3 'level complete' message")
	var advanced := await wait_until(func() -> bool: return int(board.get("level_index")) == 1, 2.0)
	expect(advanced, "G3 level 2 loaded")
