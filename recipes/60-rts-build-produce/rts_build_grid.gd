class_name RtsBuildGrid
extends RefCounted
## Building placement on a grid (recipe 60). A building covers `size` cells (a footprint); it fits where every cell is
## inside the map, free, not blocked (cliffs, water, resources, a no-build ring around a mine) and explored — the ghost
## turns red otherwise. World positions snap to the footprint's centre, so a 2×2 and a 3×3 building both line up.

var cell_size := 2.0
var origin := Vector3.ZERO                ## the world position of cell (0, 0)'s corner
var width := 64
var height := 64
var occupied := {}                        ## Vector2i → building id
var blocked := {}                         ## Vector2i → true (terrain, resources)
var explored: Callable                    ## (cell: Vector2i) -> bool; unset: everything counts as explored


func cell_of(world: Vector3) -> Vector2i:
	return Vector2i(floori((world.x - origin.x) / cell_size), floori((world.z - origin.z) / cell_size))


## The footprint's top-left cell for a building of `size` centred as near to `world` as the grid allows.
func footprint_at(world: Vector3, size: Vector2i) -> Vector2i:
	var fx := (world.x - origin.x) / cell_size - size.x * 0.5
	var fz := (world.z - origin.z) / cell_size - size.y * 0.5
	return Vector2i(roundi(fx), roundi(fz))


## The world centre of a footprint (where the building's node goes).
func centre(cell: Vector2i, size: Vector2i) -> Vector3:
	return origin + Vector3((cell.x + size.x * 0.5) * cell_size, 0.0, (cell.y + size.y * 0.5) * cell_size)


func cells(cell: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			out.append(cell + Vector2i(x, y))
	return out


## Why a footprint cannot take a building ("" when it can): "outside", "occupied", "blocked", "unexplored".
func why_not(cell: Vector2i, size: Vector2i) -> String:
	for c in cells(cell, size):
		if c.x < 0 or c.y < 0 or c.x >= width or c.y >= height:
			return "outside"
		if occupied.has(c):
			return "occupied"
		if blocked.has(c):
			return "blocked"
		if explored.is_valid() and not bool(explored.call(c)):
			return "unexplored"
	return ""


func can_place(cell: Vector2i, size: Vector2i) -> bool:
	return why_not(cell, size) == ""


## Takes the cells for building `id`. False (and nothing taken) when it doesn't fit.
func place(cell: Vector2i, size: Vector2i, id: int) -> bool:
	if not can_place(cell, size):
		return false
	for c in cells(cell, size):
		occupied[c] = id
	return true


## A building destroyed or cancelled: its cells are free again.
func remove(id: int) -> void:
	for c in occupied.keys():
		if occupied[c] == id:
			occupied.erase(c)


## Blocks a ring of `margin` cells around a footprint (the genre keeps town halls off their mines).
func block_around(cell: Vector2i, size: Vector2i, margin: int) -> void:
	for c in cells(cell - Vector2i(margin, margin), size + Vector2i(margin * 2, margin * 2)):
		blocked[c] = true
