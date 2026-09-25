extends GutTest
## R05 — damage, i-frames, death once, heal clamps, the dead cannot be healed.


func _hp(max_hp: int = 5) -> Health:
	var h := Health.new()
	h.max_health = max_hp
	add_child_autofree(h)
	return h


func test_r05_damage_reduces_health() -> void:
	var h := _hp()
	assert_eq(h.take_damage(2), 2)
	assert_eq(h.current, 3)


func test_r05_invulnerability_blocks_then_expires() -> void:
	var h := _hp()
	h.take_damage(1)
	assert_eq(h.take_damage(1), 0, "second hit inside i-frames is ignored")
	h.advance(h.invulnerability_time + 0.01)
	assert_eq(h.take_damage(1), 1, "hit after i-frames lands")


func test_r05_died_emitted_exactly_once_and_overkill_clamped() -> void:
	var h := _hp(3)
	watch_signals(h)
	assert_eq(h.take_damage(10), 3, "overkill applies only what is left")
	h.advance(1.0)
	h.take_damage(1)
	assert_signal_emit_count(h, "died", 1)
	assert_true(h.is_dead())


func test_r05_heal_clamps_and_dead_stay_dead() -> void:
	var h := _hp(5)
	h.take_damage(2)
	assert_eq(h.heal(10), 2)
	assert_eq(h.current, 5)
	h.advance(1.0)
	h.take_damage(5)
	assert_eq(h.heal(3), 0, "no healing the dead")


func test_r05_zero_and_negative_amounts_do_nothing() -> void:
	var h := _hp()
	assert_eq(h.take_damage(0), 0)
	assert_eq(h.take_damage(-3), 0)
	assert_eq(h.current, 5)
