extends GutTest
## R30 — walking, pushing, blocked pushes change nothing, undo restores exactly, solving fires once at the end.

const LEVEL := [
	"#######",
	"#@ $ .#",
	"#  $ .#",
	"#######",
]


func _p() -> GridPuzzle:
	return GridPuzzle.parse(PackedStringArray(LEVEL))


func test_r30_parse() -> void:
	var p := _p()
	assert_eq(p.player, Vector2i(1, 1))
	assert_eq(p.boxes.size(), 2)
	assert_eq(p.goals.size(), 2)


func test_r30_push_box() -> void:
	var p := _p()
	assert_true(p.move(Vector2i.RIGHT))
	assert_true(p.move(Vector2i.RIGHT), "push the box from x=3 to x=4")
	assert_true(p.boxes.has(Vector2i(4, 1)))
	assert_eq(p.player, Vector2i(3, 1))


func test_r30_blocked_push_changes_nothing() -> void:
	var p := _p()
	p.move(Vector2i.RIGHT)
	p.move(Vector2i.RIGHT)
	p.move(Vector2i.RIGHT)   # box to x=5 (goal)
	var before_moves := p.moves
	assert_false(p.move(Vector2i.RIGHT), "box against the wall")
	assert_eq(p.moves, before_moves)
	assert_false(p.move(Vector2i.UP), "wall")


func test_r30_undo_restores_exact_state() -> void:
	var p := _p()
	p.move(Vector2i.RIGHT)
	p.move(Vector2i.RIGHT)
	assert_true(p.undo())
	assert_true(p.undo())
	assert_eq(p.player, Vector2i(1, 1))
	assert_true(p.boxes.has(Vector2i(3, 1)) and p.boxes.has(Vector2i(3, 2)))
	assert_false(p.undo(), "nothing left to undo")


func test_r30_solution_solves_once() -> void:
	var p := _p()
	watch_signals(p)
	# first box onto its goal, walk round behind the second box, push it twice
	for d in [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
		p.move(d)
	assert_false(p.is_solved())
	p.move(Vector2i.RIGHT)
	assert_true(p.is_solved())
	assert_signal_emit_count(p, "solved", 1)
