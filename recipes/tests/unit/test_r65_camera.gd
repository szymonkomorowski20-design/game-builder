extends GutTest
## R65 — the RTS camera's rules: the screen edges pan (and corners diagonally, at the same speed), the pan speed grows
## with the zoom, the pivot stays inside the bounds.


func test_r65_edges() -> void:
	var size := Vector2(1280, 720)
	assert_eq(RtsCamera.edge_direction(Vector2(640, 360), size, 12.0), Vector2.ZERO, "the middle: still")
	assert_eq(RtsCamera.edge_direction(Vector2(5, 360), size, 12.0), Vector2(-1, 0), "left edge")
	assert_eq(RtsCamera.edge_direction(Vector2(640, 715), size, 12.0), Vector2(0, 1), "bottom edge: toward the viewer")
	var corner := RtsCamera.edge_direction(Vector2(1279, 0), size, 12.0)
	assert_almost_eq(corner.length(), 1.0, 0.0001, "a corner: diagonal, not faster")


func test_r65_pan_speed_follows_the_zoom() -> void:
	var near := RtsCamera.pan_step(Vector2.RIGHT, 18.0, 10.0, 1.0)
	var far := RtsCamera.pan_step(Vector2.RIGHT, 18.0, 40.0, 1.0)
	assert_almost_eq(far.x, near.x * 4.0, 0.001, "zoomed out 4×: pans 4× as fast")
	assert_almost_eq(RtsCamera.pan_step(Vector2(1, 1), 10.0, 20.0, 1.0).length(), 10.0, 0.001, "diagonal keys: the same speed")


func test_r65_bounds() -> void:
	var r := Rect2(-10, -20, 20, 40)
	assert_eq(RtsCamera.clamp_to(Vector3(50, 3, -50), r), Vector3(10, 3, -20))
	assert_eq(RtsCamera.clamp_to(Vector3(1, 0, 2), r), Vector3(1, 0, 2))
