extends GbScenario
## G1 — one press = one cell; holding the key does not keep moving; walls block and don't count.


func run() -> void:
	var board := get_tree().current_scene
	var p: GridPuzzle = board.get("puzzle")
	var start := p.player
	await press("move_right", 0.5)
	expect_eq(p.player, start + Vector2i.RIGHT, "G1 holding moves exactly one cell")
	await tap("move_up")
	expect_eq(p.player, start + Vector2i.RIGHT, "G1 a wall blocks")
	expect_eq(p.moves, 1, "G1 blocked moves are not counted")
