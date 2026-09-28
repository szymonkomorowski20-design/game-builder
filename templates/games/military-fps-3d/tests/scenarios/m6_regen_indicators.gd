extends GbScenario
## M6 — a hit from the right shows an arc on the right (direction indicator) and costs its damage; health does not
## come back before regen_delay, then refills at regen_rate; low health turns the screen edges red (no number);
## two hits from about the same side refresh one arc instead of stacking. (Start yard, hits dealt directly.)


func run() -> void:
	var m := node(".") as MilMission
	var p := m.player
	var t := p.tuning
	await wait_frames(5)
	p.aim_at(p.eye_position() + Vector3(0, 0, -10))       # facing −Z: +X is the right
	await wait_frames(1)
	p.take_hit(30.0, p.global_position + Vector3(8, 1.5, 0))
	await wait_frames(1)
	expect_eq(p.indicators.indicators.size(), 1, "M6 one indicator")
	expect_near(float(p.indicators.indicators[0].angle), 90.0, 8.0, "M6 a hit from the right points right")
	expect_near(p.health.current, t.max_health - 30.0, 0.01, "M6 the hit costs its damage")
	p.take_hit(10.0, p.global_position + Vector3(8, 1.5, 1))
	await wait_frames(1)
	expect_eq(p.indicators.indicators.size(), 1, "M6 a second hit from the same side refreshes the arc")
	await shot("m6_indicator")
	await wait(t.regen_delay - 0.3)
	expect_near(p.health.current, t.max_health - 40.0, 0.01, "M6 no regeneration before regen_delay")
	await wait(0.3 + 40.0 / t.regen_rate + 0.3)
	expect_near(p.health.current, t.max_health, 0.01, "M6 health refills after regen_delay at regen_rate")
	expect_eq(m.hud.danger, 0.0, "M6 no red edges at full health")
	p.take_hit(t.max_health * 0.75, p.global_position + Vector3(0, 1.5, -8))
	await wait_frames(2)
	expect_gt(m.hud.danger, 0.2, "M6 low health turns the edges red")
	expect(p.alive, "M6 still alive at a quarter")
	await shot("m6_danger")
