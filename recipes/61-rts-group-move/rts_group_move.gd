class_name RtsGroupMove
extends RefCounted
## Moving a group (recipe 61). Twenty units ordered to one point fight over it: they bump, circle and push forever. The
## genre's answers, as pure functions the game calls when it gives a MOVE / ATTACK_MOVE to a selection:
## - **the magic box** (a StarCraft II habit players rely on): when the target is outside the group's bounding box and
##   the group is compact, each unit keeps its offset from the centre, so a formation moves as a formation; a target
##   inside the box gathers them;
## - **slots**: a gathering group gets a grid of points around the target, rows facing the way they walk, `spacing`
##   apart;
## - **assignment**: each unit gets the nearest free slot, globally closest pairs first, so paths don't cross;
## - **arrival**: a unit stops at its slot, or near it once a neighbour next to it has stopped (the crowd rule);
## - **speed matching** (optional): the group walks at its slowest member's speed and arrives together.
## Collision avoidance while walking stays with the engine (NavigationAgent3D avoidance).


## Targets for each of `positions` ordered to `target`. `max_spread`: a group wider than this gathers instead.
static func targets(positions: Array[Vector3], target: Vector3, spacing: float, max_spread: float = 12.0) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if positions.is_empty():
		return out
	if positions.size() == 1:
		out.append(target)
		return out
	var box := _bounds(positions)
	var inside := box.has_point(Vector2(target.x, target.z))
	var compact := box.size.x <= max_spread and box.size.y <= max_spread
	var c := centroid(positions)
	if not inside and compact:
		for p in positions:
			out.append(Vector3(target.x + p.x - c.x, target.y, target.z + p.z - c.z))
		return out
	var dir := Vector3(target.x - c.x, 0.0, target.z - c.z)
	var s := slots(target, positions.size(), spacing, dir)
	var pick := assign(positions, s)
	for i in positions.size():
		out.append(s[pick[i]])
	return out


## A grid of `count` points centred on `centre`, `spacing` apart, rows across `facing` (the first row in front).
static func slots(centre: Vector3, count: int, spacing: float, facing: Vector3) -> Array[Vector3]:
	var f := Vector3(facing.x, 0.0, facing.z)
	f = f.normalized() if f.length() > 0.001 else Vector3.FORWARD
	var side := Vector3(-f.z, 0.0, f.x)
	var cols := ceili(sqrt(float(count)))
	var rows := ceili(float(count) / cols)
	var out: Array[Vector3] = []
	for i in count:
		var r := i / cols
		var col := i % cols
		var in_row := mini(cols, count - r * cols)
		var x := (col - (in_row - 1) * 0.5) * spacing
		var z := ((rows - 1) * 0.5 - r) * spacing
		out.append(centre + side * x + f * z)
	var shift := centre - centroid(out)      # an uneven last row: keep the whole grid centred
	for i in out.size():
		out[i] += shift
	return out


## For each position, the index of its slot: globally closest pairs first (a greedy matching — near-optimal, and
## crossing-free for the usual shapes). Every slot is used once.
static func assign(positions: Array[Vector3], slot_points: Array[Vector3]) -> Array[int]:
	var pairs: Array = []
	for i in positions.size():
		for j in slot_points.size():
			pairs.append([positions[i].distance_squared_to(slot_points[j]), i, j])
	pairs.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out: Array[int] = []
	out.resize(positions.size())
	out.fill(-1)
	var used := {}
	var left := positions.size()
	for p in pairs:
		if left == 0:
			break
		var i: int = p[1]
		var j: int = p[2]
		if out[i] != -1 or used.has(j):
			continue
		out[i] = j
		used[j] = true
		left -= 1
	return out


## Has this unit arrived? At its slot (within `radius`), or within `crowd` × radius of it while touching a neighbour
## that has arrived (the crowd rule: the last ones don't shove the first ones forever).
static func arrived(at: Vector3, slot: Vector3, radius: float, arrived_neighbours: Array[Vector3], crowd: float = 3.0) -> bool:
	var d := Vector2(at.x - slot.x, at.z - slot.z).length()
	if d <= radius:
		return true
	if d > radius * crowd:
		return false
	for n in arrived_neighbours:
		if Vector2(at.x - n.x, at.z - n.z).length() <= radius * 2.2:
			return true
	return false


## The speed a group walks at when it should arrive together: its slowest member's.
static func group_speed(speeds: Array[float]) -> float:
	var s := INF
	for v in speeds:
		s = minf(s, v)
	return 0.0 if s == INF else s


static func centroid(positions: Array[Vector3]) -> Vector3:
	var c := Vector3.ZERO
	for p in positions:
		c += p
	return c / maxf(positions.size(), 1)


static func _bounds(positions: Array[Vector3]) -> Rect2:
	var r := Rect2(Vector2(positions[0].x, positions[0].z), Vector2.ZERO)
	for p in positions:
		r = r.expand(Vector2(p.x, p.z))
	return r
