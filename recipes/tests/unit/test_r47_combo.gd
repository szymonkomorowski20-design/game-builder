extends GutTest
## R47 — melee combo: each step goes windup → active (the only time it can hit) → recovery; pressing attack during
## recovery, or within `buffer_time` before it, chains the next step at once; a press too early is dropped; no press →
## back to idle and the chain restarts; after the last step a press loops to the first; a dash may cancel recovery
## but not the committed windup/active; every active window gets a new hit id (one hit per target per swing).

const DT := 1.0 / 60.0

var combo: ComboAttack


func _step(windup: float, active: float, recovery: float, damage: int) -> AttackStep:
	var s := AttackStep.new()
	s.windup = windup
	s.active = active
	s.recovery = recovery
	s.damage = damage
	return s


func before_each() -> void:
	combo = ComboAttack.new()
	combo.steps = [_step(0.10, 0.05, 0.20, 10), _step(0.10, 0.05, 0.20, 12), _step(0.15, 0.10, 0.35, 25)]
	combo.buffer_time = 0.15


## Advances in physics-frame steps; returns the phases seen, in order, without repeats.
func _run(seconds: float) -> Array:
	var seen := []
	for i in roundi(seconds / DT):
		combo.tick(DT)
		var tag := "%d:%s" % [combo.step_index, ComboAttack.Phase.keys()[combo.phase]]
		if seen.is_empty() or seen.back() != tag:
			seen.append(tag)
	return seen


func test_r47_one_press_runs_one_step_then_idles() -> void:
	combo.press()
	assert_eq(combo.phase, ComboAttack.Phase.WINDUP)
	assert_eq(combo.step_index, 0)
	assert_eq(_run(0.5), ["0:WINDUP", "0:ACTIVE", "0:RECOVERY", "-1:IDLE"])


func _frames(n: int) -> void:
	for i in n:
		combo.tick(DT)


func test_r47_timings_are_exact_to_the_frame() -> void:
	combo.press()
	_frames(5)
	assert_eq(combo.phase, ComboAttack.Phase.WINDUP, "frame 5 (0.083 s): still winding up")
	_frames(1)
	assert_eq(combo.phase, ComboAttack.Phase.ACTIVE, "frame 6 (0.10 s): active")
	_frames(3)
	assert_eq(combo.phase, ComboAttack.Phase.RECOVERY, "frame 9 (0.15 s): recovery")
	_frames(11)
	assert_eq(combo.phase, ComboAttack.Phase.RECOVERY, "frame 20: still recovering")
	_frames(1)
	assert_eq(combo.phase, ComboAttack.Phase.IDLE, "frame 21 (0.35 s): idle")


func test_r47_press_in_recovery_chains_immediately() -> void:
	combo.press()
	_run(0.20)                      # in step 0's recovery
	combo.press()
	assert_eq(combo.step_index, 1, "the second step starts on the press")
	assert_eq(combo.phase, ComboAttack.Phase.WINDUP)


func test_r47_press_shortly_before_recovery_is_buffered() -> void:
	combo.press()
	_run(0.05)                      # windup; recovery starts at 0.15 → press is 0.10 s early (buffer 0.15)
	combo.press()
	assert_eq(combo.step_index, 0, "no chain during the committed windup")
	_run(0.10 + DT)
	assert_eq(combo.step_index, 1, "the buffered press chains the moment recovery begins")


func test_r47_press_too_early_is_dropped() -> void:
	combo.buffer_time = 0.05
	combo.press()
	combo.press()                   # 0.15 s before recovery, buffer only 0.05
	assert_eq(_run(0.5), ["0:WINDUP", "0:ACTIVE", "0:RECOVERY", "-1:IDLE"], "no second step")


func test_r47_no_press_resets_the_chain() -> void:
	combo.press()
	_run(0.5)
	combo.press()
	assert_eq(combo.step_index, 0, "a new press after idling starts from the first step")


func test_r47_full_chain_then_loops() -> void:
	combo.press()
	for i in 2:
		_run(0.16)                  # into recovery
		combo.press()
	assert_eq(combo.step_index, 2, "third (finisher) step")
	_run(0.26)                      # into the finisher's recovery (0.15 + 0.10)
	combo.press()
	assert_eq(combo.step_index, 2, "no chain beyond the last step during its recovery")
	_run(0.40)
	assert_eq(combo.step_index, 0, "the buffered press loops back to the first step after the finisher")


func test_r47_dash_cancels_recovery_only() -> void:
	combo.press()
	assert_false(combo.try_dash_cancel(), "windup is committed")
	_run(0.12)
	assert_false(combo.try_dash_cancel(), "active is committed")
	_run(0.05)
	assert_true(combo.try_dash_cancel(), "recovery can be cancelled by a dash")
	assert_eq(combo.phase, ComboAttack.Phase.IDLE)
	assert_eq(combo.step_index, -1)


func test_r47_each_swing_has_its_own_hit_id() -> void:
	var ids := []
	combo.hit_window_opened.connect(func(_i: int, id: int): ids.append(id))
	combo.press()
	_run(0.20)
	combo.press()
	_run(0.20)
	assert_eq(ids.size(), 2, "two active windows")
	assert_ne(ids[0], ids[1], "new id per swing")
	assert_true(combo.is_hitting() == false)


func test_r47_current_damage_follows_the_step() -> void:
	combo.press()
	assert_eq(combo.current_step().damage, 10)
	_run(0.16)
	combo.press()
	assert_eq(combo.current_step().damage, 12)
