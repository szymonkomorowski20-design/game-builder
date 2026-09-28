extends GutTest
## Contracts of the military-fps-3d template: the numbers that keep the fight readable and fair. A tuning change
## that breaks one of these changed the game's character — decide it in the spec, then update the contract.

const RIFLE := preload("res://data/rifle.tres")
const PISTOL := preload("res://data/pistol.tres")
const SOLDIER := preload("res://data/soldier.tres")
const PLAYER := preload("res://data/player_tuning.tres")


func _hits_to_kill(gun: GunStats, distance: float, zone: StringName) -> int:
	var g := GunModel.new(gun)
	return ceili(SOLDIER.max_health / g.damage_at(distance, zone))


func test_time_to_kill_bands() -> void:
	assert_eq(_hits_to_kill(RIFLE, 10.0, &"body"), 3, "rifle: 3 body hits up close (genre doc: CoD4-era rifle)")
	assert_eq(_hits_to_kill(RIFLE, 10.0, &"head"), 2, "rifle: 2 to the head")
	assert_eq(_hits_to_kill(RIFLE, 45.0, &"body"), 4, "rifle: 4 body hits at long range (falloff)")
	assert_between(_hits_to_kill(PISTOL, 8.0, &"body"), 3, 4, "pistol: 3–4 body hits up close")
	assert_eq(_hits_to_kill(PISTOL, 8.0, &"head"), 2, "pistol: 2 to the head")
	var ttk := (3 - 1) * RIFLE.shot_interval()
	assert_between(ttk, 0.1, 0.3, "rifle TTK up close %.2f s" % ttk)


## Expected damage per second of one soldier peeking at full aim (the bursts' cadence × accuracy × damage).
func _soldier_dps(accuracy: float) -> float:
	var burst := (SOLDIER.burst_min + SOLDIER.burst_max) * 0.5
	var cycle := burst * 60.0 / SOLDIER.rpm + SOLDIER.burst_pause
	return burst / cycle * accuracy * SOLDIER.damage


## Seconds for `shooters` soldiers who all start peeking at once to kill a full-health, standing player (expected
## value, with the accuracy ramp from accuracy_min), ignoring cover — the worst honest case.
func _seconds_to_kill_player(shooters: int, difficulty: float) -> float:
	var hp := PLAYER.max_health
	var t := 0.0
	var dt := 1.0 / 60.0
	while hp > 0.0 and t < 60.0:
		var acc := lerpf(SOLDIER.accuracy_min, SOLDIER.accuracy_max, clampf(t / SOLDIER.aim_time, 0.0, 1.0)) * difficulty
		hp -= _soldier_dps(acc) * shooters * dt
		t += dt
	return t


func test_two_soldiers_need_seconds_to_kill_a_player_in_the_open() -> void:
	var two := _seconds_to_kill_player(2, 1.0)
	assert_gt(two, 3.5, "two peeking soldiers (the token limit) need > 3.5 s to kill a standing player at normal difficulty (%.1f s)" % two)
	var three := _seconds_to_kill_player(3, 1.0)
	assert_lt(three, two, "a third shooter would make it deadlier — that is what the token limit prevents")
	assert_gt(_seconds_to_kill_player(2, 1.3), 2.5, "even on hard (× 1.3) two need > 2.5 s")


func test_bursts_leave_gaps_to_peek_back() -> void:
	assert_gt(SOLDIER.burst_pause, 0.3, "a pause between bursts")
	assert_gt(SOLDIER.peek_wait, 1.0, "a soldier stays down > 1 s between peeks")
	assert_lt(SOLDIER.accuracy_min, 0.2, "the first shots of a peek mostly miss")
	assert_lt(PLAYER.regen_delay, 6.0, "health comes back within a few seconds in cover")


func test_difficulty_scales_accuracy_not_timing() -> void:
	var b := ShooterBrain.new()
	b.accuracy_min = SOLDIER.accuracy_min
	b.accuracy_max = SOLDIER.accuracy_max
	var wait_before := b.peek_wait
	assert_almost_eq(b.accuracy(0.7), b.accuracy(1.0) * 0.7, 1e-6, "easy lowers accuracy")
	assert_eq(b.peek_wait, wait_before, "and changes no timing")


func test_every_bark_has_a_subtitle() -> void:
	for kind in [&"contact", &"reloading", &"flanking", &"suppressed", &"man_down"]:
		assert_true(MilHud.BARKS.has(kind), "bark %s has a Polish subtitle" % kind)


func _wall(at: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	b.add_child(c)
	add_child_autofree(b)
	b.global_position = at


func test_spawns_are_out_of_sight_ahead_and_not_too_close() -> void:
	# Player at the origin looking toward −Z; a wall 15 m ahead hides what is behind it.
	_wall(Vector3(0, 1.5, -15), Vector3(8, 3, 0.5))
	await wait_physics_frames(2)
	var space := get_tree().root.get_world_3d().direct_space_state
	var eye := Vector3(0, 1.6, 0)
	var ahead := Vector3(0, 0, -1)
	var picker := SpawnPicker.new()
	var hidden := Vector3(0, 0, -18)
	var visible := Vector3(12, 0, -18)
	var too_close := Vector3(0, 0, -8)
	var behind := Vector3(0, 0, 16)
	assert_true(picker.is_fair(space, hidden, eye, ahead), "behind the wall, 18 m ahead: fair")
	assert_false(picker.is_fair(space, visible, eye, ahead), "in plain view: unfair")
	assert_false(picker.is_fair(space, too_close, eye, ahead), "8 m away: unfair")
	assert_false(picker.is_fair(space, behind, eye, ahead), "behind the player: unfair")
	var points: Array[Vector3] = [visible, hidden, too_close, behind]
	var one := picker.pick(space, points, eye, ahead, 1)
	assert_eq(one, [hidden] as Array[Vector3], "one soldier: the fair point")
	assert_eq(picker.last_unfair, 0)
	var two := picker.pick(space, points, eye, ahead, 2)
	assert_eq(two.size(), 2)
	assert_eq(picker.last_unfair, 1, "two soldiers but one fair point: the second is counted as unfair")
