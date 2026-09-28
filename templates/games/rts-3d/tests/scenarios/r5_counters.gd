extends GbScenario
## R5 — the counter triangle in the engine (recipe 63 in the game), not just in the damage table: equal-cost groups
## meet in the open middle of the map with attack-move, and the counter wins every time — archers beat footmen, riders
## beat archers, footmen beat riders. Also: a group of footmen destroys a farm (buildings can be destroyed).

const SPOT := Vector3(0, 0, 18)


func _fight(g: RtsGame, a_kind: StringName, a_n: int, b_kind: StringName, b_n: int) -> int:
	var a: Array[RtsUnit] = []
	var b: Array[RtsUnit] = []
	for i in a_n:
		a.append(g.spawn_unit(0, a_kind, SPOT + Vector3(-7, 0, -1.5 + i * 1.2)))
	for i in b_n:
		b.append(g.spawn_unit(1, b_kind, SPOT + Vector3(7, 0, -1.5 + i * 1.2)))
	await wait_frames(3)
	for u in a:
		u.orders.give(RtsOrders.make(RtsOrders.Kind.ATTACK_MOVE, SPOT + Vector3(9, 0, 0)))
	for u in b:
		u.orders.give(RtsOrders.make(RtsOrders.Kind.ATTACK_MOVE, SPOT + Vector3(-9, 0, 0)))
	var alive := func(list: Array[RtsUnit]) -> int:
		var n := 0
		for i in list.size():
			var u = list[i]                      # a Variant: the dead are freed
			if is_instance_valid(u) and u.alive:
				n += 1
		return n
	await wait_until(func() -> bool: return alive.call(a) == 0 or alive.call(b) == 0, 60.0)
	var left_a: int = alive.call(a)
	var left_b: int = alive.call(b)
	note("%d %s vs %d %s: %d vs %d left" % [a_n, a_kind, b_n, b_kind, left_a, left_b])
	var everyone: Array = []
	everyone.append_array(a)
	everyone.append_array(b)
	for i in everyone.size():
		var u = everyone[i]
		if is_instance_valid(u) and u.alive:
			u.take_damage(1e6, null)
	await wait_frames(3)
	if left_a > 0 and left_b == 0:
		return 0
	return 1 if left_b > 0 and left_a == 0 else -1           # −1: nobody won (both alive after a minute, or both dead)


func run() -> void:
	await load_scene("res://tests/fixtures/sandbox.tscn")
	var g := get_tree().current_scene as RtsGame
	await wait_frames(10)
	# Equal cost: 4 archers (400) against 4 footmen (360) and so on.
	expect_eq(await _fight(g, &"archer", 4, &"footman", 4), 0, "R5 archers beat footmen")
	expect_eq(await _fight(g, &"rider", 3, &"archer", 4), 0, "R5 riders beat archers")
	expect_eq(await _fight(g, &"footman", 4, &"rider", 3), 0, "R5 footmen beat riders")
	# A building can be destroyed.
	var farm := g.place_building(1, &"farm", g.grid.footprint_at(SPOT, Vector2i(2, 2)), true)
	for i in 5:
		var f := g.spawn_unit(0, &"footman", SPOT + Vector3(-5, 0, -2 + i))
		f.orders.give(RtsOrders.make(RtsOrders.Kind.ATTACK, farm.global_position, farm))
	var held: Array = [farm]                     # a lambda capturing the freed farm itself errors; hold it in an array
	var down := await wait_until(func() -> bool: return not is_instance_valid(held[0]), 60.0)
	expect(down, "R5 five footmen destroy a farm within a minute")
