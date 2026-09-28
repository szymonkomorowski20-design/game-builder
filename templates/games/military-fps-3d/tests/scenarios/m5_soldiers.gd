extends GbScenario
## M5 — the courtyard's first wave is dug in: every soldier starts crouched at cover that hides it from the player.
## They peek and fire; never more than `attack_tokens` peek at once; a peek's first shots use accuracy_min (they
## mostly miss); the player hears them ("Kontakt!"); shooting close to a peeking soldier sends it back into cover
## with a bark; a player standing in the open takes less than a full health bar in the first 3.5 s of fire (the
## lethality contract, on the real code). (The player is made very tough, so only behaviour is measured.)

const LETHALITY_WINDOW := 3.5


func run() -> void:
	var m := node(".") as MilMission
	var p := m.player
	await wait_frames(5)
	p.health.max_health = 100000.0
	p.health.current = 100000.0
	var bot := MilBot.new(self, m)
	await bot.walk_to(Vector3(0, 0, -13.2), 0.6)
	await wait_until(func() -> bool: return m.stage == MilMission.Stage.COURTYARD, 3.0)
	await wait_frames(2)
	var first := m.courtyard.alive.duplicate()
	expect_eq(first.size(), m.courtyard.waves[0], "M5 the first wave is here")
	var hidden := true
	for s: MilSoldier in first:
		var q := PhysicsRayQueryParameters3D.create(p.eye_position(), s.head_point(), MilPlayer.WORLD)
		hidden = hidden and not p.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
		hidden = hidden and s.brain.state == ShooterBrain.Mode.COVER
	expect(hidden, "M5 the first wave starts crouched in cover, heads hidden from the player")
	expect_eq(m.unfair_spawns, 0, "M5 no unfair spawn")
	var most_peeking := 0
	var first_peek_accuracy := -1.0
	var first_shot_at := -1.0
	var hits_in_window := -1
	var t := 0.0
	while t < 10.0:
		if first_shot_at < 0.0 and m.soldier_shots > 0:
			first_shot_at = t
		if first_shot_at >= 0.0 and hits_in_window < 0 and t - first_shot_at >= LETHALITY_WINDOW:
			hits_in_window = m.soldier_hits
		var peeking := 0
		for s: MilSoldier in first:
			if is_instance_valid(s) and s.alive and s.brain.state == ShooterBrain.Mode.PEEK:
				peeking += 1
				if first_peek_accuracy < 0.0 and s.shots == 1:
					first_peek_accuracy = s.last_accuracy     # what the first shot really used
		most_peeking = maxi(most_peeking, peeking)
		await wait_frames(1)
		t += 1.0 / 60.0
	expect_gt(first_peek_accuracy, -0.5, "M5 a soldier peeked and fired within 10 s")
	var tn := (first[0] as MilSoldier).tuning
	expect_lt(first_peek_accuracy, tn.accuracy_min * m.difficulty + 0.02, "M5 a peek starts at accuracy_min (%.2f)" % first_peek_accuracy)
	expect(most_peeking <= m.attack_tokens, "M5 at most %d soldiers peek at once (saw %d)" % [m.attack_tokens, most_peeking])
	expect_gt(m.soldier_shots, 0, "M5 they fire")
	# The lethality contract on the real code (bursts, pauses, peeks, the ramp): a player standing in the open at the
	# gate takes less than a full health bar in the first LETHALITY_WINDOW s of fire.
	expect_gt(hits_in_window, -1, "M5 the fire lasted the window")
	expect_lt(hits_in_window * tn.damage, p.tuning.max_health, "M5 standing in the open, %d hits (%.0f damage) in the first %.1f s of fire" % [hits_in_window, hits_in_window * tn.damage, LETHALITY_WINDOW])
	# Suppression: wait for a peek, shoot a metre beside the soldier.
	var found: Array[MilSoldier] = []     # a lambda captures locals by value: collect into an array
	await wait_until(func() -> bool:
		for s: MilSoldier in first:
			if is_instance_valid(s) and s.alive and s.brain.state == ShooterBrain.Mode.PEEK:
				found.append(s)
				return true
		return false, 12.0)
	var target: MilSoldier = found[0] if not found.is_empty() else null
	expect(target != null, "M5 a soldier peeks again")
	if target != null:
		hold("aim")
		await wait(p.gun().stats.ads_time + 0.02)
		var side := (target.global_position - p.global_position).cross(Vector3.UP).normalized()
		p.aim_at(target.aim_point() + side * 1.0)
		await wait_frames(1)
		await tap("shoot")
		await wait_frames(2)
		expect_eq(target.brain.state, ShooterBrain.Mode.COVER, "M5 a shot landing close sends it back into cover")
		expect(target.brain.is_suppressed(), "M5 it is suppressed (its next peek waits longer)")
		expect_eq(m.hud.subtitle, "Żołnierz: " + String(MilHud.BARKS[&"suppressed"]), "M5 and says so")
		release("aim")
		await shot("m5_suppressed")
