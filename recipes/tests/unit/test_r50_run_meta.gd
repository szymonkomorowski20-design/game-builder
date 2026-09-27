extends GutTest
## R50 — run structure and meta progression. RunMap: the first room is one combat door with a boon (onboarding),
## the last is the boss alone, the step before the boss offers a rest, other steps offer 2–3 distinct doors, no shop
## right after a shop, elites only from `elite_from`, same seed → same doors. MetaProgress: dying banks the run's
## currency, upgrades cost more each level and need the currency, they raise stats through a StatSheet, and the whole
## thing survives to_dict/from_dict (for the save recipe).


func _map() -> RunMap:
	var m := RunMap.new()
	m.rooms = 10
	m.elite_from = 4
	return m


func _types(doors: Array[RoomDoor]) -> Array:
	return doors.map(func(d: RoomDoor): return d.type)


func test_r50_first_and_last_rooms() -> void:
	var m := _map()
	var first := m.doors(0, 1, RoomDoor.Type.COMBAT)
	assert_eq(first.size(), 1)
	assert_eq(first[0].type, RoomDoor.Type.COMBAT)
	assert_eq(first[0].reward, RoomDoor.Reward.BOON, "the first reward is a boon")
	var last := m.doors(m.rooms - 1, 1, RoomDoor.Type.COMBAT)
	assert_eq(_types(last), [RoomDoor.Type.BOSS], "the last room is the boss, alone")
	for seed in 50:
		assert_true(_types(m.doors(m.rooms - 2, seed, RoomDoor.Type.COMBAT)).has(RoomDoor.Type.REST), "a rest before the boss (seed %d)" % seed)


func test_r50_middle_steps_offer_two_or_three_distinct_doors() -> void:
	var m := _map()
	for seed in 50:
		for depth in range(1, m.rooms - 2):
			var doors := m.doors(depth, seed, RoomDoor.Type.COMBAT)
			assert_between(doors.size(), 2, 3)
			var keys := {}
			for d in doors:
				keys["%d/%d" % [d.type, d.reward]] = true
			assert_eq(keys.size(), doors.size(), "distinct doors (depth %d seed %d)" % [depth, seed])


func test_r50_no_shop_after_shop_and_elites_from_depth() -> void:
	var m := _map()
	var elite_seen_late := false
	for seed in 100:
		for depth in range(1, m.rooms - 1):
			var after_shop := _types(m.doors(depth, seed, RoomDoor.Type.SHOP))
			assert_false(after_shop.has(RoomDoor.Type.SHOP), "no shop right after a shop")
			var types := _types(m.doors(depth, seed, RoomDoor.Type.COMBAT))
			if depth < m.elite_from:
				assert_false(types.has(RoomDoor.Type.ELITE), "no elite before depth %d" % m.elite_from)
			elif types.has(RoomDoor.Type.ELITE):
				elite_seen_late = true
	assert_true(elite_seen_late, "elites do appear later")


func test_r50_deterministic() -> void:
	var m := _map()
	var a := m.doors(3, 99, RoomDoor.Type.COMBAT).map(func(d: RoomDoor): return [d.type, d.reward])
	var b := m.doors(3, 99, RoomDoor.Type.COMBAT).map(func(d: RoomDoor): return [d.type, d.reward])
	assert_eq(a, b)


func _meta() -> MetaProgress:
	var meta := MetaProgress.new()
	meta.upgrades = {&"vitality": {"stat": &"max_health", "per_level": 10.0, "base_cost": 10, "max_level": 3}}
	return meta


func test_r50_death_banks_currency_and_upgrades_cost_more() -> void:
	var meta := _meta()
	var run := RunState.new()
	run.collect(25)
	run.collect(10)
	meta.bank(run.end(false))
	assert_eq(meta.currency, 35, "dying keeps everything collected in the run")
	assert_true(meta.buy(&"vitality"), "level 1 costs 10")
	assert_eq(meta.currency, 25)
	assert_true(meta.buy(&"vitality"), "level 2 costs 20")
	assert_eq(meta.currency, 5)
	assert_false(meta.buy(&"vitality"), "level 3 costs 30 — not enough")
	assert_eq(meta.level(&"vitality"), 2)
	meta.currency = 1000
	assert_true(meta.buy(&"vitality"))
	assert_false(meta.buy(&"vitality"), "max level reached")
	assert_eq(meta.currency, 970)


func test_r50_upgrades_raise_stats_and_survive_a_save() -> void:
	var meta := _meta()
	meta.currency = 100
	meta.buy(&"vitality")
	meta.buy(&"vitality")
	var sheet := StatSheet.new({&"max_health": 50.0})
	meta.apply_to(sheet)
	assert_almost_eq(sheet.value(&"max_health"), 70.0, 1e-6, "+10 per level")
	var restored := _meta()
	restored.from_dict(meta.to_dict())
	assert_eq(restored.currency, meta.currency)
	assert_eq(restored.level(&"vitality"), 2)


func test_r50_a_new_run_starts_fresh() -> void:
	var run := RunState.new()
	run.depth = 6
	run.collect(40)
	run.end(false)
	run.begin(123)
	assert_eq(run.depth, 0)
	assert_eq(run.collected, 0)
	assert_eq(run.seed, 123)
