class_name CoverFinder
extends RefCounted
## Picks a cover point for a cover-shooter soldier (recipe 57). Cover points are Marker3Ds (group "cover") placed
## behind low walls, crates and pillars. A point is **cover against the player** when a ray from its crouch height to
## the player's eyes is blocked, and it is **useful** when a ray from its standing height (the peek) sees the player.
## Among useful covers, the score prefers:
##   a distance to the player inside [near, far] (the band where the soldier's gun is meant to fight);
##   a short walk for the soldier;
##   for a flank, a new angle on the player (the angle between "player → old spot" and "player → new spot").
## Occupied points (other soldiers' targets) are skipped.

const CROUCH := 0.9
const STAND := 1.6

var near := 8.0
var far := 22.0
var mask := 1                 ## layers that block sight (walls, crates)


## True when the player's eyes can't see the point at crouch height, but can at standing height.
func is_useful(space: PhysicsDirectSpaceState3D, point: Vector3, player_eye: Vector3) -> bool:
	return _blocked(space, point + Vector3(0, CROUCH, 0), player_eye) and not _blocked(space, point + Vector3(0, STAND, 0), player_eye)


func score(point: Vector3, soldier: Vector3, player: Vector3, flank_from: Variant = null) -> float:
	var d := Vector2(point.x - player.x, point.z - player.z).length()
	var band := 0.0 if d >= near and d <= far else -minf(absf(d - near), absf(d - far))
	var walk := -0.15 * soldier.distance_to(point)
	var angle := 0.0
	if flank_from != null:
		var a := Vector2(point.x - player.x, point.z - player.z)
		var b := Vector2((flank_from as Vector3).x - player.x, (flank_from as Vector3).z - player.z)
		angle = 0.08 * rad_to_deg(absf(a.angle_to(b)))    # a flank is worth a longer walk
	return band * 2.0 + walk + angle


## The best useful, free cover point, or null. `occupied`: points other soldiers already took.
func best(space: PhysicsDirectSpaceState3D, points: Array[Vector3], soldier: Vector3, player_eye: Vector3, occupied: Array[Vector3] = [], flank_from: Variant = null) -> Variant:
	var best_point: Variant = null
	var best_score := -INF
	var player := Vector3(player_eye.x, 0, player_eye.z)
	for p in points:
		if occupied.any(func(o: Vector3) -> bool: return o.distance_to(p) < 0.5):
			continue
		if flank_from != null and (flank_from as Vector3).distance_to(p) < 0.5:
			continue
		if not is_useful(space, p, player_eye):
			continue
		var s := score(p, soldier, player, flank_from)
		if s > best_score:
			best_score = s
			best_point = p
	return best_point


func _blocked(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, mask)
	return not space.intersect_ray(q).is_empty()
