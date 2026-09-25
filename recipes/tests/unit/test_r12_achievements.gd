extends GutTest
## R12 — unlock at the threshold, exactly once; survives a save round trip without re-firing.


func _ach() -> Achievements:
	var a := Achievements.new()
	a.define(&"collector", &"coins", 10)
	a.define(&"rich", &"coins", 100)
	return a


func test_r12_unlocks_at_threshold_once() -> void:
	var a := _ach()
	watch_signals(a)
	a.add_stat(&"coins", 9)
	assert_false(a.is_unlocked(&"collector"))
	a.add_stat(&"coins", 1)
	assert_true(a.is_unlocked(&"collector"))
	a.add_stat(&"coins", 5)
	assert_signal_emit_count(a, "unlocked", 1)
	assert_false(a.is_unlocked(&"rich"))


func test_r12_round_trip_does_not_refire() -> void:
	var a := _ach()
	a.add_stat(&"coins", 12)
	var b := _ach()
	b.load_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	watch_signals(b)
	assert_true(b.is_unlocked(&"collector"))
	b.add_stat(&"coins", 1)
	assert_signal_not_emitted(b, "unlocked")
	assert_eq(b.stats[&"coins"], 13)
