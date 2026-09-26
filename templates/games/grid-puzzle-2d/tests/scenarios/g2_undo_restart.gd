extends GbScenario
## G2 — action undoes the last move (including a push); jump restarts the level.


func run() -> void:
	var board := get_tree().current_scene
	var p: GridPuzzle = board.get("puzzle")
	await tap("move_right")
	await tap("move_right")
	expect(p.boxes.has(Vector2i(4, 1)), "G2 the box was pushed")
	await tap("action")
	expect(p.boxes.has(Vector2i(3, 1)), "G2 undo puts the box back")
	expect_eq(p.moves, 1, "G2 undo removes one move")
	await tap("jump")
	var fresh: GridPuzzle = board.get("puzzle")
	expect_eq(fresh.moves, 0, "G2 restart resets moves")
	expect_eq(fresh.player, Vector2i(1, 1), "G2 restart resets the player")
