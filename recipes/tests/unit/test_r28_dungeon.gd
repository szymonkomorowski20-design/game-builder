extends GutTest
## R28 — determinism per seed, every floor cell reachable from the first room (over many seeds),
## rooms never overlap, the border is solid wall. Generators are tested as properties over many seeds.


func _flood_count(d: Dictionary, start: Vector2i) -> int:
	var w: int = d.w
	var seen := {}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		if seen.has(c) or c.x < 0 or c.y < 0 or c.x >= w or c.y >= int(d.h):
			continue
		if d.cells[c.y * w + c.x] != DungeonGen.FLOOR:
			continue
		seen[c] = true
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			stack.append(c + dir)
	return seen.size()


func test_r28_same_seed_same_dungeon() -> void:
	assert_eq(DungeonGen.generate(42).cells, DungeonGen.generate(42).cells)
	assert_ne(DungeonGen.generate(42).cells, DungeonGen.generate(43).cells)


func test_r28_all_floor_connected_over_many_seeds() -> void:
	for s in 50:
		var d := DungeonGen.generate(s)
		var floor_total: int = (d.cells as PackedByteArray).count(DungeonGen.FLOOR)
		var start: Vector2i = (d.rooms[0] as Rect2i).position
		assert_eq(_flood_count(d, start), floor_total, "seed %d: unreachable floor" % s)


func test_r28_rooms_do_not_overlap_and_border_is_wall() -> void:
	for s in 50:
		var d := DungeonGen.generate(s)
		assert_gt(d.rooms.size(), 2, "seed %d produced a usable number of rooms" % s)
		for i in d.rooms.size():
			for j in range(i + 1, d.rooms.size()):
				assert_false((d.rooms[i] as Rect2i).intersects(d.rooms[j]), "seed %d rooms %d/%d overlap" % [s, i, j])
		var rows := DungeonGen.to_rows(d)
		assert_false(rows[0].contains(".") or rows[-1].contains("."), "seed %d open top/bottom border" % s)
		for r in rows:
			assert_true(r[0] == "#" and r[-1] == "#", "seed %d open side border" % s)


func test_r28_output_builds_a_tilemap() -> void:
	var layer := AsciiLevel.build(DungeonGen.to_rows(DungeonGen.generate(7)))
	add_child_autofree(layer)
	assert_eq(layer.get_used_rect().size, Vector2i(48, 32))
