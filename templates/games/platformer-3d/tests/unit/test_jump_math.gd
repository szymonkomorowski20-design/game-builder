extends GutTest
## D2 — jump physics from height + time to apex (metres).


func test_d2_gravity_and_velocity_from_height_and_time() -> void:
	assert_almost_eq(JumpMath.gravity(1.6, 0.38), 2.0 * 1.6 / (0.38 * 0.38), 0.0001)
	assert_almost_eq(JumpMath.jump_velocity(1.6, 0.38), 2.0 * 1.6 / 0.38, 0.0001)


func test_d2_apex_round_trip_is_the_designed_height() -> void:
	var g := JumpMath.gravity(1.6, 0.38)
	var v := JumpMath.jump_velocity(1.6, 0.38)
	assert_almost_eq(JumpMath.apex_height(v, g), 1.6, 0.0001)


func test_d2_the_raised_platform_is_within_one_jump() -> void:
	# The course's raised platform is 1 m high; the default jump must clear it with margin for the capsule.
	var t: PlayerTuning = load("res://data/player_tuning.tres")
	assert_gt(t.jump_height, 1.0 + 0.3, "jump_height clears the 1 m platform")
