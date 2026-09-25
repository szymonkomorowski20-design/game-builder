extends GbScenario
## R15 — "pause" freezes the world and shows the menu; pressing it again resumes.


func run() -> void:
	await load_scene("res://15-pause/pause_demo.tscn")
	var spinner := node("Spinner")
	var menu := node("PauseMenu") as CanvasLayer
	await wait_frames(5)
	expect_gt(spinner.ticks, 0, "R15 world runs before pausing")
	expect(not menu.visible, "R15 menu hidden while playing")

	await tap("pause")
	expect(get_tree().paused, "R15 pause action pauses the tree")
	expect(menu.visible, "R15 menu visible while paused")
	var frozen: int = spinner.ticks
	await wait(0.5)
	expect_eq(spinner.ticks, frozen, "R15 world does not tick while paused")

	await tap("pause")
	expect(not get_tree().paused, "R15 second press resumes")
	await wait_frames(5)
	expect_gt(spinner.ticks, frozen, "R15 world ticks again after resume")
	get_tree().paused = false
