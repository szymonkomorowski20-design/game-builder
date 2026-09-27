extends GbScenario
## R50 — the bot plays the run loop with real keys: the first room offers one door, three rooms later it dies, the
## hub shows the banked currency, it buys an upgrade, and the next run starts at room 1 with more max health.


func run() -> void:
	await load_scene("res://50-run-meta/run_demo.tscn")
	var demo := node(".") as RunDemo
	await wait_frames(3)
	expect_eq(demo.doors.size(), 1, "R50 the first room has one door (combat + boon)")
	for i in 3:
		await tap("action")
	expect_eq(demo.run.depth, 3, "R50 three rooms entered")
	var collected := demo.run.collected
	expect_gt(collected, 0, "R50 the run collected currency")
	await tap("jump")
	expect(demo.in_hub, "R50 dying returns to the hub")
	expect_eq(demo.meta.currency, collected, "R50 everything collected is banked")
	var health_before := demo.sheet.value(&"max_health")
	await tap("action")
	expect_eq(demo.meta.level(&"vitality"), 1, "R50 an upgrade was bought in the hub")
	await tap("jump")
	expect(not demo.in_hub, "R50 a new run started")
	expect_eq(demo.run.depth, 0, "R50 the new run starts at the first room")
	expect_near(demo.sheet.value(&"max_health"), health_before + 10.0, 1e-4, "R50 the new run is stronger")
	await shot("run_meta")
