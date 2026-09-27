extends GutTest
## R49 — encounter director. plan(depth, seed): waves whose total cost fits the wave budget and fills it (nothing
## cheap enough left over), budget and wave count grow with depth, enemies appear only from their min_depth, a wave
## mixes types when it can, same seed → same plan. Running: the next wave starts only when every enemy of the current
## one is dead (after wave_delay); `cleared` fires once, after the last wave.


func _kind(id: StringName, cost: int, min_depth: int = 0) -> EnemyKind:
	var k := EnemyKind.new()
	k.id = id
	k.cost = cost
	k.min_depth = min_depth
	return k


func _director() -> EncounterDirector:
	var d := EncounterDirector.new()
	d.kinds = [_kind(&"rusher", 1), _kind(&"archer", 2), _kind(&"brute", 4, 3), _kind(&"summoner", 3, 5)]
	d.base_budget = 4
	d.budget_per_depth = 1.5
	d.max_waves = 3
	return d


func _cost(d: EncounterDirector, wave: Array) -> int:
	var total := 0
	for id in wave:
		total += d.kind(id).cost
	return total


func test_r49_waves_fit_and_fill_the_budget() -> void:
	var d := _director()
	for depth in 10:
		var plan := d.plan(depth, 100 + depth)
		var budget := d.wave_budget(depth)
		var cheapest := 1
		for wave in plan:
			var c := _cost(d, wave)
			assert_lte(c, budget, "depth %d: a wave never exceeds its budget" % depth)
			assert_gt(c, budget - cheapest, "depth %d: the budget is filled (%d of %d)" % [depth, c, budget])


func test_r49_grows_with_depth() -> void:
	var d := _director()
	assert_lt(d.wave_budget(0), d.wave_budget(6))
	assert_lte(d.plan(0, 1).size(), d.plan(6, 1).size())
	assert_eq(d.plan(0, 1).size(), 1, "the first room is one wave")
	assert_eq(d.plan(9, 1).size(), 3, "capped at max_waves")


func test_r49_min_depth_unlocks() -> void:
	var d := _director()
	for seed in 50:
		for wave in d.plan(2, seed):
			assert_false(wave.has(&"brute"), "no brutes before depth 3")
			assert_false(wave.has(&"summoner"), "no summoners before depth 5")
	var seen := false
	for seed in 50:
		for wave in d.plan(6, seed):
			seen = seen or wave.has(&"summoner")
	assert_true(seen, "summoners appear from depth 5")


func test_r49_waves_mix_types() -> void:
	var d := _director()
	for seed in 50:
		for wave in d.plan(4, seed):
			var kinds := {}
			for id in wave:
				kinds[id] = true
			assert_gt(kinds.size(), 1, "a wave of %d enemies mixes types (seed %d)" % [wave.size(), seed])


func test_r49_same_seed_same_plan() -> void:
	var d := _director()
	assert_eq(d.plan(5, 77), d.plan(5, 77))
	assert_ne(d.plan(5, 77), d.plan(5, 78), "a different seed changes it")


func test_r49_waves_advance_only_when_cleared() -> void:
	var d := _director()
	d.wave_delay = 0.5
	var spawned := []
	var cleared := [0]
	d.wave_started.connect(func(i: int, ids: Array): spawned.append(ids.size()))
	d.cleared.connect(func(): cleared[0] += 1)
	d.start(6, 3)
	var waves := d.current_plan.size()
	assert_eq(spawned.size(), 1, "the first wave starts at once")
	for w in waves:
		var alive: int = spawned[w]
		for i in alive - 1:
			d.enemy_died()
		d.tick(2.0)
		assert_eq(spawned.size(), w + 1, "one enemy still alive → no next wave")
		d.enemy_died()
		d.tick(0.49)
		assert_eq(spawned.size(), w + 1, "the next wave waits wave_delay")
		d.tick(0.02)
	assert_eq(spawned.size(), waves, "all waves ran")
	assert_eq(cleared[0], 1, "cleared exactly once, after the last wave")
	assert_true(d.is_cleared())
