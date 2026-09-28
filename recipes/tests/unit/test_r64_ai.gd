extends GutTest
## R64 — the skirmish AI's decisions on a fake world. A farm before supply runs out (and saving for it); workers up to
## the target; the build order waits for its top goal instead of buying cheaper things, and skips what the tech tree
## locks; a wave at wave_size, then bigger waves; a retreat when the odds turn; the think interval is the reaction time;
## presets from easy to hard.


class FakeWorld:
	extends RefCounted
	var counts := {}
	var pending_counts := {}
	var gold := 0
	var costs := {&"worker": 50, &"farm": 80, &"barracks": 150, &"footman": 60, &"archer": 70, &"stable": 200}
	var locked := {}
	var supply := 10
	var enemy_power := 0.0
	var orders: Array[StringName] = []
	var attacks := 0
	var maxed := false
	var coming := {}
	var danger := Vector3.INF
	var attack_at := Vector3.INF
	var retreats := 0
	var army_units: Array = []

	func count(kind: StringName) -> int:
		return int(counts.get(kind, 0))

	func pending(kind: StringName) -> int:
		return int(pending_counts.get(kind, 0))

	func supply_free() -> int:
		return supply

	func supply_maxed() -> bool:
		return maxed

	func unlocking(kind: StringName) -> bool:
		return coming.has(kind)

	func threat() -> Vector3:
		return danger

	func can_afford(kind: StringName) -> bool:
		return gold >= int(costs.get(kind, 0))

	func available(kind: StringName) -> bool:
		return not locked.has(kind)

	func order(kind: StringName) -> bool:
		if not can_afford(kind):
			return false
		gold -= int(costs.get(kind, 0))
		counts[kind] = count(kind) + 1
		orders.append(kind)
		return true

	func army() -> Array:
		return army_units

	func power(units: Array) -> float:
		return units.size() * 60.0

	func enemy_power_near(_at: Vector3) -> float:
		return enemy_power

	func army_centre() -> Vector3:
		return Vector3.ZERO

	func attack(_units: Array, at: Vector3) -> void:
		attacks += 1
		attack_at = at

	func retreat(_units: Array, _to: Vector3) -> void:
		retreats += 1

	func enemy_base() -> Vector3:
		return Vector3(100, 0, 100)

	func home() -> Vector3:
		return Vector3.ZERO


func _brain(w: FakeWorld) -> RtsAiBrain:
	var b := RtsAiBrain.new()
	b.world = w
	b.worker_target = 3
	b.build_order = [{"kind": &"barracks", "count": 1}, {"kind": &"stable", "count": 1}, {"kind": &"footman", "count": 20}] as Array[Dictionary]
	return b


func test_r64_a_farm_before_supply_runs_out() -> void:
	var w := FakeWorld.new()
	w.supply = 2
	w.gold = 60
	var b := _brain(w)
	b.think()
	assert_eq(w.orders, [] as Array[StringName], "can't afford the farm yet: it saves (no worker bought)")
	w.gold = 200
	b.think()
	assert_eq(w.orders, [&"farm"] as Array[StringName])
	w.pending_counts[&"farm"] = 1
	b.think()
	assert_eq(w.orders.count(&"farm"), 1, "one on its way is enough")


func test_r64_workers_up_to_the_target() -> void:
	var w := FakeWorld.new()
	w.gold = 1000
	var b := _brain(w)
	b.build_order = [] as Array[Dictionary]
	for i in 5:
		b.think()
	assert_eq(w.count(&"worker"), 3, "stops at the target")


func test_r64_the_build_order_saves_for_its_top_goal() -> void:
	var w := FakeWorld.new()
	w.counts[&"worker"] = 3
	w.gold = 100                                   # enough for a footman, not for the barracks
	var b := _brain(w)
	b.think()
	assert_false(w.orders.has(&"footman"), "no cheaper thing jumps the queue")
	w.gold = 150
	b.think()
	assert_eq(w.orders, [&"barracks"] as Array[StringName])
	w.locked[&"stable"] = true
	w.gold = 60
	b.think()
	assert_eq(w.orders[w.orders.size() - 1], &"footman", "a tech-locked stable is skipped")


