extends GutTest
## R40 — camera-relative movement for any yaw; pitch clamped, yaw wrapped; mouse motion turns the camera only while
## allowed; invert_y flips the vertical direction.


func _cam() -> OrbitCamera:
	var cam := OrbitCamera.new()
	var pitch := Node3D.new()
	pitch.name = "Pitch"
	cam.add_child(pitch)
	add_child_autofree(cam)
	return cam


func test_r40_up_means_away_from_the_camera_for_any_yaw() -> void:
	var up := Vector2(0, -1)
	assert_true(OrbitCamera.camera_relative(up, 0.0).is_equal_approx(Vector3(0, 0, -1)), "yaw 0 → -Z")
	assert_true(OrbitCamera.camera_relative(up, PI / 2.0).is_equal_approx(Vector3(-1, 0, 0)), "yaw 90° left → -X")
	assert_true(OrbitCamera.camera_relative(up, PI).is_equal_approx(Vector3(0, 0, 1)), "yaw 180° → +Z")
	assert_true(OrbitCamera.camera_relative(Vector2(1, 0), PI / 2.0).is_equal_approx(Vector3(0, 0, -1)), "right at yaw 90° → -Z")
	assert_almost_eq(OrbitCamera.camera_relative(Vector2(0.6, -0.8), 1.0).length(), 1.0, 0.0001, "length is kept")


func test_r40_pitch_is_clamped_and_yaw_wraps() -> void:
	var cam := _cam()
	cam.orbit(0.0, -10.0)
	assert_almost_eq(cam.pitch, deg_to_rad(cam.min_pitch_deg), 0.0001, "cannot look further down than min_pitch")
	cam.orbit(0.0, 10.0)
	assert_almost_eq(cam.pitch, deg_to_rad(cam.max_pitch_deg), 0.0001, "cannot look further up than max_pitch")
	cam.orbit(3.0 * PI / 2.0, 0.0)
	assert_true(cam.yaw >= -PI and cam.yaw <= PI, "yaw stays in −π…π (%f)" % cam.yaw)
	assert_almost_eq(cam.rotation.y, cam.yaw, 0.0001, "the node carries the yaw")
	assert_almost_eq((cam.get_node("Pitch") as Node3D).rotation.x, cam.pitch, 0.0001, "Pitch carries the pitch")


func test_r40_mouse_motion_turns_only_when_allowed() -> void:
	var cam := _cam()
	var ev := InputEventMouseMotion.new()
	ev.screen_relative = Vector2(100, 0)
	cam.require_captured_mouse = true
	cam._unhandled_input(ev)   # the test runner's mouse is not captured
	assert_almost_eq(cam.yaw, 0.0, 0.0001, "no capture → no turn")
	cam.require_captured_mouse = false
	cam._unhandled_input(ev)
	assert_almost_eq(cam.yaw, -100.0 * cam.mouse_sensitivity, 0.0001, "moving the mouse right turns right (yaw decreases)")


func test_r40_invert_y() -> void:
	var cam := _cam()
	cam.require_captured_mouse = false
	var start := cam.pitch
	var ev := InputEventMouseMotion.new()
	ev.screen_relative = Vector2(0, 20)
	cam._unhandled_input(ev)
	assert_lt(cam.pitch, start, "mouse down looks down")
	cam.invert_y = true
	var mid := cam.pitch
	cam._unhandled_input(ev)
	assert_gt(cam.pitch, mid, "inverted: mouse down looks up")
