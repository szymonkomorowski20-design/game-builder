extends GbScenario
## R02 — the camera stays inside its limits and does not move while the target is inside the drag margins.


func run() -> void:
	await load_scene("res://02-camera-follow/camera_follow.tscn")
	var mover := node("Mover") as Node2D
	var cam := node("Mover/Camera2D") as Camera2D
	await wait_frames(3)
	var before := cam.get_screen_center_position()
	mover.position.x += 20.0
	await wait_frames(3)
	expect_near(cam.get_screen_center_position().x, before.x, 0.5, "R02 small move inside the drag margin does not move the camera")
	mover.position = Vector2(10.0, 10.0)
	await wait_frames(3)
	var half := cam.get_viewport_rect().size / 2.0
	expect_near(cam.get_screen_center_position().x, half.x, 0.5, "R02 camera clamped to limit_left")
	expect_near(cam.get_screen_center_position().y, half.y, 0.5, "R02 camera clamped to limit_top")
