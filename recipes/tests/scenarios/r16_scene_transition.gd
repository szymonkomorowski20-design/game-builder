extends GbScenario
## R16 — the router fades to black, swaps the scene, fades back; a second request while busy is refused;
## a missing path is refused without touching the current scene.


func run() -> void:
	await load_scene("res://16-scene-transitions/room_a.tscn")
	var router := SceneRouter.new()
	router.fade_time = 0.1
	get_tree().root.add_child(router)
	await wait_frames(1)

	expect(not await router.change_to("res://16-scene-transitions/" + "missing.tscn"), "R16 missing scene refused")
	expect_eq(get_tree().current_scene.name, "RoomA", "R16 still in room A after a refused change")

	router.change_to("res://16-scene-transitions/room_b.tscn")
	await wait(0.05)
	expect(router.busy, "R16 router busy during the transition")
	expect(not await router.change_to("res://16-scene-transitions/room_a.tscn"), "R16 second change while busy refused")
	expect_gt(router.alpha(), 0.0, "R16 screen is fading out")
	var done := await wait_until(func(): return not router.busy, 3.0)
	expect(done, "R16 transition finishes")
	expect_eq(get_tree().current_scene.name, "RoomB", "R16 now in room B")
	expect_near(router.alpha(), 0.0, 0.01, "R16 faded back in")
	router.queue_free()
