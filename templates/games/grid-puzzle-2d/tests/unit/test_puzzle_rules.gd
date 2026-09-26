extends GutTest
## Rules and levels: pushing, blocked moves, undo, win; every shipped level is solvable (BFS) within its par.

const LEVELS := preload("res://data/levels.tres")
## Par = shortest solution length found by the solver. A level change that makes it longer or unsolvable fails here.
const PAR := [3, 7, 9]


func test_push_and_blocked() -> void:
	var p := GridPuzzle.parse(PackedStringArray(["#######", "#@ $ .#", "#######"]))
	assert_true(p.move(Vector2i.RIGHT))
	assert_true(p.move(Vector2i.RIGHT), "push")
	assert_true(p.boxes.has(Vector2i(4, 1)))
	assert_false(p.move(Vector2i.UP), "wall")
	p.move(Vector2i.RIGHT)
	assert_false(p.move(Vector2i.RIGHT), "box against the wall")
	assert_eq(p.moves, 3, "blocked moves are not counted")
	assert_true(p.is_solved())


func test_undo_restores_exactly() -> void:
	var p := GridPuzzle.parse(PackedStringArray(["#######", "#@ $ .#", "#######"]))
	p.move(Vector2i.RIGHT)
	p.move(Vector2i.RIGHT)
	p.undo()
	p.undo()
	assert_eq(p.player, Vector2i(1, 1))
	assert_true(p.boxes.has(Vector2i(3, 1)))
	assert_eq(p.moves, 0)
	assert_false(p.undo())


func test_every_level_is_solvable_within_par() -> void:
	assert_eq(LEVELS.count(), PAR.size(), "a par for every level")
	for i in LEVELS.count():
		var solution := GridPuzzle.solve(LEVELS.rows(i))
		assert_false(solution.is_empty(), "level %d is solvable" % (i + 1))
		assert_eq(solution.size(), PAR[i], "level %d par" % (i + 1))
		var p := GridPuzzle.parse(LEVELS.rows(i))
		for d in solution:
			p.move(d)
		assert_true(p.is_solved(), "level %d: replaying the solution solves it" % (i + 1))


func test_unsolvable_level_detected() -> void:
	# box in a corner that is not a goal
	assert_true(GridPuzzle.solve(PackedStringArray(["#####", "#$  #", "#  @#", "# . #", "#####"])).is_empty())
