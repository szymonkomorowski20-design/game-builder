extends GbScenario
## M9 — the radio only works once the warehouse is cleared; holding E fills its progress, letting go resets it (a
## commitment under fire); holding it for hold_time plants the charge, sets the checkpoint and calls the
## reinforcements, who run in out of sight. (The mission is advanced to the radio by starting each zone in turn and
## killing its soldiers directly.)


func _clear(m: MilMission, zone: EncounterZone) -> void:
	zone.start()
	await wait_until(func() -> bool:
		for s in zone.alive.duplicate():
			if is_instance_valid(s) and s.alive:
				s.take_shot(1000.0, &"body", m.player.global_position)
		return zone.done, 20.0)


func run() -> void:
	var m := node(".") as MilMission
	var p := m.player
	await wait_frames(5)
	p.global_position = Vector3(-10, 0.05, -69.2)
	await wait_frames(3)
	hold("action")
	await wait(0.5)
	release("action")
	expect_eq(m.radio.progress, 0.0, "M9 the radio does nothing before the warehouse is cleared")
	await _clear(m, m.courtyard)
	await _clear(m, m.warehouse)
	await wait_frames(2)
	expect_eq(m.stage, MilMission.Stage.RADIO, "M9 the objective is the radio")
	expect_eq(m.objective_text(), "Zniszcz radiostację (przytrzymaj E)", "M9 the objective line says what to do")
	var unfair_before := m.unfair_spawns    # the shortcut above spawned arenas far from the player; count from here
	hold("action")
	await wait(m.radio.hold_time * 0.5)
	expect_near(m.radio.progress, 0.5, 0.05, "M9 holding fills the progress")
	await shot("m9_planting")
	release("action")
	await wait_frames(2)
	expect_eq(m.radio.progress, 0.0, "M9 letting go resets it")
	hold("action")
	await wait(m.radio.hold_time + 0.2)
	release("action")
	expect(m.radio.done, "M9 holding for hold_time plants the charge")
	expect_eq(m.stage, MilMission.Stage.REINFORCEMENTS, "M9 the reinforcements are called")
	expect_eq(m.checkpoints.active_order, m.extraction.order, "M9 the checkpoint moves to the radio")
	await wait_until(func() -> bool: return not m.extraction.alive.is_empty(), 6.0)
	expect_eq(m.extraction.alive.size(), m.extraction.waves[0], "M9 the reinforcements arrive")
	expect_eq(m.unfair_spawns - unfair_before, 0, "M9 the reinforcements run in out of sight")