func test_r64_waves_grow_and_retreat_when_losing() -> void:
	var w := FakeWorld.new()
	w.counts[&"worker"] = 3
	var b := _brain(w)
	b.wave_size = 4
	b.wave_growth = 2
	for i in 3:
		w.army_units.append(i)
	b.think()
	assert_eq(w.attacks, 0, "3 < 4: wait")
	w.army_units.append(3)
	b.think()
	assert_eq(w.attacks, 1, "4: the first wave")
	assert_eq(b.wave_size, 6, "the next one is bigger")
	w.enemy_power = 300.0                          # 4 × 60 = 240 < 300 × 0.6? no: 240 > 180
	b.think()
	assert_eq(w.retreats, 0, "a fair fight: stay")
	assert_eq(w.attacks, 2, "and keep pushing")
	assert_eq(b.waves_sent, 1, "the same wave")
	w.enemy_power = 500.0                          # 240 < 300
	b.think()
	assert_eq(w.retreats, 1, "outmatched: back home")
	assert_false(b.attacking)
	b.think()
	assert_eq(w.attacks, 2, "the next wave waits for 6")


func test_r64_waves_are_capped_and_no_farms_at_the_ceiling() -> void:
	var w := FakeWorld.new()
	w.counts[&"worker"] = 3
	var b := _brain(w)
	b.wave_size = 30
	b.max_wave_size = 10
	for i in 10:
		w.army_units.append(i)
	b.think()
	assert_eq(b.waves_sent, 1, "a wave the supply can't reach is capped at max_wave_size")
	w.supply = 0
	w.gold = 500
	w.maxed = true
	b.think()
	assert_false(w.orders.has(&"farm"), "at the supply ceiling a farm adds nothing")


func test_r64_a_step_waits_while_its_prerequisite_is_coming() -> void:
	var w := FakeWorld.new()
	w.counts[&"worker"] = 3
	w.gold = 1000
	w.locked[&"footman"] = true
	w.coming[&"footman"] = true               # its barracks is being built
	var b := _brain(w)
	b.build_order = [{"kind": &"footman", "count": 4}, {"kind": &"barracks", "count": 2}] as Array[Dictionary]
	b.think()
	assert_false(w.orders.has(&"barracks"), "it waits for the barracks under way instead of starting a second")
	w.coming.erase(&"footman")
	b.think()
	assert_true(w.orders.has(&"barracks"), "nothing on its way: the locked step is skipped")


func test_r64_the_army_defends_the_base() -> void:
	var w := FakeWorld.new()
	w.counts[&"worker"] = 3
	var b := _brain(w)
	b.wave_size = 10
	w.army_units = [1, 2, 3]
	w.danger = Vector3(3, 0, 4)
	b.think()
	assert_eq(w.attacks, 1, "three units, no wave yet — but raiders at the base")
	assert_eq(w.attack_at, Vector3(3, 0, 4), "they go at the raiders")
	assert_eq(b.waves_sent, 0, "a defence is not a wave")


func test_r64_the_think_interval_is_the_reaction_time() -> void:
	var w := FakeWorld.new()
	w.gold = 1000
	var b := _brain(w)
	b.think_interval = 1.0
	for i in 9:
		b.tick(0.1)
	assert_true(w.orders.is_empty(), "not before a second")
	b.tick(0.15)
	assert_false(w.orders.is_empty())


func test_r64_presets_from_easy_to_hard() -> void:
	var easy := RtsAiBrain.preset(0)
	var normal := RtsAiBrain.preset(1)
	var hard := RtsAiBrain.preset(2)
	assert_gt(easy.think_interval, normal.think_interval)
	assert_gt(normal.think_interval, hard.think_interval)
	assert_lt(easy.income_multiplier, hard.income_multiplier)
	assert_almost_eq(float(normal.income_multiplier), 1.0, 0.0001, "normal plays fair")
	assert_true(int(easy.production) < int(normal.production) and int(normal.production) < int(hard.production), "production buildings rise with the level")
	assert_true(int(easy.max_supply) < int(normal.max_supply) and int(normal.max_supply) < int(hard.max_supply), "… and so does the army's food ceiling")
	var b := RtsAiBrain.new()
	b.apply_preset(2)
	assert_almost_eq(b.think_interval, 0.5, 0.0001)


func test_r64_a_stalled_army_attacks_with_what_it_has() -> void:
	var w := FakeWorld.new()
	var b := _brain(w)
	b.wave_size = 3
	for i in 3:
		w.army_units.append(i)
	b.think()
	assert_eq(b.waves_sent, 1, "the first wave goes")
	w.army_units.clear()
	b.think()
	assert_false(b.attacking, "… and is gone")
	for i in 2:
		w.army_units.append(10 + i)                   # 2 at home, the next wave wants 5, and the gold is gone
	for i in 30:
		b.think()
	assert_eq(b.waves_sent, 1, "30 s without growth: still home")
	for i in 40:
		b.think()
	assert_eq(b.waves_sent, 2, "stall_after s without growth: the wave goes with its 2")


