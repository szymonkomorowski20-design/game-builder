extends GutTest
## F-unit — a target loses `damage` per hit, is destroyed exactly once at 0, and ignores hits after that.

const TARGET := preload("res://scenes/targets/target.tscn")


func test_f_target_health_and_single_destroy() -> void:
	var t: ShootTarget = TARGET.instantiate()
	add_child_autofree(t)
	t.health = 3
	watch_signals(t)
	t.take_damage(1)
	t.take_damage(1)
	assert_eq(t.health, 1)
	assert_signal_emit_count(t, "destroyed", 0)
	t.take_damage(1)
	assert_signal_emit_count(t, "destroyed", 1)
	t.take_damage(1)
	assert_signal_emit_count(t, "destroyed", 1, "a destroyed target is not destroyed twice")
	assert_eq(t.hits, 3, "the hit after destruction is ignored")


func test_f_bigger_damage_kills_faster() -> void:
	var t: ShootTarget = TARGET.instantiate()
	add_child_autofree(t)
	t.health = 3
	watch_signals(t)
	t.take_damage(5)
	assert_signal_emit_count(t, "destroyed", 1)
