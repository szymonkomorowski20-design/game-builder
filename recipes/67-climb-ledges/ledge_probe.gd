class_name LedgeProbe
extends RefCounted
## Finds a hold to climb without hand-placed markers (recipe 67), the way the genre's markup-free systems do (genre doc
## §1): a steep wall faced within `max_facing_deg`, and a flat top within a height window, either on the wall itself (a
## roof's edge, a crate, a fence) or on a lip sticking out of its face (a cornice, a sill, a beam). It also says where
## the body hangs and whether there is room to stand on the top. Pure queries on a PhysicsDirectSpaceState3D, unit-tested
## on boxes. Holds count only on `mask`: put climbable geometry on its own layer and give it one look (genre doc §12).

var reach := 1.0                 ## m in front of the body's axis a wall may be
var max_facing_deg := 40.0       ## the wall's normal against the facing
var max_wall_tilt_deg := 20.0    ## how far from vertical a wall may lean
var max_top_slope_deg := 25.0    ## a top steeper than this is no hold
var ray_step := 0.15             ## m between the forward rays through the window
var top_inset := 0.1             ## m behind the wall's face a wall's own top is sampled
var lip_probe := 0.05            ## m in front of the wall's face a lip's top is sampled
var hang_gap := 0.5              ## m from the wall's face to the body's axis while hanging
var hang_below := 1.95           ## m from the hold's top down to the feet while hanging
var stand_in := 0.6              ## m behind the edge the body stands after climbing up
var body_radius := 0.35
var body_height := 1.8
var mask := 1                    ## what can be climbed
var world_mask := 1              ## what blocks the body (for the room to hang and to stand)


## A hold whose top lies between `y_min` and `y_max` on a wall in front of `origin` (the body's feet) along `facing`.
## Returns {} or {kind (&"top" / &"lip"), top_y, edge, normal (out of the wall), hang (feet), stand (feet), height
## (above the origin), can_hang, can_stand}. Of several holds in the window the lowest wins.
func find(space: PhysicsDirectSpaceState3D, origin: Vector3, facing: Vector3, y_min: float, y_max: float,
		exclude: Array[RID] = []) -> Dictionary:
	var f := Vector3(facing.x, 0.0, facing.z)
	if f.length_squared() < 1e-6:
		return {}
	f = f.normalized()
	# 1. The wall's face: the farthest wall hit through the window (lips stick out of the face, so they are nearer).
	var face_d := -1.0
	var face_n := Vector3.ZERO
	var y := y_min
	while y <= y_max + 0.3 + 1e-4:
		var from := Vector3(origin.x, y, origin.z)
		var hit := _ray(space, from, from + f * reach, mask, exclude)
		if not hit.is_empty() and _is_wall(hit.normal, f):
			var d := from.distance_to(hit.position)
			if d > face_d:
				face_d = d
				face_n = _flat(hit.normal)
		y += ray_step
	if face_d < 0.0:
		return {}
	# 2. Tops: just behind the face (the wall's own top) and just in front of it (a lip).
	var best := {}
	for kind: StringName in [&"top", &"lip"]:
		var d := face_d + (top_inset if kind == &"top" else -lip_probe)
		var column := Vector3(origin.x, 0.0, origin.z) + f * d
		var start := Vector3(column.x, y_max + 0.3, column.z)
		if kind == &"top" and _solid(space, start, exclude):
			continue    # the wall goes on above the window: no top of it within reach
		# (a lip column may start inside the hold above the window; the ray passes through it)
		var top_y := _top_in_window(space, column, start.y, y_min, y_max, exclude)
		if is_nan(top_y):
			continue
		if kind == &"top":
			# The edge must be open above: just behind the face, over the top. A thin wall with a crate behind it
			# would otherwise offer the crate's top, and the body would climb through the wall.
			var above := Vector3(origin.x, 0.0, origin.z) + f * (face_d + 0.03)
			if _solid(space, Vector3(above.x, top_y + 0.2, above.z), exclude):
				continue
		if best.is_empty() or top_y < float(best.top_y):
			best = {kind = kind, top_y = top_y}
	if best.is_empty():
		return {}
	# 3. Where the body goes: the face at the top's height, out from it to hang, in from it to stand.
	var top_y := float(best.top_y)
	var edge := Vector3(origin.x, 0.0, origin.z) + f * face_d
	edge.y = top_y
	var hang := edge + face_n * hang_gap + Vector3.DOWN * hang_below
	var stand := edge - face_n * stand_in
	return {
		kind = best.kind,
		top_y = top_y,
		edge = edge,
		normal = face_n,
		hang = hang,
		stand = stand,
		height = top_y - origin.y,
		can_hang = capsule_free(space, hang, exclude),
		can_stand = best.kind == &"top" and capsule_free(space, stand + Vector3.UP * 0.05, exclude),
	}


## True when the body's capsule standing with its feet at `feet` touches nothing solid.
func capsule_free(space: PhysicsDirectSpaceState3D, feet: Vector3, exclude: Array[RID] = []) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = body_radius
	shape.height = body_height
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), feet + Vector3.UP * (body_height * 0.5))
	q.collision_mask = world_mask
	q.exclude = exclude
	return space.intersect_shape(q, 1).is_empty()


## The first flat top at or below `y_max` going down the column from `from_y`: holds above the window (a cornice over
## the sill the player wants) are passed through. NAN when that top is below `y_min`, too steep, or missing.
func _top_in_window(space: PhysicsDirectSpaceState3D, column: Vector3, from_y: float, y_min: float, y_max: float,
		exclude: Array[RID]) -> float:
	var y := from_y
	for i in 8:
		var hit := _ray(space, Vector3(column.x, y, column.z), Vector3(column.x, y_min - 0.05, column.z), mask, exclude)
		if hit.is_empty():
			return NAN
		var top_y := (hit.position as Vector3).y
		if top_y > y_max:
			y = top_y - 0.02    # start inside that hold: a ray leaving a solid doesn't hit it again
			continue
		if top_y < y_min or (hit.normal as Vector3).y < cos(deg_to_rad(max_top_slope_deg)):
			return NAN
		return top_y
	return NAN


func _is_wall(normal: Vector3, facing: Vector3) -> bool:
	if absf(normal.y) > sin(deg_to_rad(max_wall_tilt_deg)):
		return false
	return (-_flat(normal)).dot(facing) >= cos(deg_to_rad(max_facing_deg))


func _solid(space: PhysicsDirectSpaceState3D, point: Vector3, exclude: Array[RID]) -> bool:
	var q := PhysicsPointQueryParameters3D.new()
	q.position = point
	q.collision_mask = world_mask
	q.exclude = exclude
	return not space.intersect_point(q, 1).is_empty()


static func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, ray_mask: int,
		exclude: Array[RID]) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, ray_mask, exclude))


static func _flat(v: Vector3) -> Vector3:
	var f := Vector3(v.x, 0.0, v.z)
	return f.normalized() if f.length_squared() > 1e-8 else Vector3.ZERO
