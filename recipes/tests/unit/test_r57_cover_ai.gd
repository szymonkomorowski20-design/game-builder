extends GutTest
## Recipe 57 — cover-shooter AI: the soldier's decisions (move, cover, peek, reload, flank, suppression, tokens,
## accuracy ramp) and the cover finder (hidden when crouched, sees when standing; the band; occupied; flanks).

const DT := 1.0 / 60.0


func _brain() -> ShooterBrain:
	var b := ShooterBrain.new()
	b.move_to(Vector3(1, 0, 1))
	return b


func _run(b: ShooterBrain, seconds: float, arrived := true, sees := true, moved := true) -> void:
	for i in roundi(seconds / DT):
		b.tick(DT, arrived, sees, moved)


func test_r57_move_cover_peek_cycle() -> void:
	var b := _brain()
	assert_eq(b.state, ShooterBrain.Mode.MOVE)
	b.tick(DT, true, true, true)
	assert_eq(b.state, ShooterBrain.Mode.COVER, "arrived → cover")
	_run(b, b.peek_wait + 0.05)
	assert_eq(b.state, ShooterBrain.Mode.PEEK, "after peek_wait → peek")
	_run(b, b.peek_time + 0.05)
	assert_eq(b.state, ShooterBrain.Mode.COVER, "after peek_time → back in cover")


func test_r57_accuracy_ramps_while_exposed() -> void:
	var b := _brain()
	b.tick(DT, true, true, true)
	_run(b, b.peek_wait + 0.05)
	var first := b.accuracy()
	assert_almost_eq(first, b.accuracy_min, 0.03, "the first shots at a player who just appeared mostly miss")
	_run(b, b.aim_time * 0.5)
	assert_gt(b.accuracy(), first, "aim improves with exposure")
	assert_true(b.accuracy() <= b.accuracy_max + 1e-6)
	assert_almost_eq(b.accuracy(0.5), b.accuracy() * 0.5, 1e-6, "difficulty scales accuracy, not the tells")


func test_r57_empty_magazine_reloads_in_cover_and_barks() -> void:
	var b := _brain()
	b.magazine = 3
	b.rounds = 3
	var barks: Array[StringName] = []
	b.bark.connect(func(k: StringName) -> void: barks.append(k))
	b.tick(DT, true, true, true)
	_run(b, b.peek_wait + 0.05)
	assert_true(b.fire_round() and b.fire_round() and b.fire_round())
	assert_eq(b.state, ShooterBrain.Mode.RELOAD, "empty → reload in cover")
	assert_true(barks.has(&"reloading"), "it says so (the player can push)")
	assert_false(b.fire_round(), "no firing while reloading")
	_run(b, b.reload_time + 0.05)
	assert_eq([b.state, b.rounds], [ShooterBrain.Mode.COVER, 3])


func test_r57_suppression_sends_it_back_and_delays_the_next_peek() -> void:
	var b := _brain()
	b.tick(DT, true, true, true)
	_run(b, b.peek_wait + 0.05)
	b.suppress()
	assert_eq(b.state, ShooterBrain.Mode.COVER, "hit while peeking → back into cover")
	_run(b, b.peek_wait + 0.1)
	assert_eq(b.state, ShooterBrain.Mode.COVER, "the next peek waits longer while suppressed")
	_run(b, b.suppressed_extra)
	assert_eq(b.state, ShooterBrain.Mode.PEEK)


func test_r57_flank_when_the_player_camps() -> void:
	var b := _brain()
	var barks: Array[StringName] = []
	b.bark.connect(func(k: StringName) -> void: barks.append(k))
	b.peek_wait = 999.0      # stay in cover to see the flank decision alone
	b.tick(DT, true, true, false)
	_run(b, b.flank_after + 0.1, true, true, false)
	assert_eq(b.state, ShooterBrain.Mode.FLANK, "a player who doesn't move gets flanked")
	assert_true(barks.has(&"flanking"))
	b.tick(DT, true, true, false)
	assert_eq(b.state, ShooterBrain.Mode.FLANK, "it waits for the body to pick the flank cover (arriving at the old spot does not count)")
	b.move_to(Vector3(-8, 0, -6))
	b.tick(DT, false, true, false)
	assert_eq(b.state, ShooterBrain.Mode.FLANK, "on the way")
	b.tick(DT, true, true, false)
	assert_eq(b.state, ShooterBrain.Mode.COVER, "arrived at the flank cover")


func test_r57_tokens_limit_simultaneous_shooters() -> void:
	var t := AttackTokens.new()
	t.limit = 1
	var a := _brain()
	var c := _brain()
	a.tokens = t
	c.tokens = t
	for b in [a, c]:
		b.tick(DT, true, true, true)
	for i in roundi((a.peek_wait + 0.05) / DT):
		a.tick(DT, true, true, true)
		c.tick(DT, true, true, true)
	assert_eq([a.state, c.state], [ShooterBrain.Mode.PEEK, ShooterBrain.Mode.COVER], "one token: only one shooter peeks")
	for i in roundi((a.peek_time + 0.1) / DT):
		a.tick(DT, true, true, true)
		c.tick(DT, true, true, true)
	assert_eq(c.state, ShooterBrain.Mode.PEEK, "the token passes on when the first goes back into cover")


func _crate(at: Vector3, height: float) -> StaticBody3D:
	var s := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, height, 0.4)
	c.shape = box
	c.position = Vector3(0, height * 0.5, 0)
	s.add_child(c)
	add_child_autofree(s)
	s.global_position = at
	return s


func test_r57_cover_finder_hidden_crouched_visible_standing() -> void:
	# Player at z = 0 looking toward −z; a waist-high crate at z = −12 hides a point just behind it.
	_crate(Vector3(0, 0, -12), 1.2)
	_crate(Vector3(6, 0, -12), 3.0)          # a tall wall: hides, but can't be peeked over
	await wait_physics_frames(2)
	var space := get_tree().root.get_world_3d().direct_space_state
	var f := CoverFinder.new()
	var eye := Vector3(0, 1.6, 0)
	assert_true(f.is_useful(space, Vector3(0, 0, -12.6), eye), "behind the low crate: hidden crouched, sees standing")
	assert_false(f.is_useful(space, Vector3(-6, 0, -12.6), eye), "open ground: no cover")
	assert_false(f.is_useful(space, Vector3(6, 0, -12.6), eye), "behind a tall wall: can't peek")
	var points: Array[Vector3] = [Vector3(-6, 0, -12.6), Vector3(0, 0, -12.6), Vector3(6, 0, -12.6)]
	assert_eq(f.best(space, points, Vector3(0, 0, -20), eye), Vector3(0, 0, -12.6), "the only useful point")
	var taken: Array[Vector3] = [Vector3(0, 0, -12.6)]
	assert_eq(f.best(space, points, Vector3(0, 0, -20), eye, taken), null, "occupied points are skipped")


func test_r57_flank_score_prefers_a_new_angle() -> void:
	var f := CoverFinder.new()
	var player := Vector3.ZERO
	var old := Vector3(0, 0, -12)
	var same_side := Vector3(1, 0, -12)
	var side := Vector3(-10, 0, -7)
	assert_gt(f.score(side, old, player, old), f.score(same_side, old, player, old), "a flank point off to the side scores higher")
