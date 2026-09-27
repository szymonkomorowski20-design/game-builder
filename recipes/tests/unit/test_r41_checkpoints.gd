extends GutTest
## R41 — respawn at the start before any checkpoint; a later checkpoint becomes the respawn point; touching an
## earlier one afterwards does not move it back; reset returns to the start; works with Vector3 too.


func test_r41_start_until_a_checkpoint_is_reached() -> void:
	var t := CheckpointTracker.new(Vector2(10, 20))
	assert_eq(t.respawn_position, Vector2(10, 20))
	assert_eq(t.active_order, -1)


func test_r41_later_checkpoint_wins_earlier_does_not_move_it_back() -> void:
	var t := CheckpointTracker.new(Vector2.ZERO)
	assert_true(t.reach(0, Vector2(100, 0)), "first checkpoint becomes active")
	assert_true(t.reach(2, Vector2(300, 0)), "a later one replaces it")
	assert_false(t.reach(1, Vector2(200, 0)), "an earlier one does not move the respawn back")
	assert_false(t.reach(2, Vector2(999, 0)), "touching the active one again changes nothing")
	assert_eq(t.respawn_position, Vector2(300, 0))
	assert_eq(t.active_order, 2)


func test_r41_signal_only_on_a_new_checkpoint() -> void:
	var t := CheckpointTracker.new(Vector2.ZERO)
	watch_signals(t)
	t.reach(0, Vector2(1, 0))
	t.reach(0, Vector2(1, 0))
	assert_signal_emit_count(t, "activated", 1)


func test_r41_reset_and_3d() -> void:
	var t := CheckpointTracker.new(Vector3(0, 1, 0))
	t.reach(0, Vector3(5, 1, -10))
	assert_eq(t.respawn_position, Vector3(5, 1, -10))
	t.reset()
	assert_eq(t.respawn_position, Vector3(0, 1, 0))
	assert_eq(t.active_order, -1)
