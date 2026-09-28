extends GbScenario
## M4 — a shot to the head deals damage × headshot_mult and shows the head hit marker; a body shot deals the base
## damage and the body marker; the killing shot shows the kill marker and counts a kill. (A passive soldier placed in
## the start yard, 8 m ahead, that crouched and stood up once.)


func run() -> void:
	var m := node(".") as MilMission
	var p := m.player
	await wait_frames(5)
	var s := m.soldier_scene.instantiate() as MilSoldier
	s.passive = true
	s.position = Vector3(0, 0, -6)
	m.soldiers_root.add_child(s)
	await wait_frames(3)
	s.set_crouched(true)       # after crouching and standing up again, the head must still be a head
	await wait_frames(1)
	s.set_crouched(false)
	await wait_frames(1)
	var g := p.gun()
	var full := s.health
	hold("aim")                    # aimed shots: hip fire spreads 3°, wider than a head at 8 m
	await wait(g.stats.ads_time + 0.05)
	p.aim_at(s.head_point())
	await wait_frames(1)
	await tap("shoot")
	var head_damage := g.damage_at(p.eye_position().distance_to(s.head_point()), &"head")
	expect_near(full - s.health, head_damage, 0.5, "M4 a headshot deals damage × headshot_mult (%.0f)" % head_damage)
	expect_eq(m.hud.hit_marker, &"head", "M4 the head hit marker shows")
	expect_eq(p.headshots, 1, "M4 one headshot counted")
	await shot("m4_headshot")
	await wait(0.4)
	var hp := s.health
	p.aim_at(s.aim_point())
	await wait_frames(1)
	await tap("shoot")
	expect_near(hp - s.health, g.stats.damage, 0.5, "M4 a body shot deals the base damage up close")
	expect_eq(m.hud.hit_marker, &"body", "M4 the body hit marker shows")
	await wait(0.4)
	p.aim_at(s.aim_point())
	await wait_frames(1)
	await tap("shoot")
	expect(not s.alive, "M4 the third hit kills (health %.0f)" % s.health)
	expect_eq(m.hud.hit_marker, &"kill", "M4 the kill marker shows")
	expect_eq(p.kills, 1, "M4 one kill counted")
	await wait(0.5)
	expect(not s.is_in_group(&"soldiers"), "M4 a dead soldier is no longer a target")
