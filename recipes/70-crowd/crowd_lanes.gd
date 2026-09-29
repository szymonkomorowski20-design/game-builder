class_name CrowdLanes
extends RefCounted
## Where the crowd walks (recipe 70): a hand-drawn network of lane points (genre doc §7: lanes and slots, not free
## wandering, which looks chaotic), each linked to its neighbours. A civilian walks from point to point and picks the
## next one at random among the links, never straight back unless it's a dead end. It is deterministic from a seed, so
## a scene plays the same every run.

var points: Array[Vector3] = []
var links: Array[PackedInt32Array] = []


func add_point(p: Vector3) -> int:
	points.append(p)
	links.append(PackedInt32Array())
	return points.size() - 1


func link(a: int, b: int) -> void:
	if a == b or links[a].has(b):
		return
	links[a].append(b)
	links[b].append(a)


## Lanes from polylines (e.g. Path3D curves or Marker3D rows); points closer than `join` merge, so lanes cross.
static func from_paths(paths: Array[PackedVector3Array], join: float = 0.5) -> CrowdLanes:
	var lanes := CrowdLanes.new()
	for path in paths:
		var prev := -1
		for p in path:
			var i := lanes.nearest(p)
			if i < 0 or lanes.points[i].distance_to(p) > join:
				i = lanes.add_point(p)
			if prev >= 0:
				lanes.link(prev, i)
			prev = i
	return lanes


func nearest(p: Vector3) -> int:
	var best := -1
	var best_d := INF
	for i in points.size():
		var d := points[i].distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = i
	return best


## The next point after walking from `previous` to `current`.
func next_from(current: int, previous: int, rng: RandomNumberGenerator) -> int:
	var options: Array[int] = []
	for n in links[current]:
		if n != previous:
			options.append(n)
	if options.is_empty():
		return previous if previous >= 0 else current
	return options[rng.randi_range(0, options.size() - 1)]
