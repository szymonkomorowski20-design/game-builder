extends GutTest
## R37 — completable levels pass; unreachable pickups, hazards blocking the exit and key/door soft-locks fail
## with the exact cells; every generated dungeon (recipe 28) is completable.


func _check(rows: Array) -> Dictionary:
	return LevelCheck.analyze(PackedStringArray(rows))


func test_r37_good_level() -> void:
	var r := _check([
		"#########",
		"#S..c...#",
		"#.###.#.#",
		"#...k.D.#",
		"#######E#",
	])
	assert_true(r.ok, str(r))
	assert_eq(r.path_length, 9)


func test_r37_pickup_behind_wall_is_reported() -> void:
	var r := _check([
		"########",
		"#S...E.#",
		"########",
		"#..c...#",
		"########",
	])
	assert_false(r.ok)
	assert_eq(r.unreachable_pickups, [Vector2i(3, 3)])
	assert_true(r.exit_reachable)


func test_r37_hazard_blocks_exit() -> void:
	var r := _check([
		"#######",
		"#S.~.E#",
		"#######",
	])
	assert_false(r.exit_reachable)
	assert_eq(r.path_length, -1)


func test_r37_key_behind_its_own_door_is_a_softlock() -> void:
	var r := _check([
		"#########",
		"#S..D.k.#",
		"#########",
		"#......E#",
	])
	assert_false(r.ok)
	assert_eq(r.softlocked_doors, [Vector2i(4, 1)])
	assert_true(r.unreachable_pickups.has(Vector2i(6, 1)))


func test_r37_every_generated_dungeon_is_completable() -> void:
	for s in 30:
		var d := DungeonGen.generate(s)
		var rows := DungeonGen.to_rows(d)
		var first: Rect2i = d.rooms[0]
		var last: Rect2i = d.rooms[-1]
		var a := first.position
		var b := last.end - Vector2i.ONE
		rows[a.y] = rows[a.y].substr(0, a.x) + "S" + rows[a.y].substr(a.x + 1)
		rows[b.y] = rows[b.y].substr(0, b.x) + "E" + rows[b.y].substr(b.x + 1)
		assert_true(LevelCheck.analyze(rows).ok, "seed %d" % s)


func test_r37_tilemap_layer_input() -> void:
	var layer := AsciiLevel.build(PackedStringArray(["#####", "#...#", "#####"]))
	add_child_autofree(layer)
	var rows := LevelCheck.rows_from_layer(layer, Vector2i(1, 1), Vector2i(3, 1))
	assert_eq(rows[1], "#S.E#")
	assert_true(LevelCheck.analyze(rows).ok)
