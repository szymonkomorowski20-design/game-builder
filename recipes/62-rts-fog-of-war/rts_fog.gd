class_name RtsFog
extends RefCounted
## Fog of war on a grid (recipe 62), one per team. Each cell is UNEXPLORED (black), EXPLORED (seen once: terrain and
## buildings as last seen, no units) or VISIBLE (a unit or building of the team sees it now).
## `update(viewers)` recomputes what is visible from every viewer's circle of sight and adds it to what is explored —
## call it a few times a second, not every frame. Circles are stamped from precomputed offsets, so a hundred units cost
## tens of thousands of cheap writes. `to_image()` gives the overlay a shader samples (0 / 128 / 255).
## Sight here goes through everything; high ground and trees blocking sight are an extension (see the README).

enum { UNEXPLORED = 0, EXPLORED = 1, VISIBLE = 2 }

var cell_size := 1.0
var origin := Vector3.ZERO
var width := 128
var height := 128

var _explored := PackedByteArray()
var _visible := PackedByteArray()
var _circles := {}                  ## radius in cells → PackedInt32Array of (dx, dy) pairs


func _init(w: int = 128, h: int = 128, cell: float = 1.0, at: Vector3 = Vector3.ZERO) -> void:
	width = w
	height = h
	cell_size = cell
	origin = at
	_explored.resize(w * h)
	_visible.resize(w * h)


func cell_of(world: Vector3) -> Vector2i:
	return Vector2i(floori((world.x - origin.x) / cell_size), floori((world.z - origin.z) / cell_size))


## viewers: [{"at": Vector3, "sight": float (metres)}]. Visible = what they see now; explored keeps everything seen.
func update(viewers: Array) -> void:
	_visible.fill(0)
	for v in viewers:
		var c := cell_of(v.at)
		var r := maxi(roundi(float(v.sight) / cell_size), 0)
		var offs: PackedInt32Array = _circle(r)
		for k in range(0, offs.size(), 2):
			var x := c.x + offs[k]
			var y := c.y + offs[k + 1]
			if x < 0 or y < 0 or x >= width or y >= height:
				continue
			var i := y * width + x
			_visible[i] = 1
			_explored[i] = 1


func state_at(world: Vector3) -> int:
	return cell_state(cell_of(world))


func cell_state(c: Vector2i) -> int:
	if c.x < 0 or c.y < 0 or c.x >= width or c.y >= height:
		return UNEXPLORED
	var i := c.y * width + c.x
	if _visible[i]:
		return VISIBLE
	return EXPLORED if _explored[i] else UNEXPLORED


## An enemy unit is drawn (and can be clicked) only here.
func is_visible(world: Vector3) -> bool:
	return state_at(world) == VISIBLE


## A building may be placed only here (recipe 60's `explored`), and a building seen once stays drawn here.
func is_explored(world: Vector3) -> bool:
	return state_at(world) != UNEXPLORED


func explored_fraction() -> float:
	var n := 0
	for b in _explored:
		n += b
	return float(n) / maxf(_explored.size(), 1)


## The overlay: one pixel per cell, 0 unexplored, 128 explored, 255 visible (FORMAT_L8). A shader darkens the world by it
## (smoothed with linear filtering); update an ImageTexture with it after each update().
func to_image() -> Image:
	var data := PackedByteArray()
	data.resize(width * height)
	for i in data.size():
		data[i] = 255 if _visible[i] else (128 if _explored[i] else 0)
	return Image.create_from_data(width, height, false, Image.FORMAT_L8, data)


## Marks everything explored (a revealed map, a cheat, a replay).
func reveal_all() -> void:
	_explored.fill(1)


func _circle(r: int) -> PackedInt32Array:
	if _circles.has(r):
		return _circles[r]
	var offs := PackedInt32Array()
	var r2 := (r + 0.5) * (r + 0.5)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r2:
				offs.append(dx)
				offs.append(dy)
	_circles[r] = offs
	return offs
