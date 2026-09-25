extends GutTest
## R08 — cooldown, magazine, empty signal, reload timing, no firing while reloading.


func _weapon() -> Weapon:
	var world := Node2D.new()
	add_child_autofree(world)   # fired projectiles land here and are freed with it
	var w := Weapon.new()
	w.magazine_size = 3
	w.cooldown = 0.2
	w.reload_time = 1.0
	w.spawn_parent = world
	world.add_child(w)
	return w


func test_r08_cooldown_blocks_rapid_fire() -> void:
	var w := _weapon()
	assert_true(w.try_fire(Vector2.RIGHT))
	assert_false(w.try_fire(Vector2.RIGHT), "second shot inside cooldown is blocked")
	w.advance(0.21)
	assert_true(w.try_fire(Vector2.RIGHT))


func test_r08_projectiles_are_not_children_of_the_weapon() -> void:
	var w := _weapon()
	var got: Array = []
	w.fired.connect(func(p: Node2D) -> void: got.append(p))
	w.try_fire(Vector2.RIGHT)
	assert_eq(got.size(), 1)
	assert_ne(got[0].get_parent(), w, "a projectile parented to the weapon would follow it after firing")


func test_r08_magazine_empties_and_signals() -> void:
	var w := _weapon()
	watch_signals(w)
	for i in 3:
		assert_true(w.try_fire(Vector2.RIGHT))
		w.advance(0.21)
	assert_eq(w.ammo, 0)
	assert_false(w.try_fire(Vector2.RIGHT))
	assert_signal_emitted(w, "empty")


func test_r08_reload_takes_reload_time_and_blocks_fire() -> void:
	var w := _weapon()
	w.try_fire(Vector2.RIGHT)
	w.advance(0.21)
	w.reload()
	assert_true(w.is_reloading())
	assert_false(w.try_fire(Vector2.RIGHT), "cannot fire while reloading")
	w.advance(0.5)
	assert_eq(w.ammo, 2, "not reloaded yet")
	w.advance(0.6)
	assert_eq(w.ammo, 3, "full after reload_time")


func test_r08_reload_with_full_magazine_does_nothing() -> void:
	var w := _weapon()
	w.reload()
	assert_false(w.is_reloading())
