class_name LevelCheck
extends RefCounted
## Proves a level is completable before anyone plays it: exit and every pickup reachable from the start,
## no soft-lock with keys and doors, shortest path length for pacing. Works on text rows (hand-made or
## generated levels) and on a TileMapLayer (cells with collision are walls).
##   #  wall   ~ hazard (not walkable)   . floor   S start   E exit   c pickup   k key   D locked door

const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


## Returns {"ok", "exit_reachable", "unreachable_pickups": Array[Vector2i], "softlocked_doors": Array[Vector2i],
##          "path_length": int (-1 if no path), "dead_ends": int}
static func analyze(rows: PackedStringArray) -> Dictionary:
	var cells := {}
	var start := Vector2i(-1, -1)
	for y in rows.size():
		for x in rows[y].length():
			var c := rows[y][x]
			cells[Vector2i(x, y)] = c
			if c == "S":
				start = Vector2i(x, y)
	if start.x < 0:
		return {"ok": false, "error": "no start S", "exit_reachable": false, "unreachable_pickups": [], "softlocked_doors": [], "path_length": -1, "dead_ends": 0}

	# Keys open doors: explore with doors closed, spend one reachable key per adjacent door, repeat to a fixpoint.
	var open_doors := {}
	var keys_used := 0
	var region := {}
	while true:
		region = _flood(cells, start, open_doors)
		var keys := 0
		for p in region:
			if cells[p] == "k":
				keys += 1
		var opened := false
		for p in cells:
			if cells[p] == "D" and not open_doors.has(p) and keys > keys_used and _touches(region, p):
				open_doors[p] = true
				keys_used += 1
				opened = true
				break
		if not opened:
			break

	var unreachable: Array[Vector2i] = []
	var softlocked: Array[Vector2i] = []
	var exit := Vector2i(-1, -1)
	for p in cells:
		match cells[p]:
			"c", "k":
				if not region.has(p):
					unreachable.append(p)
			"D":
				if not open_doors.has(p):
					softlocked.append(p)
			"E":
				exit = p
	var exit_ok := exit.x >= 0 and region.has(exit)
	var dead_ends := 0
	for p in region:
		var n := 0
		for d in DIRS:
			if region.has(p + d):
				n += 1
		if n == 1 and cells[p] == ".":
			dead_ends += 1
	return {
		"ok": exit_ok and unreachable.is_empty() and softlocked.is_empty(),
		"exit_reachable": exit_ok, "unreachable_pickups": unreachable, "softlocked_doors": softlocked,
		"path_length": _distance(cells, start, exit, open_doors) if exit_ok else -1, "dead_ends": dead_ends,
	}


## TileMapLayer → rows: a cell with a collision polygon is "#", any other painted cell is ".", unpainted is "#".
static func rows_from_layer(layer: TileMapLayer, start: Vector2i, exit: Vector2i) -> PackedStringArray:
	var r := layer.get_used_rect()
	var rows := PackedStringArray()
	for y in range(r.position.y, r.end.y):
		var line := ""
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			var data := layer.get_cell_tile_data(c)
			var ch := "#" if data == null or data.get_collision_polygons_count(0) > 0 else "."
			if c == start:
				ch = "S"
			elif c == exit:
				ch = "E"
			line += ch
		rows.append(line)
	return rows


static func _walkable(cells: Dictionary, p: Vector2i, open_doors: Dictionary) -> bool:
	if not cells.has(p):
		return false
	var c: String = cells[p]
	return c != "#" and c != "~" and (c != "D" or open_doors.has(p))


static func _flood(cells: Dictionary, start: Vector2i, open_doors: Dictionary) -> Dictionary:
	var seen := {start: true}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in DIRS:
			var q: Vector2i = p + d
			if not seen.has(q) and _walkable(cells, q, open_doors):
				seen[q] = true
				stack.append(q)
	return seen


static func _touches(region: Dictionary, p: Vector2i) -> bool:
	for d in DIRS:
		if region.has(p + d):
			return true
	return false


static func _distance(cells: Dictionary, a: Vector2i, b: Vector2i, open_doors: Dictionary) -> int:
	var dist := {a: 0}
	var queue: Array[Vector2i] = [a]
	var i := 0
	while i < queue.size():
		var p: Vector2i = queue[i]
		i += 1
		if p == b:
			return dist[p]
		for d in DIRS:
			var q: Vector2i = p + d
			if not dist.has(q) and _walkable(cells, q, open_doors):
				dist[q] = dist[p] + 1
				queue.append(q)
	return -1
