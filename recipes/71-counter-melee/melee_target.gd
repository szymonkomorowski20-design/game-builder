class_name MeleeTarget
extends RefCounted
## Which enemy a melee attack goes for (recipe 71), after God of War (2018)'s rules (genre doc §11): if there is any
## sensible target, attack it instead of the air; the stick's direction carries the intent (with no input, the camera's
## direction); the reach shrinks with the angle away from that direction, so an enemy far to the side isn't pulled in
## from across the room.

## The best target among `enemies` (positions) for a player at `from` wanting `direction`, or -1 when none is in reach.
static func pick(from: Vector3, direction: Vector3, enemies: Array[Vector3], reach: float = 3.0,
		side_reach: float = 0.3) -> int:
	var d := Vector3(direction.x, 0.0, direction.z)
	if d.length_squared() < 1e-6:
		return -1
	d = d.normalized()
	var best := -1
	var best_score := INF
	for i in enemies.size():
		var to := enemies[i] - from
		to.y = 0.0
		var dist := to.length()
		var cos_a := d.dot(to / dist) if dist > 1e-4 else 1.0
		var allowed := reach * maxf(cos_a, side_reach)
		if dist > allowed:
			continue
		var score := dist / reach + (1.0 - cos_a)
		if score < best_score:
			best_score = score
			best = i
	return best
