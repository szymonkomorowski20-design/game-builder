extends GbScenario
## M7 — dying in the courtyard shows the death screen, then puts the player back at the courtyard's checkpoint with
## full health; the unfinished fight is reset (its soldiers gone, the objective back to "go through the gate"), and
## walking in again starts it over. Deaths are counted.


func run() -> void:
	var m := node(".") as MilMission
	var p := m.player
	await wait_frames(5)
	var bot := MilBot.new(self, m)
	await bot.walk_to(Vector3(0, 0, -13.2), 0.6)
	await wait_until(func() -> bool: return m.stage == MilMission.Stage.COURTYARD, 3.0)
	var checkpoint := m.courtyard.checkpoint_position()
	p.take_hit(1000.0, p.global_position + Vector3(0, 1.5, -10))
	await wait_frames(2)
	expect(not p.alive, "M7 the player is dead")
	expect(not p.controls_enabled, "M7 no control while dead")
	await shot("m7_dead")
	await wait(m.respawn_delay + 0.2)
	expect(p.alive, "M7 alive again after respawn_delay")
	expect_lt(Vector2(p.global_position.x - checkpoint.x, p.global_position.z - checkpoint.z).length(), 0.3, "M7 at the courtyard checkpoint")
	expect_near(p.health.current, p.tuning.max_health, 0.01, "M7 with full health")
	expect_eq(m.deaths, 1, "M7 one death counted")
	expect_eq(m.stage, MilMission.Stage.GATE, "M7 the objective is the gate again")
	await wait_frames(2)
	expect_eq(get_tree().get_nodes_in_group(&"soldiers").size(), 0, "M7 the unfinished fight's soldiers are gone")
	await bot.walk_to(Vector3(0, 0, -13.2), 0.6)
	await wait_until(func() -> bool: return m.stage == MilMission.Stage.COURTYARD, 3.0)
	expect_eq(m.stage, MilMission.Stage.COURTYARD, "M7 walking in starts the fight again")
	expect_eq(m.courtyard.alive.size(), m.courtyard.waves[0], "M7 with a fresh first wave")
