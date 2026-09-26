class_name DungeonGen
extends RefCounted
## Seeded rooms-and-corridors generator: random non-overlapping rooms, each connected to the previous one by an
## L-shaped corridor. Same seed → same dungeon (share seeds, reproduce bugs). Output feeds AsciiLevel (recipe 27).

const WALL := 0
const FLOOR := 1


## Returns {"w", "h", "cells": PackedByteArray (w*h), "rooms": Array[Rect2i]}
static func generate(seed_value: int, w: int = 48, h: int = 32, attempts: int = 40, min_room: int = 4, max_room: int = 9) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cells := PackedByteArray()
	cells.resize(w * h)
	cells.fill(WALL)
	var rooms: Array[Rect2i] = []
	for i in attempts:
		var size := Vector2i(rng.randi_range(min_room, max_room), rng.randi_range(min_room, max_room))
		var pos := Vector2i(rng.randi_range(1, w - size.x - 1), rng.randi_range(1, h - size.y - 1))
		var room := Rect2i(pos, size)
		var overlaps := false
		for other in rooms:
			if room.grow(1).intersects(other):
				overlaps = true
				break
		if overlaps:
			continue
		_carve_rect(cells, w, room)
		if not rooms.is_empty():
			_carve_corridor(cells, w, _center(rooms[-1]), _center(room), rng.randf() < 0.5)
		rooms.append(room)
	return {"w": w, "h": h, "cells": cells, "rooms": rooms}


static func _center(r: Rect2i) -> Vector2i:
	return r.position + r.size / 2


static func _carve_rect(cells: PackedByteArray, w: int, r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			cells[y * w + x] = FLOOR


static func _carve_corridor(cells: PackedByteArray, w: int, a: Vector2i, b: Vector2i, horizontal_first: bool) -> void:
	var corner := Vector2i(b.x, a.y) if horizontal_first else Vector2i(a.x, b.y)
	for seg in [[a, corner], [corner, b]]:
		var from: Vector2i = seg[0]
		var to: Vector2i = seg[1]
		for y in range(mini(from.y, to.y), maxi(from.y, to.y) + 1):
			for x in range(mini(from.x, to.x), maxi(from.x, to.x) + 1):
				cells[y * w + x] = FLOOR


static func to_rows(d: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	for y in int(d.h):
		var line := ""
		for x in int(d.w):
			line += "." if d.cells[y * int(d.w) + x] == FLOOR else "#"
		rows.append(line)
	return rows
