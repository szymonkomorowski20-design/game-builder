extends GutTest
## R43 — dash: burst for `duration`, blocked during `cooldown`, invulnerable during the burst + iframes_after, no dash
## without a direction. Knockback: away from the source, decays linearly to zero, a new hit replaces the push.


func _run(d: Dash, seconds: float, step := 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		d.tick(step)
		t += step


func test_r43_dash_burst_then_stop() -> void:
	var d := Dash.new()
	assert_true(d.try_start(Vector2(3, 4)))
	assert_true(d.velocity().is_equal_approx(Vector2(0.6, 0.8) * d.speed), "normalized direction × speed")
	_run(d, d.duration + 0.02)
	assert_false(d.is_dashing())
	assert_eq(d.velocity(), Vector2.ZERO)


func test_r43_cooldown_blocks_a_second_dash() -> void:
	var d := Dash.new()
	d.try_start(Vector2.RIGHT)
	_run(d, d.duration + 0.05)
	assert_false(d.try_start(Vector2.RIGHT), "blocked during the cooldown")
	_run(d, d.cooldown)
	assert_true(d.try_start(Vector2.RIGHT), "allowed after the cooldown")


func test_r43_no_direction_no_dash() -> void:
	var d := Dash.new()
	assert_false(d.try_start(Vector2.ZERO))
	assert_false(d.is_dashing())


func test_r43_invulnerable_through_the_burst_and_the_extra_frames() -> void:
	var d := Dash.new()
	assert_false(d.is_invulnerable(), "not before dashing")
	d.try_start(Vector2.UP)
	_run(d, d.duration + d.iframes_after * 0.5)
	assert_true(d.is_invulnerable(), "still invulnerable just after the burst")
	_run(d, d.iframes_after)
	assert_false(d.is_invulnerable(), "vulnerable again")


func test_r43_knockback_away_and_decaying() -> void:
	var k := Knockback.new()
	k.hit(Vector2(0, 0), Vector2(10, 0), 300.0)
	assert_true(k.velocity().is_equal_approx(Vector2(300, 0)), "away from the source at full strength")
	k.tick(k.duration * 0.5)
	assert_true(k.velocity().is_equal_approx(Vector2(150, 0)), "half way → half strength")
	k.tick(k.duration * 0.5)
	assert_eq(k.velocity(), Vector2.ZERO, "gone after `duration`")
	assert_false(k.active())


func test_r43_a_new_hit_replaces_the_push() -> void:
	var k := Knockback.new()
	k.hit(Vector2.ZERO, Vector2(10, 0), 300.0)
	k.hit(Vector2.ZERO, Vector2(0, -10), 200.0)
	assert_true(k.velocity().is_equal_approx(Vector2(0, -200)), "no stacking into a launch")
	k.hit(Vector2(5, 5), Vector2(5, 5), 200.0)
	assert_eq(k.velocity(), Vector2.ZERO, "a hit from the body's own position pushes nowhere")
