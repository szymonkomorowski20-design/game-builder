extends GutTest
## T-unit — damage respects invulnerability, healing caps at max, death fires once.

const PLAYER := preload("res://scenes/player/player.tscn")


func _player() -> TopDownPlayer:
	var p: TopDownPlayer = PLAYER.instantiate()
	add_child_autofree(p)
	p.set_physics_process(false)   # no input / timers ticking during the test
	return p


func test_damage_then_invulnerable() -> void:
	var p := _player()
	assert_eq(p.health, p.tuning.max_health)
	assert_eq(p.take_damage(2), 2)
	assert_true(p.is_invulnerable())
	assert_eq(p.take_damage(2), 0, "no damage during invulnerability")
	assert_eq(p.health, p.tuning.max_health - 2)


func test_heal_caps_at_max() -> void:
	var p := _player()
	p.take_damage(1)
	assert_eq(p.heal(5), 1)
	assert_eq(p.health, p.tuning.max_health)
	assert_eq(p.heal(1), 0, "full health heals nothing")


func test_death_fires_once() -> void:
	var p := _player()
	watch_signals(p)
	p.take_damage(99)
	assert_true(p.is_dead())
	assert_eq(p.health, 0)
	p._invulnerable = 0.0
	assert_eq(p.take_damage(1), 0, "dead players take no damage")
	assert_signal_emit_count(p, "died", 1)
