class_name Hearing
extends RefCounted
## Hearing that follows the level, not a circle (recipe 68, genre doc §4): a guard hears a noise only if the way a
## person would walk from the noise to the guard is shorter than the noise's radius. A wall between them with the
## door far away means silence, even when the straight distance is short. A noise far from the navigation mesh (on a
## roof the guards can't walk) travels through the open air: the straight distance counts.

## Metres from `from` (the noise) to `to` (the listener): along the navigation map, or straight when the noise is more
## than `off_mesh` metres from the mesh. INF when no path reaches the listener.
static func distance(map: RID, from: Vector3, to: Vector3, off_mesh: float = 1.0) -> float:
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return from.distance_to(to)
	if NavigationServer3D.map_get_closest_point(map, from).distance_to(from) > off_mesh:
		return from.distance_to(to)
	var path := NavigationServer3D.map_get_path(map, from, to, true)
	if path.is_empty():
		return INF
	if path[path.size() - 1].distance_to(to) > off_mesh:
		return INF          # the path ends short of the listener: another room, no way through
	var length := 0.0
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	return length


static func hears(radius: float, path_length: float) -> bool:
	return radius > 0.0 and path_length <= radius
