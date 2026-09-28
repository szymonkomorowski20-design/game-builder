extends GbScenario
## M1 — walking covers walk_speed × time; sprinting is faster and can't shoot; crouching lowers the eye below low
## cover and slows you; aiming down sights slows you by the gun's ads_move_scale. (Start yard, no enemies.)

const START := Vector3(0, 0.05, 2)


func _run_for(p: MilPlayer, actions: Array[String], seconds: float) -> float:
	p.global_position = START
	p.velocity = Vector3.ZERO
	p.aim_at(START + Vector3(0, 1.6, -10))
	await wait_frames(2)
	var from := p.global_position
	for a in actions:
		hold(a)
	await wait(seconds)
	for a in actions:
		release(a)
	var d := p.global_position - from
	d.y = 0.0
	await wait(0.2)
	return d.length()


func run() -> void:
	var m := node(".") as MilMission
	var p := m.player
	var t := p.tuning
	await wait_frames(5)
	var walk := await _run_for(p, ["move_up"], 1.0)
	expect_near(walk, t.walk_speed, 0.5, "M1 walking 1 s covers ~walk_speed")
	var shots := p.shots_fired
	var sprint := await _run_for(p, ["move_up", "sprint", "shoot"], 1.0)
	expect_near(sprint, t.sprint_speed, 0.7, "M1 sprinting 1 s covers ~sprint_speed")
	expect_eq(p.shots_fired, shots, "M1 no shots while sprinting")
	await tap("crouch")
	await wait(t.crouch_time + 0.1)
	expect(p.crouching, "M1 crouch toggles on")
	expect_near(p.head.position.y, t.crouch_eye, 0.02, "M1 the eye drops to crouch_eye (below 1.1 m cover)")
	var crouch := await _run_for(p, ["move_up"], 1.0)
	expect_near(crouch, t.crouch_speed, 0.4, "M1 crouch-walking covers ~crouch_speed")
	await tap("crouch")
	await wait(t.crouch_time + 0.1)
	expect(not p.crouching, "M1 crouch toggles off")
	expect_near(p.head.position.y, t.stand_eye, 0.02, "M1 the eye is back at stand_eye")
	var ads := await _run_for(p, ["aim", "move_up"], 1.0)
	expect_near(ads, t.walk_speed * p.gun().stats.ads_move_scale, 0.5, "M1 aiming down sights slows walking by ads_move_scale")
	expect_eq(m.stage, MilMission.Stage.GATE, "M1 still in the start yard")
