extends GutTest
## R61 — group movement. Slots: the count, the spacing, the first row in front, centred on the target. Assignment:
## every slot once, near the optimum (brute force on small groups), no crossing for a line shifted sideways. The magic
## box: a compact group keeps its shape toward a target outside it; a target inside it, or a scattered group, gathers
## into slots. Arrival: at the slot, or near it beside an arrived neighbour. Speed matching.


func _line(n: int, at: Vector3, step: Vector3) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in n:
		out.append(at + step * i)
	return out


func test_r61_slots_are_a_facing_grid() -> void:
	var s := RtsGroupMove.slots(Vector3(10, 0, 10), 9, 2.0, Vector3(0, 0, -1))
	assert_eq(s.size(), 9)
	assert_almost_eq(RtsGroupMove.centroid(s).distance_to(Vector3(10, 0, 10)), 0.0, 0.001, "centred on the target")
	var nearest := INF
	for i in s.size():
		for j in range(i + 1, s.size()):
			nearest = minf(nearest, s[i].distance_to(s[j]))
	assert_almost_eq(nearest, 2.0, 0.001, "spacing apart")
	assert_lt(s[0].z, s[8].z, "the first row is in front (facing −Z)")
	assert_eq(RtsGroupMove.slots(Vector3.ZERO, 7, 1.0, Vector3.RIGHT).size(), 7, "an uneven count")


func _total(positions: Array[Vector3], slot_points: Array[Vector3], pick: Array[int]) -> float:
	var t := 0.0
	for i in positions.size():
		t += positions[i].distance_to(slot_points[pick[i]])
	return t


func _best_total(positions: Array[Vector3], slot_points: Array[Vector3]) -> float:
	var best := INF
	for perm in _perms(range(slot_points.size())):
		var t := 0.0
		for i in positions.size():
			t += positions[i].distance_to(slot_points[perm[i]])
		best = minf(best, t)
	return best


func _perms(items: Array) -> Array:
	if items.size() <= 1:
		return [items]
	var out: Array = []
	for i in items.size():
		var rest := items.duplicate()
		var head = rest.pop_at(i)
		for p in _perms(rest):
			out.append([head] + p)
	return out


func test_r61_assignment_uses_every_slot_near_the_optimum() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for trial in 20:
		var pos: Array[Vector3] = []
		for i in 6:
			pos.append(Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10)))
		var s := RtsGroupMove.slots(Vector3(rng.randf_range(20, 30), 0, 0), 6, 2.0, Vector3.RIGHT)
		var pick := RtsGroupMove.assign(pos, s)
		var seen := {}
		for j in pick:
			seen[j] = true
		assert_eq(seen.size(), 6, "every slot once")
		assert_lt(_total(pos, s, pick), _best_total(pos, s) * 1.15, "within 15%% of the best (trial %d)" % trial)


func test_r61_a_line_moved_sideways_does_not_cross() -> void:
	var pos := _line(5, Vector3(0, 0, 0), Vector3(2, 0, 0))
	var s := _line(5, Vector3(0, 0, 10), Vector3(2, 0, 0))
	var pick := RtsGroupMove.assign(pos, s)
	for i in 5:
		assert_eq(pick[i], i, "each walks straight ahead")


func test_r61_the_list_order_does_not_decide() -> void:
	var pos := _line(5, Vector3(0, 0, 0), Vector3(2, 0, 0))
	var s := _line(5, Vector3(8, 0, 1), Vector3(-2, 0, 0))      # the same line a step ahead, listed right to left
	var pick := RtsGroupMove.assign(pos, s)
	for i in 5:
		assert_eq(pick[i], 4 - i, "each takes the slot in front of it, not the one with its index")


func test_r61_the_magic_box() -> void:
	var group := _line(4, Vector3(0, 0, 0), Vector3(1.5, 0, 0))
	var far := RtsGroupMove.targets(group, Vector3(30, 0, 20), 1.5)
	for i in 4:
		assert_almost_eq((far[i] - group[i]).distance_to(far[0] - group[0]), 0.0, 0.001, "the shape moves as it is")
	var inside := RtsGroupMove.targets(group, Vector3(2, 0, 0), 1.5)
	var d := {}
	for t in inside:
		d[t] = true
	assert_eq(d.size(), 4, "a target inside the box: they gather into slots")
	assert_lt(RtsGroupMove.centroid(inside).distance_to(Vector3(2, 0, 0)), 0.01)
	var scattered: Array[Vector3] = [Vector3(0, 0, 0), Vector3(40, 0, 0), Vector3(0, 0, 40)]
	var gathered := RtsGroupMove.targets(scattered, Vector3(100, 0, 100), 1.5)
	assert_lt(RtsGroupMove.centroid(gathered).distance_to(Vector3(100, 0, 100)), 0.01, "a scattered group gathers")
	assert_eq(RtsGroupMove.targets([Vector3.ZERO] as Array[Vector3], Vector3(5, 0, 5), 1.5), [Vector3(5, 0, 5)] as Array[Vector3], "one unit: the point")


func test_r61_arrival_and_the_crowd_rule() -> void:
	var none: Array[Vector3] = []
	assert_true(RtsGroupMove.arrived(Vector3(0.3, 0, 0), Vector3.ZERO, 0.5, none))
	assert_false(RtsGroupMove.arrived(Vector3(1.2, 0, 0), Vector3.ZERO, 0.5, none), "near, alone: keep going")
	var stopped: Array[Vector3] = [Vector3(2.0, 0, 0)]
	assert_true(RtsGroupMove.arrived(Vector3(1.2, 0, 0), Vector3.ZERO, 0.5, stopped), "near, touching a stopped one: stop")
	assert_false(RtsGroupMove.arrived(Vector3(4.0, 0, 0), Vector3.ZERO, 0.5, [Vector3(4.5, 0, 0)] as Array[Vector3]), "too far from the slot")


func test_r61_group_speed() -> void:
	assert_almost_eq(RtsGroupMove.group_speed([3.0, 2.2, 4.5] as Array[float]), 2.2, 0.0001)
	assert_almost_eq(RtsGroupMove.group_speed([] as Array[float]), 0.0, 0.0001)
