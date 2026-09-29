extends GbScenario
## S11 — witnesses and posters: the market guard is struck from behind in front of the crowd; the crowd panics, a
## townsperson's report raises notoriety after its delay (recipe 72), and the guards now notice faster; tearing down a
## wanted poster brings it back down.


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	var victim := bot.calm_guards(&"market")
	victim.process_mode = Node.PROCESS_MODE_DISABLED
	var p := game.player
	await wait_frames(5)

	p.teleport(Vector3(8.0, 0.05, 8.0))
	(p.get_node("Body") as Node3D).rotation.y = atan2(-1.0, -1.0)   # facing the guard's back (south-east)
	await wait(0.2)
	await tap("strike")
	expect(not victim.alive, "struck from behind")
	expect_eq(game.notoriety.pending_reports(), 1, "a townsperson saw it and runs to tell")
	var panic := false
	for c in game.civilians:
		if c.mind.mood == CrowdMind.Mood.PANIC:
			panic = true
	expect(panic, "the crowd nearby panics")
	expect_eq(game.notoriety.level(), 0, "not known yet")
	await wait(6.5)
	expect_eq(game.notoriety.level(), 1, "the report raises notoriety")
	expect_near(game.notice_scale(), 1.3, 1e-4, "and the guards notice faster")
	shot("s11_notorious")

	p.teleport(Vector3(25.0, 0.05, 6.0))
	await wait(0.2)
	await tap("action")
	expect_eq(game.notoriety.level(), 0, "a torn poster brings it down")
	expect_near(game.notice_scale(), 1.0, 1e-4, "and the guards back to normal")
