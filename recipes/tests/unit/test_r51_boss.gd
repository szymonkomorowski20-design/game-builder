extends GutTest
## R51 — boss brain: HP thresholds change the phase once each, and a big hit stops at the threshold (it cannot skip a
## phase); the boss is invulnerable during the phase transition; attacks run telegraph → strike → recovery, a phase-
## locked attack only appears from its phase, the same attack is not used twice in a row when there is a choice, the
## choice is deterministic for a seed; validate() flags telegraphs too short to read and windows too short to punish;
## death fires once and stops attacking.

const DT := 1.0 / 60.0

var boss: BossBrain


func _attack(id: StringName, telegraph: float, strike: float, recovery: float, min_phase: int = 0) -> BossAttack:
	var a := BossAttack.new()
	a.id = id
	a.telegraph = telegraph
	a.strike = strike
	a.recovery = recovery
	a.min_phase = min_phase
	return a


func before_each() -> void:
	boss = BossBrain.new()
	boss.max_health = 300
	boss.thresholds = [0.66, 0.33]
	boss.transition_time = 1.0
	boss.attacks = [_attack(&"slam", 0.6, 0.2, 0.8), _attack(&"sweep", 0.5, 0.3, 0.7), _attack(&"storm", 0.8, 0.5, 1.0, 1)]
	boss.start(11)


func _frames(n: int) -> void:
	for i in n:
		boss.tick(DT)


func _collect_attack_ids(seconds: float) -> Array:
	var ids := []
	boss.attack_started.connect(func(a: BossAttack): ids.append(a.id))
	_frames(roundi(seconds / DT))
	return ids


func test_r51_phase_changes_once_and_big_hits_stop_at_the_threshold() -> void:
	var phases := []
	boss.phase_changed.connect(func(p: int): phases.append(p))
	boss.take_damage(250)
	assert_eq(boss.health, 198, "a 250 hit stops at the 66% threshold (198 of 300)")
	assert_eq(boss.phase, 1)
	assert_true(boss.is_invulnerable(), "transition: invulnerable")
	boss.take_damage(50)
	assert_eq(boss.health, 198, "damage ignored while transitioning")
	_frames(61)
	assert_false(boss.is_invulnerable())
	boss.take_damage(10)
	assert_eq(boss.health, 188)
	boss.take_damage(500)
	assert_eq(boss.health, 99, "stops at 33% too")
	assert_eq(phases, [1, 2], "each phase change fired once, in order")


func test_r51_attack_cycle_timings() -> void:
	var a := boss.current_attack()
	assert_not_null(a, "the boss starts its first attack")
	assert_true(boss.is_telegraphing())
	_frames(roundi(a.telegraph / DT) - 1)
	assert_true(boss.is_telegraphing(), "still telegraphing one frame before the end")
	assert_almost_eq(boss.state_elapsed(), a.telegraph - DT, 1e-3, "state_elapsed tracks the telegraph")
	_frames(1)
	assert_true(boss.is_striking(), "strike right after the telegraph")
	_frames(roundi(a.strike / DT))
	assert_true(boss.is_recovering(), "then the window to punish")


func test_r51_no_repeat_and_deterministic() -> void:
	var ids := _collect_attack_ids(20.0)
	assert_gt(ids.size(), 5)
	for i in range(1, ids.size()):
		assert_ne(ids[i], ids[i - 1], "no attack twice in a row (at %d)" % i)
	var again := BossBrain.new()
	again.max_health = 300
	again.thresholds = [0.66, 0.33]
	again.attacks = boss.attacks
	var ids2 := []
	again.attack_started.connect(func(a: BossAttack): ids2.append(a.id))
	again.start(11)
	for i in roundi(20.0 / DT):
		again.tick(DT)
	ids.push_front(ids2[0])   # the first attack of `boss` started in before_each, before we listened
	assert_eq(ids2.slice(0, 5), ids.slice(0, 5), "same seed → same attack order")


func test_r51_phase_locked_attacks() -> void:
	var early := _collect_attack_ids(30.0)
	assert_false(early.has(&"storm"), "phase-1 attack not used in phase 0")
	boss.take_damage(110)
	_frames(61)
	var later := _collect_attack_ids(30.0)
	assert_true(later.has(&"storm"), "used once phase 1 is reached")


func test_r51_validate_flags_unreadable_attacks() -> void:
	boss.min_telegraph = 0.4
	boss.min_window = 0.5
	assert_eq(boss.validate(), [], "the good set passes")
	boss.attacks.append(_attack(&"cheap_shot", 0.15, 0.2, 0.8))
	boss.attacks.append(_attack(&"relentless", 0.6, 0.2, 0.1))
	var problems := boss.validate()
	assert_eq(problems.size(), 2)
	assert_string_contains(problems[0], "cheap_shot")
	assert_string_contains(problems[1], "relentless")


func test_r51_death_once_and_silence() -> void:
	var deaths := [0]
	boss.died.connect(func(): deaths[0] += 1)
	for i in 3:
		boss.take_damage(1000)
		_frames(61)
	assert_eq(boss.health, 0)
	assert_eq(deaths[0], 1)
	var after := _collect_attack_ids(5.0)
	assert_eq(after, [], "a dead boss does not attack")
