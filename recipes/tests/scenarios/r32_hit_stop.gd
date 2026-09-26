extends GbScenario
## R32 — hit-stop slows time, restores it after the real-time duration, and overlapping stops extend it.
## Counted in rendered frames (gb runs with --fixed-fps 60, so 1 frame = 1/60 s of real time).


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func run() -> void:
	await load_scene("res://main.tscn")
	var hs := HitStop.new()
	get_tree().root.add_child(hs)

	hs.stop(0.1)
	await frames(2)
	expect_near(Engine.time_scale, hs.slow_scale, 0.001, "R32 time slowed during hit-stop")
	await frames(10)
	expect_eq(Engine.time_scale, 1.0, "R32 time restored after 0.1 s of real time")

	hs.stop(0.1)
	await frames(3)
	hs.stop(0.2)   # a bigger hit during the first stop
	await frames(9)
	expect(hs.is_active(), "R32 first stop over, second still running")
	expect_near(Engine.time_scale, hs.slow_scale, 0.001, "R32 overlapping stop keeps time slowed")
	await frames(12)
	expect_eq(Engine.time_scale, 1.0, "R32 restored after the longest stop")
	hs.queue_free()
