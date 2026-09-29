class_name CrowdRules
extends RefCounted
## Small crowd rules (recipe 70, genre doc §6–§7):
## - `steer`: people slow down rather than turn; a sharp change of direction stops them first (Hitman's biggest lesson);
## - `lod_interval` / `lod_due` / `lod_animate`: full updates only near the camera, fewer farther away, no animation
##   far away (Assassin's Creed Unity's 12 m and 40 m bands);
## - `blended`: the player hides in a crowd when walking slowly within reach of at least two calm civilians (a group of
##   two, as in Assassin's Creed III).

static var near_band := 12.0
static var mid_band := 40.0
static var animate_within := 30.0


## One steering step: turn `heading` toward `desired` by at most `turn_rate` rad/s, and scale the speed down with the
## remaining angle (cos², so 90° off is a near stop). Returns {heading, speed}.
static func steer(heading: Vector3, desired: Vector3, speed: float, turn_rate: float, delta: float) -> Dictionary:
	var h := Vector3(heading.x, 0.0, heading.z)
	var d := Vector3(desired.x, 0.0, desired.z)
	if d.length_squared() < 1e-8:
		return {heading = h, speed = 0.0}
	d = d.normalized()
	if h.length_squared() < 1e-8:
		return {heading = d, speed = speed}
	h = h.normalized()
	var angle := h.signed_angle_to(d, Vector3.UP)
	var turn := clampf(angle, -turn_rate * delta, turn_rate * delta)
	var new_h := h.rotated(Vector3.UP, turn)
	var left := absf(angle - turn)
	var scale := maxf(cos(minf(left, PI * 0.5)), 0.0)
	return {heading = new_h, speed = speed * scale * scale}


## Update every n-th frame at this distance from the camera.
static func lod_interval(distance: float) -> int:
	if distance < near_band:
		return 1
	return 3 if distance < mid_band else 10


## True on this agent's frames: agents in one band are spread over the frames by their id.
static func lod_due(frame: int, id: int, distance: float) -> bool:
	var n := lod_interval(distance)
	return frame % n == posmod(id, n)


static func lod_animate(distance: float) -> bool:
	return distance < animate_within


## The player is blended into the crowd: moving no faster than `max_speed` within `radius` of at least `min_people`
## calm civilians.
static func blended(player: Vector3, player_speed: float, calm_civilians: Array[Vector3], radius: float = 1.8,
		min_people: int = 2, max_speed: float = 2.4) -> bool:
	if player_speed > max_speed:
		return false
	var near := 0
	for c in calm_civilians:
		if Vector2(c.x - player.x, c.z - player.z).length() <= radius:
			near += 1
			if near >= min_people:
				return true
	return false
