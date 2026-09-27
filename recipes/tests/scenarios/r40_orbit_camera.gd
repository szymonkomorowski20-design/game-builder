extends GbScenario
## R40 — after turning the camera 90° left with the mouse, "up" walks the mover toward -X (away from the camera),
## the camera follows it, and the spring arm is at its full length in the open.


func run() -> void:
	await load_scene("res://40-orbit-camera-3d/orbit_demo.tscn")
	var cam := node("Orbit") as OrbitCamera
	var mover := node("Mover") as OrbitMover
	cam.require_captured_mouse = false
	await wait(0.3)
	var ev := InputEventMouseMotion.new()
	ev.screen_relative = Vector2(-(PI / 2.0) / cam.mouse_sensitivity, 0.0)
	ev.relative = ev.screen_relative   # what a stretched viewport would scale — the recipe must not use it
	Input.parse_input_event(ev)
	await wait_frames(2)
	expect_near(cam.yaw, PI / 2.0, 0.001, "R40 the mouse turned the camera 90° left")
	var start := mover.global_position
	await press("move_up", 0.5)
	var moved := mover.global_position - start
	expect_lt(moved.x, -1.5, "R40 up walks toward -X after the turn (moved %s)" % moved)
	expect_near(moved.z, 0.0, 0.05, "R40 no drift along Z")
	await wait_frames(2)
	expect_near(cam.global_position.x, mover.global_position.x, 0.01, "R40 the camera follows the mover")
	var arm := node("Orbit/Pitch/Arm") as SpringArm3D
	expect_near(arm.get_hit_length(), arm.spring_length, 0.01, "R40 nothing between camera and mover → full arm")
