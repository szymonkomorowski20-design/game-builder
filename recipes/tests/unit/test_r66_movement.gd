extends GutTest
## Recipe 66 — stealth movement: the profile picked from the held intents, speeds and noise, the landing noise, the fall
## rule's heights (and soft landings), the edge guard's decisions, and the drop probe on real physics boxes.


func test_r66_profile_from_intents() -> void:
	var p := MoveProfiles.new()
	assert_eq(p.pick(0.0, false, false), MoveProfiles.WALK, "no input: walk (makes no steps, so no noise)")
	assert_eq(p.pick(0.3, false, false), MoveProfiles.WALK, "a half-pushed stick walks")
	assert_eq(p.pick(1.0, false, false), MoveProfiles.RUN, "a full push runs")
	assert_eq(p.pick(1.0, true, false), MoveProfiles.SPRINT, "sprint held while moving")
	assert_eq(p.pick(0.0, true, false), MoveProfiles.WALK, "sprint needs movement")
	assert_eq(p.pick(1.0, false, true), MoveProfiles.SNEAK, "sneak held")
	assert_eq(p.pick(1.0, true, true), MoveProfiles.SPRINT, "sprint wins over sneak: the player asked to be fast")


func test_r66_speed_noise_profile() -> void:
	var p := MoveProfiles.new()
	assert_gt(p.speed(MoveProfiles.SPRINT), p.speed(MoveProfiles.RUN), "sprint is faster than a run")
	assert_gt(p.speed(MoveProfiles.RUN), p.speed(MoveProfiles.WALK), "a run is faster than a walk")
	assert_gt(p.speed(MoveProfiles.WALK), p.speed(MoveProfiles.SNEAK), "a walk is faster than sneaking")
	assert_eq(p.noise(MoveProfiles.SNEAK), 0.0, "sneaking is silent")
	assert_gt(p.noise(MoveProfiles.SPRINT), p.noise(MoveProfiles.RUN), "sprinting is louder than running")
	assert_true(p.is_high_profile(MoveProfiles.SPRINT), "sprint is high profile")
	assert_false(p.is_high_profile(MoveProfiles.RUN), "a run is not")
	assert_eq(p.landing_noise(0.3), 0.0, "a hop is silent")
	assert_almost_eq(p.landing_noise(3.0), 6.0, 1e-5, "3 m: 2 m of radius per m fallen")
	assert_almost_eq(p.landing_noise(20.0), p.landing_noise_max, 1e-5, "capped")


func test_r66_fall_rule_heights() -> void:
	var f := FallRule.new()
	assert_eq(int(f.outcome(3.0, false).kind), FallRule.Kind.NONE, "below the safe height: nothing")
	assert_eq(int(f.outcome(4.5, false).kind), FallRule.Kind.NONE, "the safe height itself: nothing")
	var mid := f.outcome((f.safe_height + f.deadly_height) * 0.5, false)
	assert_eq(int(mid.kind), FallRule.Kind.HURT, "between: hurt")
	assert_almost_eq(float(mid.damage), 0.5, 1e-5, "halfway: half of full health")
	assert_eq(int(f.outcome(14.0, false).kind), FallRule.Kind.DEAD, "the deadly height: death")
	assert_eq(int(f.outcome(20.0, true).kind), FallRule.Kind.NONE, "hay takes a 20 m fall")
	assert_eq(int(f.outcome(50.0, true).kind), FallRule.Kind.DEAD, "above the soft maximum even hay can't help")
	f.deadly_height = INF
	assert_eq(int(f.outcome(100.0, false).kind), FallRule.Kind.HURT, "no death from falling when deadly_height is INF")


func test_r66_edge_decisions() -> void:
	assert_eq(EdgeGuard.decide(0.3, 0.6, false, false, false, true), EdgeGuard.GO, "a small step down: go on")
	assert_eq(EdgeGuard.decide(INF, 0.6, false, false, false, true), EdgeGuard.STOP, "an edge without intent: stop")
	assert_eq(EdgeGuard.decide(INF, 0.6, true, false, false, true), EdgeGuard.JUMP, "jump pressed: jump")
	assert_eq(EdgeGuard.decide(INF, 0.6, false, true, false, true), EdgeGuard.DROP, "drop pressed: walk off")
	assert_eq(EdgeGuard.decide(INF, 0.6, false, false, true, true), EdgeGuard.JUMP, "sprinting leaps")
	assert_eq(EdgeGuard.decide(INF, 0.6, false, false, true, false), EdgeGuard.STOP, "unless the leap is switched off")


func test_r66_drop_probe_on_boxes() -> void:
	var roof := GreyboxBlock.make(Vector3(0, 2.5, 0), Vector3(6, 5, 10), Color.GRAY)
	add_child_autofree(roof)
	var ground := GreyboxBlock.make(Vector3(0, -0.5, 0), Vector3(40, 1, 40), Color.DIM_GRAY)
	add_child_autofree(ground)
	await wait_physics_frames(2)
	var space := get_tree().root.get_world_3d().direct_space_state
	var fwd := Vector3(0, 0, -1)
	assert_almost_eq(EdgeGuard.probe_drop(space, Vector3(0, 5, 0), fwd, 0.45, 0.65, 1), 0.0, 0.01, "mid-roof: flat")
	assert_eq(EdgeGuard.probe_drop(space, Vector3(0, 5, -4.8), fwd, 0.45, 0.65, 1), INF, "at the edge: nothing within the step")
	assert_almost_eq(EdgeGuard.probe_drop(space, Vector3(0, 5, -4.8), fwd, 0.45, 10.0, 1), 5.0, 0.01, "a longer probe finds the street 5 m down")
	assert_almost_eq(EdgeGuard.probe_drop(space, Vector3(0, 5, 0), Vector3.ZERO, 0.45, 0.65, 1), 0.0, 1e-6, "standing still: no edge")
	var excluded: Array[RID] = [roof.get_rid()]
	assert_almost_eq(EdgeGuard.probe_drop(space, Vector3(0, 5, 0), fwd, 0.45, 10.0, 1, excluded), 5.0, 0.01, "excluded bodies are not floor")
