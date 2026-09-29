class_name ViewpointNetwork
extends RefCounted
## Viewpoints (recipe 73, genre doc §9). Synchronising at one reveals, in one go, every marker within its radius (a
## clear goal and an instant reward), shows the unsynced viewpoints within twice its radius, and makes it a
## fast-travel point. Walking up to a marker reveals it too (`discover_near`), so a viewpoint is a shortcut, not the
## only way to learn about a place (Far Cry 5 dropped towers because they had become exactly that).

var viewpoints := {}
var markers := {}


func add_viewpoint(id: StringName, pos: Vector3, radius: float) -> void:
	viewpoints[id] = {pos = pos, radius = radius, synced = false, seen = false}


func add_marker(id: StringName, pos: Vector3, kind: StringName = &"") -> void:
	markers[id] = {pos = pos, kind = kind, revealed = false}


## Synchronise at viewpoint `id`: returns the markers revealed now (none the second time).
func sync(id: StringName) -> Array[StringName]:
	var vp: Dictionary = viewpoints[id]
	var fresh: Array[StringName] = []
	if vp.synced:
		return fresh
	vp.synced = true
	vp.seen = true
	for m: StringName in markers:
		if not markers[m].revealed and _flat(markers[m].pos, vp.pos) <= float(vp.radius):
			markers[m].revealed = true
			fresh.append(m)
	for other: StringName in viewpoints:
		if other != id and _flat(viewpoints[other].pos, vp.pos) <= 2.0 * float(vp.radius):
			viewpoints[other].seen = true
	return fresh


## Markers within `distance` of `pos` that weren't known yet, now revealed.
func discover_near(pos: Vector3, distance: float) -> Array[StringName]:
	var fresh: Array[StringName] = []
	for m: StringName in markers:
		if not markers[m].revealed and _flat(markers[m].pos, pos) <= distance:
			markers[m].revealed = true
			fresh.append(m)
	return fresh


func revealed() -> Array[StringName]:
	var out: Array[StringName] = []
	for m: StringName in markers:
		if markers[m].revealed:
			out.append(m)
	return out


func fast_travel_points() -> Array[StringName]:
	var out: Array[StringName] = []
	for v: StringName in viewpoints:
		if viewpoints[v].synced:
			out.append(v)
	return out


## Viewpoints shown on the map but not yet climbed.
func seen_unsynced() -> Array[StringName]:
	var out: Array[StringName] = []
	for v: StringName in viewpoints:
		if viewpoints[v].seen and not viewpoints[v].synced:
			out.append(v)
	return out


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
