extends GutTest
## Recipe 56 — aim assist: slowdown inside the cone, pull only while the stick moves, range and choice of target.

var eye := Vector3.ZERO
var fwd := Vector3(0, 0, -1)


func _point_at(yaw_deg: float, dist: float = 10.0) -> Vector3:
	return Vector3(sin(deg_to_rad(yaw_deg)), 0, -cos(deg_to_rad(yaw_deg))) * dist


func test_r56_slowdown_scales_with_angle() -> void:
	var a := AimAssist.new()
	var none: Array[Vector3] = [_point_at(20.0)]
	assert_eq(a.slowdown(eye, fwd, none), 1.0, "outside the cone: no slowdown")
	var centre: Array[Vector3] = [_point_at(0.0)]
	assert_almost_eq(a.slowdown(eye, fwd, centre), a.min_scale, 1e-4, "on the target: the minimum")
	var half: Array[Vector3] = [_point_at(a.cone * 0.5)]
	assert_almost_eq(a.slowdown(eye, fwd, half), lerpf(a.min_scale, 1.0, 0.5), 1e-3, "halfway: halfway")
	var far: Array[Vector3] = [_point_at(0.0, a.max_range + 5.0)]
	assert_eq(a.slowdown(eye, fwd, far), 1.0, "beyond max_range: nothing")


func test_r56_pull_only_while_the_stick_moves() -> void:
	var a := AimAssist.new()
	var right: Array[Vector3] = [_point_at(3.0)]
	assert_eq(a.pull(eye, fwd, Basis(), right, Vector2.ZERO, 0.1), Vector2.ZERO, "idle stick: the gun never aims itself")
	var p := a.pull(eye, fwd, Basis(), right, Vector2(1, 0), 0.1)
	assert_gt(p.x, 0.0, "a target to the right pulls right")
	assert_true(p.length() <= a.pull_speed * 0.1 + 1e-4, "no more than pull_speed per second")
	var tiny := a.pull(eye, fwd, Basis(), right, Vector2(1, 0), 10.0)
	assert_almost_eq(tiny.x, 3.0, 0.05, "never past the target")


func test_r56_picks_the_closest_to_the_crosshair() -> void:
	var a := AimAssist.new()
	var two: Array[Vector3] = [_point_at(4.0), _point_at(-1.0)]
	assert_almost_eq((a.best_target(eye, fwd, two) as Vector3).x, _point_at(-1.0).x, 1e-4)
