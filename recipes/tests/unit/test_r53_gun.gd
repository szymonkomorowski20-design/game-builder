extends GutTest
## Recipe 53 — gun handling: rate, magazine, reloads, spread and bloom, recoil pattern, falloff and hit zones.

const DT := 1.0 / 60.0


func _gun(edit: Callable = Callable()) -> GunModel:
	var s := GunStats.new()
	if edit.is_valid():
		edit.call(s)
	return GunModel.new(s, 7)


func _hold(g: GunModel, seconds: float, down: bool = true) -> int:
	var shots := 0
	for i in roundi(seconds / DT):
		shots += g.tick(DT, down).size()
	return shots


func test_r53_automatic_rate_is_exact() -> void:
	var g := _gun(func(s: GunStats) -> void: s.rpm = 600.0; s.magazine = 100)
	assert_eq(_hold(g, 1.0), 10, "600 rpm = 10 shots in a second, the first at once")
	var h := _gun(func(s: GunStats) -> void: s.rpm = 700.0; s.magazine = 100)
	var n := _hold(h, 3.0)
	assert_true(n >= 34 and n <= 36, "700 rpm between frames keeps its rate (~35 in 3 s), got %d" % n)


func test_r53_semi_auto_needs_a_new_press() -> void:
	var g := _gun(func(s: GunStats) -> void: s.automatic = false)
	assert_eq(_hold(g, 0.5), 1, "holding a semi-auto fires once")
	g.tick(DT, false)
	assert_eq(g.tick(DT, true).size(), 1, "a new press fires again")


func test_r53_empty_magazine_clicks_and_reload_kinds() -> void:
	var g := _gun(func(s: GunStats) -> void: s.magazine = 3; s.reserve = 5)
	var clicks := [0]
	g.dry_fired.connect(func() -> void: clicks[0] += 1)
	assert_eq(_hold(g, 1.0), 3, "three rounds")
	g.tick(DT, false)
	g.tick(DT, true)
	assert_eq(clicks[0], 1, "a press on empty clicks")
	var times := []
	g.reload_started.connect(func(t: float) -> void: times.append(t))
	assert_true(g.reload())
	assert_almost_eq(times[0], g.stats.reload_empty, 1e-6, "empty magazine → the empty reload")
	_hold(g, g.stats.reload_empty + 0.05, false)
	assert_eq([g.ammo, g.reserve], [3, 2], "3 loaded from 5")
	g.tick(DT, true)
	g.tick(DT, false)
	assert_true(g.reload())
	assert_almost_eq(times[1], g.stats.reload_tactical, 1e-6, "rounds left → the tactical reload")
	_hold(g, g.stats.reload_tactical + 0.05, false)
	assert_eq([g.ammo, g.reserve], [3, 1], "topped up with 1, reserve 1 left")
	assert_false(g.reload(), "a full magazine does not reload")


func test_r53_cancelled_reload_loads_nothing_and_blocks_no_fire_after() -> void:
	var g := _gun(func(s: GunStats) -> void: s.magazine = 5)
	_hold(g, 0.25)
	var before := g.ammo
	g.reload()
	_hold(g, 0.5, false)
	g.cancel_reload()
	_hold(g, 3.0, false)
	assert_eq(g.ammo, before, "a cancelled reload loads nothing")
	assert_eq(g.tick(DT, true).size(), 1, "and the gun fires again at once")


func test_r53_spread_hip_ads_bloom_and_rest() -> void:
	var g := _gun()
	assert_almost_eq(g.current_spread(), g.stats.hip_spread, 1e-6)
	g.set_ads(true)
	_hold(g, g.stats.ads_time + 0.05, false)
	assert_almost_eq(g.current_spread(), g.stats.ads_spread, 1e-6, "fully aimed")
	var shots: Array[GunModel.Shot] = []
	for i in 60:
		shots.append_array(g.tick(DT, true))
	assert_almost_eq(shots[0].spread_deg, g.stats.ads_spread, 1e-6, "the first shot has no bloom")
	assert_gt(shots[-1].spread_deg, shots[0].spread_deg, "bloom grows in a burst")
	assert_true(g.bloom <= g.stats.bloom_max + 1e-6, "bloom is capped")
	_hold(g, 1.0, false)
	assert_almost_eq(g.bloom, 0.0, 1e-6, "bloom recovers when not firing")
	for s in shots:
		assert_true(s.offset.length() <= s.spread_deg + 1e-4, "every shot lands inside its cone")


func test_r53_recoil_follows_the_pattern_and_restarts_after_a_rest() -> void:
	var g := _gun(func(s: GunStats) -> void: s.magazine = 100)
	var kicks: Array[Vector2] = []
	for i in 40:
		for s in g.tick(DT, true):
			kicks.append(s.kick)
	var p := g.stats.recoil_pattern
	for i in mini(kicks.size(), p.size()):
		assert_almost_eq(kicks[i].y, p[i].y, 1e-6, "shot %d kicks as the pattern says" % i)
	_hold(g, g.stats.first_shot_rest + 0.05, false)
	assert_almost_eq(g.tick(DT, true)[0].kick.y, p[0].y, 1e-6, "after a rest the pattern starts again")


func test_r53_damage_falloff_and_zones() -> void:
	var g := _gun()
	var s := g.stats
	assert_almost_eq(g.damage_at(5.0), s.damage, 1e-6, "close: full damage")
	assert_almost_eq(g.damage_at(s.falloff_end + 10.0), s.damage * s.falloff_min, 1e-6, "far: the minimum")
	var mid := (s.falloff_start + s.falloff_end) * 0.5
	assert_almost_eq(g.damage_at(mid), s.damage * lerpf(1.0, s.falloff_min, 0.5), 1e-6, "linear in between")
	assert_almost_eq(g.damage_at(5.0, &"head"), s.damage * s.headshot_mult, 1e-6, "headshot")
	assert_almost_eq(g.damage_at(5.0, &"limb"), s.damage * s.limb_mult, 1e-6, "limb")


func test_r53_same_seed_same_shots() -> void:
	var a := GunModel.new(GunStats.new(), 3)
	var b := GunModel.new(GunStats.new(), 3)
	for i in 30:
		var sa := a.tick(DT, true)
		var sb := b.tick(DT, true)
		if not sa.is_empty():
			assert_eq(sa[0].offset, sb[0].offset)
