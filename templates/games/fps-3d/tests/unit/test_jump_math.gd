extends GutTest
## F-unit — jump physics from height + time to apex (metres).


func test_f_gravity_and_velocity_from_height_and_time() -> void:
	assert_almost_eq(JumpMath.gravity(1.2, 0.35), 2.0 * 1.2 / (0.35 * 0.35), 0.0001)
	assert_almost_eq(JumpMath.jump_velocity(1.2, 0.35), 2.0 * 1.2 / 0.35, 0.0001)


func test_f_apex_round_trip_is_the_designed_height() -> void:
	var g := JumpMath.gravity(1.2, 0.35)
	var v := JumpMath.jump_velocity(1.2, 0.35)
	assert_almost_eq(JumpMath.apex_height(v, g), 1.2, 0.0001)