func test_r64_the_stall_rule_waits_for_the_first_wave() -> void:
	var w := FakeWorld.new()
	var b := _brain(w)
	b.wave_size = 12
	for i in 2:
		w.army_units.append(i)
	for i in 120:
		b.think()
	assert_eq(b.waves_sent, 0, "no first wave from a stall: the start's saving pauses don't send 2 units")


func test_r64_a_retreated_army_rebuilds_before_it_goes_again() -> void:
	var w := FakeWorld.new()
	var b := _brain(w)
	b.wave_size = 3
	for i in 4:
		w.army_units.append(i)
	b.think()
	assert_eq(b.waves_sent, 1, "a wave goes")
	w.enemy_power = 1000.0
	b.think()
	assert_eq(w.retreats, 1, "outmatched: it retreats")
	w.enemy_power = 0.0
	for i in 50:
		b.think()
	assert_eq(b.waves_sent, 1, "within stall_after s of the retreat it is not sent back")


func test_r64_a_slowly_growing_army_never_stalls() -> void:
	var w := FakeWorld.new()
	var b := _brain(w)
	b.wave_size = 3
	for i in 3:
		w.army_units.append(i)
	b.think()
	w.army_units.clear()
	b.think()
	b.wave_size = 20
	for step in 6:
		w.army_units.append(100 + step)               # one more every 50 s
		for i in 50:
			b.think()
	assert_eq(b.waves_sent, 1, "growing (slowly): no stall wave, it waits for its size")


func test_r64_no_wave_before_the_floor_and_a_capped_first_wave() -> void:
	var w := FakeWorld.new()
	var b := _brain(w)
	b.wave_size = 3
	b.first_wave_not_before = 240.0
	b.cap_first_wave = true
	for i in 7:
		w.army_units.append(i)
	for i in 239:
		b.tick(1.0)
	assert_eq(b.waves_sent, 0, "a big enough army waits for the floor (239 s)")
	b.tick(1.0)
	assert_eq(b.waves_sent, 1, "the first wave leaves at the floor")
	assert_eq(w.attacks, 1, "… once")
	b.tick(1.0)
	assert_eq(w.attacks, 2, "and keeps pushing")
	assert_eq(b._first.size(), 3, "with its 3 units only: the other 4 stay home")
	w.army_units.remove_at(0)
	w.army_units.remove_at(0)
	w.army_units.remove_at(0)
	b.tick(1.0)
	assert_false(b.attacking, "the first wave is gone: no longer attacking")
	assert_eq(b._first.size(), 0, "… and the home army is not sent after it")


func test_r64_the_first_wave_retreats_by_what_it_meets() -> void:
	var w := WaveWorld.new()
	var b := _brain(w)
	b.wave_size = 2
	b.cap_first_wave = true
	for i in 6:
		w.army_units.append(i)
	b.think()
	assert_eq(b._first.size(), 2, "the first wave is 2 of the 6")
	w.danger_at = Vector3(50, 0, 50)
	w.enemy_power = 1000.0
	b.think()
	assert_eq(w.retreats, 1, "a strong enemy where the wave is: it retreats (the home units don't hide it)")


func test_r64_home_units_defend_while_the_first_wave_is_out() -> void:
	var w := WaveWorld.new()
	var b := _brain(w)
	b.wave_size = 2
	b.cap_first_wave = true
	for i in 6:
		w.army_units.append(i)
	b.think()
	w.danger = Vector3(-5, 0, -5)
	var before := w.attacks
	b.think()
	assert_eq(w.attacks - before, 2, "the wave keeps pushing and the home units go at the threat")
	assert_eq(w.attack_at, Vector3(-5, 0, -5), "… at the threat")
	assert_eq(w.last_units, [2, 3, 4, 5], "… the home units, not the wave")


class WaveWorld:
	extends FakeWorld
	var danger_at := Vector3.INF
	var last_units: Array = []

	func attack(units: Array, at: Vector3) -> void:
		super(units, at)
		last_units = units.duplicate()

	func centre_of(units: Array) -> Vector3:
		return Vector3(50, 0, 50) if units.size() <= 2 else Vector3.ZERO

	func enemy_power_near(at: Vector3) -> float:
		return enemy_power if at == danger_at else 0.0
