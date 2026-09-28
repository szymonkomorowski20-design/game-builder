extends GbScenario
## M8 — the whole mission is completable at base difficulty by a careful bot (MilBot): gate → courtyard (two waves)
## → warehouse (two waves) → radio (hold E) → reinforcements → extraction. If this fails after a tuning change, the
## base mission got unfair for a competent player (or soft-locked): see the spec's balance contracts.
## Allowed: at most `MAX_DEATHS` deaths (checkpoints are part of the genre), no unfair spawn.

const MAX_DEATHS := 1


func run() -> void:
	var m := node(".") as MilMission
	var bot := MilBot.new(self, m)
	await wait_frames(5)
	await bot.walk_to(Vector3(0, 0, -13.2), 0.6)
	await wait_until(func() -> bool: return m.stage == MilMission.Stage.COURTYARD, 3.0)
	expect_eq(m.stage, MilMission.Stage.COURTYARD, "M8 the gate starts the courtyard fight")
	await bot.fight(func() -> bool: return m.stage == MilMission.Stage.TO_WAREHOUSE, 150.0)
	note("courtyard: stage %s, deaths %d, hp %d, t %.0f s, enemy shots %d hits %d, %s" % [m.stage, m.deaths, roundi(m.player.health.current), m.elapsed, m.soldier_shots, m.soldier_hits, bot.counts])
	if m.stage == MilMission.Stage.GATE:   # died and respawned before clearing: walk in again
		await bot.walk_to(Vector3(0, 0, -13.2), 0.6)
		await bot.fight(func() -> bool: return m.stage == MilMission.Stage.TO_WAREHOUSE, 150.0)
	expect_eq(m.stage, MilMission.Stage.TO_WAREHOUSE, "M8 the courtyard is cleared")
	await bot.walk_to(Vector3(6, 0, -46.8), 0.6)
	await wait_until(func() -> bool: return m.stage == MilMission.Stage.WAREHOUSE, 3.0)
	await bot.fight(func() -> bool: return m.stage == MilMission.Stage.RADIO, 150.0)
	note("warehouse: stage %s, deaths %d, hp %d, t %.0f s, enemy shots %d hits %d, %s" % [m.stage, m.deaths, roundi(m.player.health.current), m.elapsed, m.soldier_shots, m.soldier_hits, bot.counts])
	if m.stage == MilMission.Stage.TO_WAREHOUSE:
		await bot.walk_to(Vector3(6, 0, -46.8), 0.6)
		await bot.fight(func() -> bool: return m.stage == MilMission.Stage.RADIO, 150.0)
	expect_eq(m.stage, MilMission.Stage.RADIO, "M8 the warehouse is cleared")
	await bot.walk_to(Vector3(-10, 0, -69.2), 0.5)
	hold("action")
	await wait_until(func() -> bool: return m.stage == MilMission.Stage.REINFORCEMENTS, 4.0)
	release("action")
	expect_eq(m.stage, MilMission.Stage.REINFORCEMENTS, "M8 holding E at the radio calls the reinforcements")
	await bot.fight(func() -> bool: return m.stage == MilMission.Stage.EXTRACT, 150.0)
	note("reinforcements: stage %s, deaths %d, hp %d, t %.0f s, enemy shots %d hits %d, %s" % [m.stage, m.deaths, roundi(m.player.health.current), m.elapsed, m.soldier_shots, m.soldier_hits, bot.counts])
	expect_eq(m.stage, MilMission.Stage.EXTRACT, "M8 the reinforcements are beaten")
	await bot.walk_to(Vector3(0, 0, -95), 1.5, 30.0)
	await wait_until(func() -> bool: return m.stage == MilMission.Stage.COMPLETE, 3.0)
	expect_eq(m.stage, MilMission.Stage.COMPLETE, "M8 the mission is complete on the pad")
	expect(m.deaths <= MAX_DEATHS, "M8 at most %d death(s) at base difficulty (got %d)" % [MAX_DEATHS, m.deaths])
	expect_eq(m.unfair_spawns, 0, "M8 every soldier spawned out of sight, ahead, 12–45 m away %s" % [m.unfair_log])
	var p := m.player
	note("done: %.0f s, deaths %d, shots %d, hits %d, headshots %d, kills %d, soldiers %d" % [m.elapsed, m.deaths, p.shots_fired, p.hits, p.headshots, p.kills, m.soldiers_spawned])
	await shot("m8_complete")
