extends GutTest
## R42 — ping-pong route along waypoints at constant speed; corners, the turn at the end, degenerate paths.

var path := PlatformPath.new(PackedVector2Array([Vector2(0, 0), Vector2(160, 0), Vector2(160, -80)]), 80.0)


func test_r42_length() -> void:
	assert_almost_eq(path.length(), 240.0, 0.001)


func test_r42_positions_along_the_way_out() -> void:
	assert_eq(path.position_at(0.0), Vector2(0, 0))
	assert_true(path.position_at(1.0).is_equal_approx(Vector2(80, 0)), "halfway along the first segment")
	assert_true(path.position_at(2.0).is_equal_approx(Vector2(160, 0)), "the corner")
	assert_true(path.position_at(2.5).is_equal_approx(Vector2(160, -40)), "up the second segment")
	assert_true(path.position_at(3.0).is_equal_approx(Vector2(160, -80)), "the end")


func test_r42_ping_pong_back_and_repeat() -> void:
	assert_true(path.position_at(3.5).is_equal_approx(Vector2(160, -40)), "on the way back")
	assert_true(path.position_at(5.0).is_equal_approx(Vector2(80, 0)), "back along the first segment")
	assert_true(path.position_at(6.0).is_equal_approx(Vector2(0, 0)), "home after 2 × length / speed")
	assert_true(path.position_at(7.0).is_equal_approx(Vector2(80, 0)), "and again")


func test_r42_degenerate_paths_stand_still() -> void:
	assert_eq(PlatformPath.new(PackedVector2Array([Vector2(5, 5)]), 80.0).position_at(3.0), Vector2(5, 5))
	assert_eq(PlatformPath.new(PackedVector2Array([Vector2(5, 5), Vector2(5, 5)]), 80.0).position_at(3.0), Vector2(5, 5))
	assert_eq(PlatformPath.new(PackedVector2Array([Vector2(1, 1), Vector2(9, 9)]), 0.0).position_at(3.0), Vector2(1, 1))
