class_name PlatformPath
extends RefCounted
## Where a platform is at time t: back and forth along waypoints at constant speed (ping-pong). Pure, so the route
## is testable without physics; the platform node only asks `position_at(time)` every physics frame.

var points: PackedVector2Array
var speed: float


func _init(waypoints: PackedVector2Array, px_per_second: float) -> void:
	points = waypoints
	speed = px_per_second


func length() -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total


func position_at(time: float) -> Vector2:
	if points.size() < 2 or speed <= 0.0 or length() == 0.0:
		return points[0] if points.size() > 0 else Vector2.ZERO
	var total := length()
	var d := fmod(time * speed, 2.0 * total)
	if d > total:
		d = 2.0 * total - d   # on the way back
	for i in range(1, points.size()):
		var seg := points[i - 1].distance_to(points[i])
		if d <= seg:
			return points[i - 1].lerp(points[i], d / seg if seg > 0.0 else 0.0)
		d -= seg
	return points[points.size() - 1]
