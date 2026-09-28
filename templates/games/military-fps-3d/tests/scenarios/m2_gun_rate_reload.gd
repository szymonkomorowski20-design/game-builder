extends GbScenario
## M2 — the rifle fires at its rpm while shoot is held; the magazine runs dry and the empty trigger starts the
## (longer) empty reload; a tactical reload is shorter and keeps nothing extra; sprinting cancels a reload; the pistol
## is semi-automatic: holding the trigger fires once. (Start yard, aimed at the back wall.)


func run() -> void:
	var m := node(".") as MilMission
	var p := m.player
	await wait_frames(5)
	p.aim_at(Vector3(0, 1.5, 7))          # the start yard's back wall
	var g := p.gun()
	var rpm := g.stats.rpm
	var before := p.shots_fired
	hold("shoot")
	await wait(1.0)
	release("shoot")
	var in_one := p.shots_fired - before
	var expected := floori(rpm / 60.0) + 1
	expect(absi(in_one - expected) <= 1, "M2 %d rpm fires %d±1 rounds in 1 s (got %d)" % [rpm, expected, in_one])
	await wait(0.3)
	hold("shoot")
	await wait_until(func() -> bool: return g.ammo == 0, 4.0)
	await wait(0.2)
	expect_eq(g.ammo, 0, "M2 the magazine runs dry")
	expect(g.is_reloading(), "M2 pulling the trigger on an empty gun starts the reload")
	release("shoot")
	var reserve := g.reserve
	await wait(g.stats.reload_empty - 0.3)
	expect(g.is_reloading(), "M2 the empty reload takes reload_empty (%.1f s)" % g.stats.reload_empty)
	await wait(0.5)
	expect_eq([g.ammo, g.reserve], [g.stats.magazine, reserve - g.stats.magazine], "M2 a full magazine, taken from the reserve")
	hold("shoot")
	await wait(0.3)
	release("shoot")
	var left := g.ammo
	await tap("reload")
	await wait(g.stats.reload_tactical - 0.3)
	expect(g.is_reloading(), "M2 a tactical reload is still running just before reload_tactical")
	await wait(0.5)
	expect_eq(g.ammo, g.stats.magazine, "M2 the tactical reload fills the magazine")
	hold("shoot")
	await wait(0.2)
	release("shoot")
	left = g.ammo
	await tap("reload")
	await wait(0.3)
	p.aim_at(p.eye_position() + Vector3(0, 0, -10))
	hold("sprint")
	hold("move_up")
	await wait(0.3)
	release("move_up")
	release("sprint")
	expect(not g.is_reloading(), "M2 sprinting cancels the reload")
	expect_eq(g.ammo, left, "M2 a cancelled reload loads nothing")
	await tap("switch_weapon")
	await wait(p.tuning.swap_time + 0.1)
	expect_eq(p.gun_index, 1, "M2 switch_weapon takes the pistol")
	p.aim_at(Vector3(0, 1.5, 7))
	before = p.shots_fired
	hold("shoot")
	await wait(1.0)
	release("shoot")
	expect_eq(p.shots_fired - before, 1, "M2 the pistol is semi-automatic: holding fires once")
	await wait(0.2)     # a finger lifts for at least a frame before the next press
	await tap("shoot")
	await wait(0.2)
	await tap("shoot")
	expect_eq(p.shots_fired - before, 3, "M2 each press fires one round")
