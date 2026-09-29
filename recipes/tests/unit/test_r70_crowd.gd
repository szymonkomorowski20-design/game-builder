extends GutTest
## Recipe 70 — the crowd: lanes merged at crossings and walked without doubling back (deterministic by seed); moods that
## only get worse, four reaction phases and a cooldown; steering that slows down instead of turning sharply; update
## and animation bands by distance, spread over frames; blending into a group of two; slots that are reserved, then
## occupied, and a full bench.


func _cross() -> CrowdLanes:
	var a := PackedVector3Array([Vector3(-5, 0, 0), Vector3(0, 0, 0), Vector3(5, 0, 0)])
	var b := PackedVector3Array([Vector3(0, 0, -5), Vector3(0, 0, 0), Vector3(0, 0, 5)])
	var paths: Array[PackedVector3Array] = [a, b]
	return CrowdLanes.from_paths(paths)


func test_r70_lanes() -> void:
	var lanes := _cross()
	assert_eq(lanes.points.size(), 5, "two lanes crossing share their middle point")
	var centre := lanes.nearest(Vector3.ZERO)
	assert_eq(lanes.links[centre].size(), 4, "the crossing links all four ways")
	var west := lanes.nearest(Vector3(-5, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 30:
		assert_ne(lanes.next_from(centre, west, rng), west, "never straight back at a crossing")
	assert_eq(lanes.next_from(west, centre, rng), centre, "at a dead end: back the way it came")
	var walk := func(s: int) -> Array:
		var r := RandomNumberGenerator.new()
		r.seed = s
		var out := []
		var prev := west
		var cur := centre
		for i in 20:
			var nxt := lanes.next_from(cur, prev, r)
			out.append(nxt)
			prev = cur
			cur = nxt
		return out
	assert_eq(walk.call(3), walk.call(3), "the same seed walks the same way")


func test_r70_mood_phases() -> void:
	var m := CrowdMind.new()
	var here := Vector3(2, 0, 0)
	assert_true(m.stimulate(CrowdMind.Mood.ALERT, Vector3.ZERO, 0.0), "an alarm")
	assert_eq(m.phase, CrowdMind.Phase.REACT, "first a short look")
	assert_eq(m.speed_scale(), 0.0, "standing while reacting")
	m.tick(0.7, here)
	assert_eq(m.phase, CrowdMind.Phase.REPOSITION, "then move to a distance")
	assert_almost_eq((m.goal(here) as Vector3).length(), m.watch_distance, 1e-4, "to the watching distance")
	m.tick(1.0, Vector3(6, 0, 0))
	assert_eq(m.phase, CrowdMind.Phase.MAIN, "there: the main behaviour")
	assert_eq(m.speed_scale(), 0.0, "an alerted civilian stands and watches")
	m.tick(1.0 + 4.0, Vector3(6, 0, 0))
	assert_eq(m.phase, CrowdMind.Phase.CALM, "then calms down")
	m.tick(1.0 + 4.0 + 3.0, Vector3(6, 0, 0))
	assert_true(m.is_calm(), "and walks on")
	assert_false(m.stimulate(CrowdMind.Mood.ALERT, Vector3.ZERO, 9.0), "a small alarm right after is ignored")
	assert_true(m.stimulate(CrowdMind.Mood.SCARED, Vector3.ZERO, 9.0), "a real fright isn't")


func test_r70_moods_only_worsen() -> void:
	var m := CrowdMind.new()
	m.stimulate(CrowdMind.Mood.SCARED, Vector3.ZERO, 0.0)
	assert_false(m.stimulate(CrowdMind.Mood.ALERT, Vector3(9, 0, 9), 0.1), "a milder stimulus changes nothing")
	assert_eq(m.source, Vector3.ZERO, "not even the source")
	assert_true(m.stimulate(CrowdMind.Mood.PANIC, Vector3(1, 0, 0), 0.2), "a worse one does")
	m.tick(1.0, Vector3(3, 0, 0))
	var g: Vector3 = m.goal(Vector3(3, 0, 0))
	assert_almost_eq(g.distance_to(Vector3(1, 0, 0)), m.flee_distance, 1e-4, "panic runs to the flee distance")
	assert_gt(g.x, 3.0, "away from the source")
	assert_gt(m.speed_scale(), 2.0, "fast")


func test_r70_steer_slows_instead_of_turning() -> void:
	var straight := CrowdRules.steer(Vector3.FORWARD, Vector3.FORWARD, 1.4, 3.0, 0.1)
	assert_almost_eq(float(straight.speed), 1.4, 1e-5, "straight on: full speed")
	var side := CrowdRules.steer(Vector3.FORWARD, Vector3.RIGHT, 1.4, 3.0, 0.1)
	assert_lt(float(side.speed), 0.2, "a right angle: nearly a stop first")
	var back := CrowdRules.steer(Vector3.FORWARD, Vector3.BACK, 1.4, 3.0, 0.1)
	assert_almost_eq(float(back.speed), 0.0, 1e-6, "turning round: stop and turn")
	var h: Vector3 = Vector3.FORWARD
	var speed := 0.0
	for i in 20:
		var s := CrowdRules.steer(h, Vector3.RIGHT, 1.4, 3.0, 0.1)
		h = s.heading
		speed = s.speed
	assert_almost_eq(h.angle_to(Vector3.RIGHT), 0.0, 1e-3, "the turn completes")
	assert_almost_eq(speed, 1.4, 1e-3, "and the speed comes back")


func test_r70_lod_bands() -> void:
	assert_eq(CrowdRules.lod_interval(5.0), 1, "near: every frame")
	assert_eq(CrowdRules.lod_interval(20.0), 3, "mid: every third frame")
	assert_eq(CrowdRules.lod_interval(60.0), 10, "far: every tenth")
	for id in 6:
		var due := 0
		for frame in 3:
			if CrowdRules.lod_due(frame, id, 20.0):
				due += 1
		assert_eq(due, 1, "each mid-band agent once in three frames (id %d)" % id)
	assert_ne(CrowdRules.lod_due(0, 0, 20.0), CrowdRules.lod_due(0, 1, 20.0), "neighbours on different frames")
	assert_true(CrowdRules.lod_animate(29.0), "animated within 30 m")
	assert_false(CrowdRules.lod_animate(31.0), "not beyond")


func test_r70_blended() -> void:
	var two: Array[Vector3] = [Vector3(1, 0, 0), Vector3(-1, 0, 0.5)]
	var one: Array[Vector3] = [Vector3(1, 0, 0)]
	var far: Array[Vector3] = [Vector3(2.5, 0, 0), Vector3(-2.5, 0, 0)]
	assert_true(CrowdRules.blended(Vector3.ZERO, 2.0, two), "walking between two calm civilians: blended")
	assert_false(CrowdRules.blended(Vector3.ZERO, 2.0, one), "one isn't a crowd")
	assert_false(CrowdRules.blended(Vector3.ZERO, 6.5, two), "sprinting through a group doesn't hide anyone")
	assert_false(CrowdRules.blended(Vector3.ZERO, 2.0, far), "2.5 m away is not with them")


func test_r70_slots() -> void:
	var bench := SmartSlots.new([Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0)] as Array[Vector3])
	var a := RefCounted.new()
	var b := RefCounted.new()
	var c := RefCounted.new()
	assert_eq(bench.reserve(a, Vector3(-3, 0, 0)), 0, "the nearest free seat")
	assert_eq(bench.reserve(b, Vector3(-3, 0, 0)), 1, "a reserved seat isn't given away")
	assert_eq(bench.reserve(c), -1, "no seat left")
	assert_eq(bench.reserve(a), 0, "asking again: the same seat")
	assert_false(bench.full(), "reserved is not yet occupied")
	bench.occupy(a)
	bench.occupy(b)
	assert_true(bench.full(), "two sitting: a hiding place for a third")
	bench.release(a)
	assert_false(bench.full(), "one left")
	assert_eq(bench.reserve(c), 0, "and the seat is free again")
