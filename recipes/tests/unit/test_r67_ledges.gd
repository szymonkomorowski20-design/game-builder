extends GutTest
## Recipe 67 — the ledge probe on real boxes: the first lip from the street, the next hold up from a hang, a roof's edge
## with room to stand, a plain wall (nothing), facing and reach limits, a crate top to step onto and one under a low
## ceiling, a lip too low to hang from, and a hold found under another hold (a cornice over a sill).

var _probe := LedgeProbe.new()


func _building() -> void:
	add_child_autofree(GreyboxBlock.make(Vector3(0, -0.5, 0), Vector3(60, 1, 60), Color.DIM_GRAY))
	add_child_autofree(GreyboxBlock.make(Vector3(0, 3, -3), Vector3(8, 6, 6), Color.GRAY))
	for seg: Array in [[2.2, -4.0, 4.0], [3.4, -4.0, 0.0], [3.4, 1.2, 4.0], [4.6, -4.0, 4.0]]:
		var top: float = seg[0]
		var x0: float = seg[1]
		var x1: float = seg[2]
		add_child_autofree(GreyboxBlock.make(Vector3((x0 + x1) * 0.5, top - 0.075, 0.06), Vector3(x1 - x0, 0.15, 0.12),
				Color.WHEAT))
	await wait_physics_frames(2)


func _space() -> PhysicsDirectSpaceState3D:
	return get_tree().root.get_world_3d().direct_space_state


func test_r67_holds_up_a_face() -> void:
	await _building()
	var fwd := Vector3(0, 0, -1)
	var through_lip := _probe.find(_space(), Vector3(-2, 0, 0.6), fwd, 0.475, 2.3)
	assert_eq(through_lip.get("kind"), &"lip", "a forward ray hitting the lip's front: still a lip (the face is the farthest hit)")
	assert_almost_eq(float(through_lip.get("top_y", 0.0)), 2.2, 0.01, "at 2.2")
	var first := _probe.find(_space(), Vector3(-2, 0, 0.6), fwd, 0.4, 2.3)
	assert_eq(first.get("kind"), &"lip", "from the street: a lip")
	assert_almost_eq(float(first.get("top_y", 0.0)), 2.2, 0.01, "the lowest hold in reach")
	assert_true(first.get("can_hang", false), "room to hang (feet 0.25 m above the street)")
	assert_false(first.get("can_stand", true), "nobody stands on a lip")
	assert_almost_eq(first.hang as Vector3, Vector3(-2, 0.25, 0.5), Vector3.ONE * 0.02, "hanging 0.5 m out, 1.95 m below the top")
	var next := _probe.find(_space(), first.hang, fwd, 2.2 + 0.45, 2.2 + 1.6)
	assert_almost_eq(float(next.get("top_y", 0.0)), 3.4, 0.01, "from the hang: the next hold up")
	var below := _probe.find(_space(), Vector3(-2, 4.6 - 1.95, 0.5), fwd, 4.6 - 1.6, 4.6 - 0.45)
	assert_almost_eq(float(below.get("top_y", 0.0)), 3.4, 0.01,
			"from the 4.6 hang, down: 3.4 (the search starts inside the hold being hung from)")
	var roof := _probe.find(_space(), Vector3(-2, 4.6 - 1.95, 0.5), fwd, 4.6 + 0.45, 4.6 + 1.6)
	assert_eq(roof.get("kind"), &"top", "above the last lip: the roof's edge")
	assert_almost_eq(float(roof.get("top_y", 0.0)), 6.0, 0.01, "at 6 m")
	assert_true(roof.get("can_stand", false), "with room to stand on the roof")
	assert_almost_eq((roof.stand as Vector3).z, -0.6, 0.02, "0.6 m in from the edge")


