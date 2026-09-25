extends GutTest
## P2 — jump physics from height + time to apex.


func test_p2_gravity_and_velocity_from_height_and_time() -> void:
	assert_almost_eq(JumpMath.gravity(72.0, 0.38), 2.0 * 72.0 / (0.38 * 0.38), 0.001)
	assert_almost_eq(JumpMath.jump_velocity(72.0, 0.38), 2.0 * 72.0 / 0.38, 0.001)


func test_p2_apex_round_trip_is_the_designed_height() -> void:
	var g := JumpMath.gravity(72.0, 0.38)
	var v := JumpMath.jump_velocity(72.0, 0.38)
	assert_almost_eq(JumpMath.apex_height(v, g), 72.0, 0.001)


func test_p2_shorter_time_to_apex_means_stronger_gravity() -> void:
	assert_gt(JumpMath.gravity(72.0, 0.3), JumpMath.gravity(72.0, 0.4))
