class_name SpawnPicker
extends RefCounted
## Fair spawns (genre doc §7: never behind the player, never in plain view, never on top of them). A spawn point is
## fair for the player's eye when:
##   - its distance is inside [min_distance, max_distance] (no ambush at arm's length, time to react);
##   - it is ahead: not behind the player along the zone's `ahead` direction (the way the mission advances);
##   - it is hidden: geometry blocks the line from the player's eye to a body standing there.
## `pick` returns the fair points farthest first; when there are fewer than asked, it fills up with the farthest
## unfair ones and counts them in `last_unfair` (a level-design bug the contract test reports).

var min_distance := 12.0
var max_distance := 45.0
var mask := 1                 ## layers that block sight (the world)

var last_unfair := 0


## `body_height`: where the line of sight is tested (1.2 = a standing chest; 0.9 = a soldier crouched in cover).
func is_fair(space: PhysicsDirectSpaceState3D, point: Vector3, eye: Vector3, ahead: Vector3, body_height: float = 1.2) -> bool:
	var flat := Vector3(point.x - eye.x, 0.0, point.z - eye.z)
	var d := flat.length()
	if d < min_distance or d > max_distance:
		return false
	if flat.dot(Vector3(ahead.x, 0.0, ahead.z)) < 0.0:
		return false
	var q := PhysicsRayQueryParameters3D.create(eye, point + Vector3(0, body_height, 0), mask)
	return not space.intersect_ray(q).is_empty()


func pick(space: PhysicsDirectSpaceState3D, points: Array[Vector3], eye: Vector3, ahead: Vector3, count: int, body_height: float = 1.2) -> Array[Vector3]:
	var by_distance := points.duplicate()
	by_distance.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_to(eye) > b.distance_to(eye))
	var fair: Array[Vector3] = []
	var rest: Array[Vector3] = []
	for p in by_distance:
		if is_fair(space, p, eye, ahead, body_height) and not fair.any(func(o: Vector3) -> bool: return o.distance_to(p) < 1.5):
			fair.append(p)
		else:
			rest.append(p)
	var out: Array[Vector3] = fair.slice(0, count)
	last_unfair = 0
	var i := 0
	while out.size() < count and i < rest.size():
		out.append(rest[i])
		last_unfair += 1
		i += 1
	return out
