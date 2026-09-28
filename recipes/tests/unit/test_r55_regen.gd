extends GutTest
## Recipe 55 — regenerating health (delay, rate, segments), the danger effect, and damage direction indicators.

const DT := 1.0 / 60.0


func _run(h: RegenHealth, seconds: float) -> void:
	for i in roundi(seconds / DT):
		h.tick(DT)


func test_r55_regen_waits_then_refills() -> void:
	var h := RegenHealth.new(100.0)
	h.take_damage(60.0)
	_run(h, h.regen_delay - 0.1)
	assert_almost_eq(h.current, 40.0, 1e-4, "nothing before the delay")
	_run(h, 0.2 + 1.0)
	assert_almost_eq(h.current, 40.0 + h.regen_rate * 1.1, 1.0, "then regen_rate per second")
	_run(h, 10.0)
	assert_almost_eq(h.current, 100.0, 1e-4, "up to full")


func test_r55_a_hit_restarts_the_delay() -> void:
	var h := RegenHealth.new(100.0)
	h.take_damage(50.0)
	_run(h, h.regen_delay - 0.5)
	h.take_damage(10.0)
	_run(h, h.regen_delay - 0.1)
	assert_almost_eq(h.current, 40.0, 1e-4, "each hit restarts the wait")


func test_r55_segments_cap_regeneration() -> void:
	var h := RegenHealth.new(100.0)
	h.segment = 25.0
	h.take_damage(40.0)       # 60 → regenerates to 75, not 100
	_run(h, h.regen_delay + 5.0)
	assert_almost_eq(h.current, 75.0, 1e-4, "only to the top of its segment")
	h.take_damage(25.0)       # exactly 50 → stays 50
	_run(h, h.regen_delay + 5.0)
	assert_almost_eq(h.current, 50.0, 1e-4, "a hit that lands on a boundary keeps that boundary")


func test_r55_danger_and_death() -> void:
	var h := RegenHealth.new(100.0)
	assert_eq(h.danger(), 0.0)
	h.take_damage(80.0)
	assert_gt(h.danger(), 0.0, "below danger_below the effect starts")
	var died := [false]
	h.died.connect(func() -> void: died[0] = true)
	h.take_damage(50.0)
	assert_true(died[0] and h.is_dead())
	_run(h, 10.0)
	assert_eq(h.current, 0.0, "the dead don't regenerate")


func test_r55_direction_to_the_attacker() -> void:
	var view := Basis()      # looking along −Z
	var me := Vector3.ZERO
	assert_almost_eq(RegenHealth.direction_to(view, me, Vector3(0, 0, -5)), 0.0, 1e-3, "in front")
	assert_almost_eq(RegenHealth.direction_to(view, me, Vector3(5, 0, 0)), 90.0, 1e-3, "right")
	assert_almost_eq(RegenHealth.direction_to(view, me, Vector3(-5, 3, 0)), -90.0, 1e-3, "left (height ignored)")
	assert_almost_eq(absf(RegenHealth.direction_to(view, me, Vector3(0, 0, 5))), 180.0, 1e-3, "behind")


func test_r55_indicators_merge_and_fade() -> void:
	var d := DamageIndicators.new()
	d.add(10.0)
	d.add(20.0)
	assert_eq(d.indicators.size(), 1, "two hits from about the same side refresh one arc")
	d.add(-120.0)
	assert_eq(d.indicators.size(), 2)
	for i in roundi(1.0 / DT):
		d.tick(DT)
	assert_gt(d.alpha(d.indicators[0]), 0.0)
	for i in roundi(1.0 / DT):
		d.tick(DT)
	assert_eq(d.indicators.size(), 0, "gone after their lifetime")
