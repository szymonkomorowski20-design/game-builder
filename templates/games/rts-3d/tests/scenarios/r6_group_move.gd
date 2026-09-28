extends GbScenario
## R6 — a group crosses the map (recipes 61, 58 in the game): twelve footmen, box-selected and right-clicked at the far
## side, walk around the rocks and all arrive — no one left stuck on the way, nobody standing on anybody (the magic box
## keeps their spacing); a second right click inside the group gathers it.


func run() -> void:
	await load_scene("res://tests/fixtures/sandbox.tscn")
	var g := get_tree().current_scene as RtsGame
	var hands := RtsHands.new(self, g)
	await wait_frames(10)
	var start := g.bases[0] + Vector3(6, 0, -8)
	var group: Array = []
	for i in 12:
		group.append(g.spawn_unit(0, &"footman", start + Vector3((i % 4) * 1.4, 0, (i / 4) * 1.4)))
	await wait_frames(5)
	await hands.box_select(group)
	expect_eq(hands.input.selection.selected.size(), 12, "R6 twelve selected")
	var before := _offsets(group)
	var goal := Vector3(12, 0, -8)
	hands.input.rig.jump_to(goal)
	await wait_frames(3)
	await hands.right_click(hands.screen(goal))
	# The magic box: each unit is sent to its own slot, keeping its offset in the group.
	var slots := {}
	var shape_kept := true
	var sent_c := Vector3.ZERO
	for u: RtsUnit in group:
		slots[u] = u.orders.current().at
		sent_c += slots[u] / group.size()
	for i in group.size():
		var s: Vector3 = slots[group[i]] - sent_c
		shape_kept = shape_kept and Vector2(s.x, s.z).distance_to(before[i]) < 0.3
	expect(shape_kept, "R6 each unit is sent to its own slot, the group's shape kept (the magic box)")
	var arrived := await wait_until(func() -> bool: return group.all(func(u: RtsUnit) -> bool: return u.orders.idle()), 45.0)
	expect(arrived, "R6 every unit arrives (none stuck on the way)")
	var far := 0.0
	for u: RtsUnit in group:
		far = maxf(far, u.global_position.distance_to(goal))
	for u: RtsUnit in group:
		note("%s at %s dist %.1f state %s" % [u.name, u.global_position, u.global_position.distance_to(goal), u.state_name()])
	expect_lt(far, 8.0, "R6 … near the goal (the farthest %.1f m)" % far)
	var closest := INF
	for i in group.size():
		for j in range(i + 1, group.size()):
			closest = minf(closest, (group[i] as RtsUnit).global_position.distance_to((group[j] as RtsUnit).global_position))
	expect_gt(closest, 0.6, "R6 nobody stands on anybody (closest pair %.2f m)" % closest)
	var on_slot := group.filter(func(u: RtsUnit) -> bool: return Vector2(u.global_position.x - slots[u].x, u.global_position.z - slots[u].z).length() < 2.0).size()
	expect_gt(on_slot, 8, "R6 … and most stand on it at the end (%d of 12 within 2 m)" % on_slot)
	await shot("r6_group")


## Each unit's flat offset from the group's centre.
func _offsets(group: Array) -> Array[Vector2]:
	var c := Vector2.ZERO
	for u: RtsUnit in group:
		c += Vector2(u.global_position.x, u.global_position.z)
	c /= group.size()
	var out: Array[Vector2] = []
	for u: RtsUnit in group:
		out.append(Vector2(u.global_position.x, u.global_position.z) - c)
	return out

