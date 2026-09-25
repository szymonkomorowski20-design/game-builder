extends GbScenario
## R04 — on screen, far layers move less than near layers when the camera moves (Parallax2D, 4.3+).
## Parallax2D overrides its own position (docs: class_parallax2d), so the test measures where the
## layer lands ON SCREEN (canvas transform), not its screen_offset (shared by all layers).


func _screen_x(n: Node2D) -> float:
	return n.get_global_transform_with_canvas().origin.x


func run() -> void:
	expect(ClassDB.class_exists("Parallax2D"), "R04 Parallax2D exists in this Godot version")
	await load_scene("res://04-parallax/parallax.tscn")
	var cam := node("Camera2D") as Camera2D
	var far := node("Far") as Parallax2D
	var near := node("Near") as Parallax2D
	await wait_frames(2)
	var far0 := _screen_x(far)
	var near0 := _screen_x(near)
	cam.position.x += 100.0
	await wait_frames(3)
	var dfar := absf(_screen_x(far) - far0)
	var dnear := absf(_screen_x(near) - near0)
	expect_near(dfar, 100.0 * far.scroll_scale.x, 1.0, "R04 far layer moves scroll_scale × camera distance on screen")
	expect_near(dnear, 100.0 * near.scroll_scale.x, 1.0, "R04 near layer moves scroll_scale × camera distance on screen")
	expect_lt(dfar, dnear, "R04 far layer moves less than near")
