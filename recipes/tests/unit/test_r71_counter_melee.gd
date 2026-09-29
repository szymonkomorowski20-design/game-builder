extends GutTest
## Recipe 71 — counter-based melee: the stage manager's weighted grid and attack capacity (attackers take turns,
## cooldowns), slot positions; the strike timeline; counters, perfect counters, blocks and dodges, mashing that
## shrinks the window, unblockable strikes, one press per hit; target picking with reach shrinking by angle.


func test_r71_grid_by_weight() -> void:
	var stage := MeleeStage.new()
	var troll := RefCounted.new()
	var soldier := RefCounted.new()
	var soldier2 := RefCounted.new()
	assert_gte(stage.engage(troll, 8), 0, "a troll takes a slot (weight 8 of 12)")
	assert_gte(stage.engage(soldier, 4), 0, "a soldier fills the grid (12 of 12)")
	assert_eq(stage.engage(soldier2, 4), -1, "a second soldier waits outside")
	assert_eq(stage.engage(soldier, 4), stage.engage(soldier, 4), "asking again: the same slot")
	stage.disengage(troll)
	assert_gte(stage.engage(soldier2, 4), 0, "the troll gone, the soldier steps in")
	var a := stage.slot_position(0, Vector3.ZERO, 2.0)
	var b := stage.slot_position(4, Vector3.ZERO, 2.0)
	assert_almost_eq(a, Vector3(0, 0, -2), Vector3.ONE * 1e-5, "slot 0 in front")
	assert_almost_eq(b, Vector3(0, 0, 2), Vector3.ONE * 1e-5, "slot 4 behind")


func test_r71_attackers_take_turns() -> void:
	var stage := MeleeStage.new()
	var a := RefCounted.new()
	var b := RefCounted.new()
	var outsider := RefCounted.new()
	stage.engage(a, 4)
	stage.engage(b, 4)
	assert_false(stage.may_attack(outsider, 2, 0.0), "only engaged fighters strike")
	assert_true(stage.may_attack(a, 3, 0.0), "the first strike")
	assert_false(stage.may_attack(b, 3, 1.0), "over the attack capacity: wait")
	stage.attack_done(a)
	assert_true(stage.may_attack(b, 3, 1.1), "freed the moment the strike lands: the next attacker goes")
	stage.attack_done(b)
	assert_false(stage.may_attack(a, 3, 1.46), "the same fighter waits out its own cooldown (the global one is over)")
	assert_true(stage.may_attack(a, 3, 1.6), "then strikes again")
	stage.attack_done(a)
	var c := RefCounted.new()
	stage.engage(c, 2)
	assert_false(stage.may_attack(c, 1, 1.7), "a fresh fighter still waits out the global cooldown")
	assert_true(stage.may_attack(c, 1, 2.0), "then goes")


func test_r71_strike_timeline() -> void:
	var one := EnemyStrike.make(EnemyStrike.Kind.NORMAL)
	assert_eq(one.hit_times(2.0).size(), 1, "one hit")
	assert_almost_eq(one.hit_times(2.0)[0], 2.7, 1e-5, "after the windup")
	assert_gt(one.windup, 0.3, "slower than human reaction")
	assert_almost_eq(one.flash_time(2.0), 2.35, 1e-5, "the flash before the hit")
	var combo := EnemyStrike.make(EnemyStrike.Kind.COMBO, 3)
	var times := combo.hit_times(0.0)
	assert_eq(times.size(), 3, "three hits")
	assert_almost_eq(times[1] - times[0], combo.combo_gap, 1e-5, "the gap between hits")
	assert_lt(combo.combo_gap, combo.windup, "the next hits come faster than the first")
	assert_almost_eq(combo.duration(), 0.7 + 0.7 + 0.8, 1e-5, "windup, two gaps, recovery")


func test_r71_counter_block_dodge() -> void:
	var d := CounterDefense.new()
	d.press_counter(0.8)
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 1.0), CounterDefense.Result.COUNTERED, "0.2 s before the hit: countered")
	d.press_counter(1.95)
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 2.0), CounterDefense.Result.PERFECT, "0.05 s before: perfect")
	d.press_counter(2.5)
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 3.0), CounterDefense.Result.HIT, "0.5 s before: too early")
	d.press_counter(4.05)
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 4.0), CounterDefense.Result.HIT, "after the hit: too late")
	d.blocking = true
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 5.0), CounterDefense.Result.BLOCKED, "held block")
	d.blocking = false
	d.press_dodge(5.8)
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 6.0), CounterDefense.Result.DODGED, "a dodge in time")


func test_r71_mashing_shrinks_the_window() -> void:
	var d := CounterDefense.new()
	for t in [10.0, 10.1, 10.2, 10.3]:
		d.press_counter(t)
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 10.45), CounterDefense.Result.HIT, "four presses in half a second: no counter")
	var calm := CounterDefense.new()
	calm.press_counter(10.3)
	assert_eq(calm.resolve(EnemyStrike.Kind.NORMAL, 10.45), CounterDefense.Result.COUNTERED, "one press at the same moment counters")


func test_r71_unblockable() -> void:
	var d := CounterDefense.new()
	d.blocking = true
	assert_eq(d.resolve(EnemyStrike.Kind.UNBLOCKABLE, 1.0), CounterDefense.Result.GUARD_BROKEN, "a block breaks")
	d.blocking = false
	d.press_counter(1.8)
	assert_eq(d.resolve(EnemyStrike.Kind.UNBLOCKABLE, 2.0), CounterDefense.Result.GUARD_BROKEN, "a counter breaks too")
	d.press_dodge(2.8)
	assert_eq(d.resolve(EnemyStrike.Kind.UNBLOCKABLE, 3.0), CounterDefense.Result.DODGED, "dodge it")
	assert_eq(d.resolve(EnemyStrike.Kind.UNBLOCKABLE, 4.0), CounterDefense.Result.HIT, "nothing: hit")


func test_r71_one_press_one_hit() -> void:
	var d := CounterDefense.new()
	d.press_counter(0.8)
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 1.0), CounterDefense.Result.COUNTERED, "the first of two simultaneous hits")
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 1.0), CounterDefense.Result.HIT, "the second needs its own press")
	d.press_counter(1.5)
	d.forget_before(2.0)
	assert_eq(d.resolve(EnemyStrike.Kind.NORMAL, 1.6), CounterDefense.Result.HIT, "forgotten presses answer nothing")


func test_r71_target_pick() -> void:
	var enemies: Array[Vector3] = [Vector3(1, 0, -1.7), Vector3(0, 0, 1.5), Vector3(2.5, 0, 0)]
	assert_eq(MeleeTarget.pick(Vector3.ZERO, Vector3(0, 0, -1), enemies), 0, "input forward: the one ahead (30° off)")
	assert_eq(MeleeTarget.pick(Vector3.ZERO, Vector3(0, 0, 1), enemies), 1, "input back: the one behind")
	assert_eq(MeleeTarget.pick(Vector3.ZERO, Vector3(1, 0, 0), [Vector3(0, 0, -2.5)] as Array[Vector3]), -1,
			"at 90° the reach shrinks to 0.9 m: not pulled in from 2.5 m")
	assert_eq(MeleeTarget.pick(Vector3.ZERO, Vector3(0, 0, -1), [Vector3(0, 0, -5)] as Array[Vector3]), -1,
			"beyond reach: attack the air")
	assert_eq(MeleeTarget.pick(Vector3.ZERO, Vector3.ZERO, enemies), -1, "no direction at all: none")