func test_r67_no_hold_facing_or_reach() -> void:
	await _building()
	assert_true(_probe.find(_space(), Vector3(-2, 0, 0.6), Vector3(0, 0, 1), 0.4, 2.3).is_empty(), "facing away: nothing")
	var at_60 := Vector3(sin(deg_to_rad(60.0)), 0, -cos(deg_to_rad(60.0)))
	assert_true(_probe.find(_space(), Vector3(-2, 0, 0.6), at_60, 0.4, 2.3).is_empty(), "60° off the wall: nothing")
	var at_30 := Vector3(sin(deg_to_rad(30.0)), 0, -cos(deg_to_rad(30.0)))
	assert_false(_probe.find(_space(), Vector3(-2, 0, 0.6), at_30, 0.4, 2.3).is_empty(), "30° off: still a hold")
	assert_true(_probe.find(_space(), Vector3(-2, 0, 1.6), Vector3(0, 0, -1), 0.4, 2.3).is_empty(), "1.6 m away: out of reach")
	assert_true(_probe.find(_space(), Vector3(-2, 0, 0.6), Vector3(0, 0, -1), 2.5, 3.2).is_empty(),
			"a window between holds: nothing (the wall's own top is out of reach)")


func test_r67_hold_under_a_hold() -> void:
	await _building()
	var fwd := Vector3(0, 0, -1)
	var right_part := _probe.find(_space(), Vector3(1.8, 1.45, 0.5), fwd, 2.4, 4.4)
	assert_almost_eq(float(right_part.get("top_y", 0.0)), 3.4, 0.01, "the 3.4 hold under the 4.6 cornice is found")
	var gap := _probe.find(_space(), Vector3(0.6, 1.45, 0.5), fwd, 2.4, 4.4)
	assert_true(gap.is_empty(), "in the gap of the 3.4 hold: nothing between 2.4 and 4.4")


func test_r67_crate_ceiling_and_low_lip() -> void:
	add_child_autofree(GreyboxBlock.make(Vector3(0, -0.5, 0), Vector3(60, 1, 60), Color.DIM_GRAY))
	add_child_autofree(GreyboxBlock.make(Vector3(0, 0.55, -0.75), Vector3(1.5, 1.1, 1.5), Color.WHEAT))
	add_child_autofree(GreyboxBlock.make(Vector3(6, 0.55, -0.75), Vector3(1.5, 1.1, 1.5), Color.WHEAT))
	add_child_autofree(GreyboxBlock.make(Vector3(6, 2.0, -0.75), Vector3(1.5, 0.3, 1.5), Color.GRAY))
	add_child_autofree(GreyboxBlock.make(Vector3(-8, 3, -3), Vector3(6, 6, 6), Color.GRAY))
	add_child_autofree(GreyboxBlock.make(Vector3(-8, 1.425, 0.06), Vector3(6, 0.15, 0.12), Color.WHEAT))
	await wait_physics_frames(2)
	var fwd := Vector3(0, 0, -1)
	var crate := _probe.find(_space(), Vector3(0, 0, 0.6), fwd, 0.4, 2.3)
	assert_eq(crate.get("kind"), &"top", "a crate: its own top")
	assert_almost_eq(float(crate.get("height", 0.0)), 1.1, 0.01, "1.1 m up")
	assert_true(crate.get("can_stand", false), "room to stand on it")
	var covered := _probe.find(_space(), Vector3(6, 0, 0.6), fwd, 0.4, 1.5)
	assert_almost_eq(float(covered.get("top_y", 0.0)), 1.1, 0.01, "a crate under a low shelf is still a top")
	assert_false(covered.get("can_stand", true), "but there is no room to stand on it")
	var low := _probe.find(_space(), Vector3(-8, 0, 0.6), fwd, 0.4, 2.3)
	assert_almost_eq(float(low.get("top_y", 0.0)), 1.5, 0.01, "a lip at 1.5 m")
	assert_false(low.get("can_hang", true), "too low to hang from: the feet would be under the street")


func test_r67_no_climbing_through_a_thin_wall() -> void:
	add_child_autofree(GreyboxBlock.make(Vector3(0, -0.5, 0), Vector3(60, 1, 60), Color.DIM_GRAY))
	add_child_autofree(GreyboxBlock.make(Vector3(0, 2, -0.04), Vector3(4, 4, 0.08), Color.GRAY))
	add_child_autofree(GreyboxBlock.make(Vector3(0, 0.6, -0.79), Vector3(1.4, 1.2, 1.4), Color.WHEAT))
	await wait_physics_frames(2)
	var through := _probe.find(_space(), Vector3(0, 0, 0.6), Vector3(0, 0, -1), 0.4, 2.3)
	assert_true(through.is_empty(), "a crate behind a 4 m wall is no hold (got %s)" % [through])
