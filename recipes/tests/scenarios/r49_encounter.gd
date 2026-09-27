extends GbScenario
## R49 — a room at depth 4 runs its planned waves in order: the bot defeats the enemies one by one (demo stand-in
## for combat), the next wave appears only after the previous one is gone, and the door opens after the last.


func run() -> void:
	await load_scene("res://49-encounter-director/encounter_demo.tscn")
	var demo := node(".") as EncounterDemo
	await wait_frames(3)
	var planned := demo.director.current_plan.size()
	expect_eq(planned, 2, "R49 depth 4 → two waves")
	expect_eq(demo.waves_seen, 1, "R49 only the first wave at the start")
	var total := 0
	for wave in demo.director.current_plan:
		total += wave.size()
	for i in total:
		expect(not demo.door_open, "R49 door shut while enemies remain (%d defeated)" % i)
		var ok := await wait_until(func() -> bool: return not demo.enemies.is_empty(), 2.0)
		expect(ok, "R49 an enemy is there to fight")
		await tap("action")
	await wait_frames(2)
	expect_eq(demo.waves_seen, planned, "R49 every planned wave appeared")
	expect(demo.door_open, "R49 the door opens after the last enemy")
	await shot("encounter")
