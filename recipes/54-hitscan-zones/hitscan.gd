class_name Hitscan
extends RefCounted
## An instant shot for a 3D shooter (recipe 54): a ray from the camera along a direction bent by the shot's spread
## offset (recipe 53), returning what it hit, where, how far — and which **hit zone**. A zone is metadata
## `hit_zone` (&"head", &"body", &"limb") on the CollisionShape3D that was hit, so one enemy body carries several
## shapes (a sphere for the head, a capsule for the torso) and the ray tells them apart.

## Forward (−Z of `basis`) turned by `offset_deg` (x = yaw right, y = pitch up), in degrees.
static func shot_direction(basis: Basis, offset_deg: Vector2) -> Vector3:
	var yawed := basis.rotated(basis.y.normalized(), -deg_to_rad(offset_deg.x))
	var pitched := yawed.rotated(yawed.x.normalized(), deg_to_rad(offset_deg.y))
	return (-pitched.z).normalized()


## Casts the shot. Returns {} when nothing is hit within `max_range`, else
## {collider, position, normal, distance, zone}. `exclude` are RIDs to ignore (the shooter's own body).
static func cast(world: World3D, from: Vector3, dir: Vector3, max_range: float, mask: int = 0xFFFFFFFF, exclude: Array[RID] = []) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, from + dir.normalized() * max_range, mask, exclude)
	var hit := world.direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return {}
	var zone := zone_of(hit.collider, int(hit.shape))
	return {"collider": hit.collider, "position": hit.position, "normal": hit.normal,
		"distance": from.distance_to(hit.position), "zone": zone}


## The hit zone of shape index `shape` on `collider`: the CollisionShape3D's `hit_zone` metadata, &"body" if unset.
static func zone_of(collider: Object, shape: int) -> StringName:
	if not collider is CollisionObject3D:
		return &"body"
	var body := collider as CollisionObject3D
	var owner_id := body.shape_find_owner(shape)
	var node := body.shape_owner_get_owner(owner_id) as Node
	if node != null and node.has_meta(&"hit_zone"):
		return StringName(node.get_meta(&"hit_zone"))
	return &"body"
