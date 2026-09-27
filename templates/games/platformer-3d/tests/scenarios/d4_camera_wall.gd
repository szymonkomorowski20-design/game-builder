extends GbScenario
## D4 — the chase camera sits at the full spring length in the open, and moves in front of a wall that comes between
## it and the player (the pillar at x = 4, z = -2.5…-1.5) instead of looking from inside it.


func run() -> void:
	var player := node("Player") as Player
	var arm := player.get_node("CameraRig/SpringArm") as SpringArm3D
	var camera := arm.get_node("Camera") as Camera3D
	await wait(0.3)
	expect_near(arm.get_hit_length(), arm.spring_length, 0.01, "D4 in the open the camera is at the full spring length")
	await shot("camera_open")

	player.teleport(Vector3(4.0, 0.05, -4.5))   # the pillar is 2 m behind the player, between it and the camera
	await wait(0.3)
	expect_lt(arm.get_hit_length(), arm.spring_length - 1.0, "D4 the arm shortens against the pillar (%.2f m)" % arm.get_hit_length())
	expect_lt(camera.global_position.z, -2.5, "D4 the camera stays in front of the pillar, not inside or behind it (z %.2f)" % camera.global_position.z)
	await shot("camera_pillar")
