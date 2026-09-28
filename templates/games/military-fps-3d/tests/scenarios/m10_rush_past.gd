extends GbScenario
## M10 — running past an unfinished arena starts nothing ahead: the warehouse fight does not start while the courtyard
## fight is on, and the objective never goes back. Once the courtyard is cleared, the warehouse fight starts by itself
## with the player already standing in its doorway. (The player is made very tough; the courtyard is cleared by
## killing its soldiers directly.)


func run() -> void:
	var m := node(".") as MilMission
	var p := m.player
	await wait_frames(5)
	p.health.max_health = 100000.0
	p.health.current = 100000.0
	var stages: Array[int] = []
	m.stage_changed.connect(func(s: MilMission.Stage) -> void: stages.append(s))
	var bot := MilBot.new(self, m)
	await bot.walk_to(Vector3(0, 0, -13.2), 0.6)
	await wait_until(func() -> bool: return m.stage == MilMission.Stage.COURTYARD, 3.0)
	await bot.walk_to(Vector3(6, 0, -47.0), 0.6, 30.0)
	await wait(1.0)
	expect_lt(p.global_position.distance_to(Vector3(6, 0, -47.0)), 2.0, "M10 the player ran to the warehouse door")
	expect_eq(m.stage, MilMission.Stage.COURTYARD, "M10 the objective is still the courtyard")
	expect(not m.warehouse.active and m.warehouse.alive.is_empty(), "M10 the warehouse fight has not started")
	await wait_until(func() -> bool:
		for s in m.courtyard.alive.duplicate():
			if is_instance_valid(s) and s.alive:
				s.take_shot(1000.0, &"body", p.global_position)
		return m.courtyard.done, 20.0)
	expect(m.courtyard.done, "M10 the courtyard is cleared (both waves)")
	await wait_until(func() -> bool: return m.stage == MilMission.Stage.WAREHOUSE, 2.0)
	expect_eq(m.stage, MilMission.Stage.WAREHOUSE, "M10 standing in the doorway, the warehouse fight starts when it is its turn")
	var sorted := stages.duplicate()
	sorted.sort()
	expect_eq(stages, sorted, "M10 the objective only moved forward: %s" % [stages])
