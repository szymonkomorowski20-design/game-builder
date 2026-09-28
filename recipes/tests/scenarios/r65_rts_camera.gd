extends GbScenario
## R65 — the RTS camera in the engine: holding a pan action moves the pivot at the tuned speed; it stops at the bounds;
## the wheel zooms only between its limits; jump_to centres a point; the screen's centre looks at the pivot on the
## ground (ground_point), so clicks and drag boxes land where the player sees them.


func run() -> void:
	await load_scene("res://65-rts-camera/rts_camera_demo.tscn")
	var rig := node("Rig") as RtsCamera
	await wait_frames(3)
	var x0 := rig.position.x
	await press("move_right", 1.0)
	var expected := rig.pan_speed * rig.distance / 20.0
	expect_near(rig.position.x - x0, expected, expected * 0.1, "one second of panning covers the tuned distance")
	await press("move_right", 10.0)
	expect_near(rig.position.x, 30.0, 0.001, "stops at the bounds")
	for i in 20:
		rig.zoom(5.0)
	expect_near(rig.distance, rig.max_distance, 0.001, "zoom out stops at its limit")
	for i in 20:
		rig.zoom(-5.0)
	expect_near(rig.distance, rig.min_distance, 0.001, "zoom in stops at its limit")
	rig.jump_to(Vector3(-12, 0, 7))
	await wait_frames(2)
	var centre := rig.ground_point(get_viewport().get_visible_rect().size * 0.5)
	expect_lt(centre.distance_to(Vector3(-12, 0, 7)), 0.05, "the screen's centre looks at the pivot on the ground (%s)" % centre)
