extends GbScenario
## M3 — aiming down sights narrows the view (FOV × ads_fov_scale), tightens the spread to ads_spread and hides the
## crosshair; firing climbs the view along the recoil pattern and it settles back after the trigger is released; the
## pattern is the same every burst (learnable); the crosshair opens with bloom.


func run() -> void:
	var m := node(".") as MilMission
	var p := m.player
	var t := p.tuning
	await wait_frames(5)
	p.aim_at(Vector3(0, 1.6, 7))
	var g := p.gun()
	var gap_rest := m.hud.crosshair_gap
	expect(m.hud.crosshair_visible, "M3 the crosshair shows from the hip")
	hold("aim")
	await wait(g.stats.ads_time + 0.1)
	expect_near(g.ads, 1.0, 0.001, "M3 fully aimed after ads_time")
	expect_near(p.camera.fov, t.fov * t.ads_fov_scale, 0.1, "M3 the view narrows to fov × ads_fov_scale")
	expect_near(g.current_spread(), g.stats.ads_spread, 0.001, "M3 the spread is ads_spread")
	await wait_frames(2)
	expect(not m.hud.crosshair_visible, "M3 no crosshair while aiming (the sights are the crosshair)")
	await shot("m3_ads")
	release("aim")
	await wait(g.stats.ads_time + 0.3)
	var pitch_before := p.head.rotation.x
	hold("shoot")
	await wait(0.4)
	var climbed := p.head.rotation.x - pitch_before
	var gap_firing := m.hud.crosshair_gap
	var kick1 := g.kick_accumulated
	release("shoot")
	expect_gt(rad_to_deg(climbed), 1.5, "M3 a burst climbs the view (%.1f°)" % rad_to_deg(climbed))
	expect_gt(gap_firing, gap_rest + 3.0, "M3 the crosshair opens while firing (bloom)")
	await wait(1.5)
	expect_lt(absf(rad_to_deg(p.head.rotation.x - pitch_before)), 0.2, "M3 the view settles back after the burst")
	expect_near(m.hud.crosshair_gap, gap_rest, 0.5, "M3 the crosshair closes again")
	hold("shoot")
	await wait(0.4)
	var kick2 := g.kick_accumulated
	release("shoot")
	expect_lt(kick1.distance_to(kick2), 0.05, "M3 the same burst kicks the same way (a learnable pattern)")
	# The first shot leaves where the sights were: its own kick moves the view for the NEXT shot. Spread is set to 0
	# for this measurement, so any offset is the recoil. Target: the warehouse wall, 46 m away through the gate.
	await wait(1.0)
	g.stats.ads_spread = 0.0
	var ends: Array[Vector3] = []
	p.fired.connect(func(_f: Vector3, _d: Vector3, end: Vector3, _h: Dictionary) -> void: ends.append(end))
	var mark := Vector3(0, 3.0, -44.0)
	p.aim_at(mark)
	hold("aim")
	await wait(g.stats.ads_time + 0.1)
	p.aim_at(mark)
	await wait_frames(1)
	await tap("shoot")
	release("aim")
	expect_eq(ends.size(), 1, "M3 one aimed shot")
	if ends.size() == 1:
		expect_lt(ends[0].distance_to(mark), 0.1, "M3 the first shot lands where the sights were at 46 m (off by %.2f m)" % ends[0].distance_to(mark))
